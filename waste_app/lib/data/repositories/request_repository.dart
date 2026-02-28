import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation_request.dart';
import '../models/donation.dart';
import '../models/delivery_task.dart';
import '../models/notification_item.dart';
import '../mappers/request_mapper.dart';
import 'donation_repository.dart';
import 'task_repository.dart';
import 'notification_repository.dart';
import 'user_repository.dart';

/// Repository for managing NGO donation requests in Firestore
class RequestRepository {
  RequestRepository({
    FirebaseFirestore? db,
    DonationRepository? donationRepo,
    TaskRepository? taskRepo,
    NotificationRepository? notificationRepo,
    UserRepository? userRepo,
  })  : _db = db ?? FirebaseFirestore.instance,
        _donationRepo = donationRepo ?? DonationRepository(),
        _taskRepo = taskRepo ?? TaskRepository(),
        _notificationRepo = notificationRepo ?? NotificationRepository();

  final FirebaseFirestore _db;
  final DonationRepository _donationRepo;
  final TaskRepository _taskRepo;
  final NotificationRepository _notificationRepo;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('requests');

  /// Create a new donation request
  /// If deliveryMode is volunteer, also creates a delivery task
  Future<String> createRequest(
    DonationRequest request, {
    String? pickupAddress,
    String? dropoffAddress,
    String? pickupName,
    String? dropoffName,
    String? vendorId, // ID of the vendor receiving the request
  }) async {
    try {
      print('🔵 Creating request for donation: ${request.donationId}');
      
      final docRef = _requests.doc();
      // Ensure dropoffAddress is set if provided separately
      final newRequest = request.copyWith(
        id: docRef.id,
        dropoffAddress: request.dropoffAddress.isEmpty ? dropoffAddress : request.dropoffAddress,
      );
      
      // Create the request
      await docRef.set(RequestMapper.toFirestore(newRequest));

      // Create Notification for Vendor
      if (vendorId != null) {
        final notification = NotificationItem(
          id: '', // Will be generated
          recipientId: vendorId,
          senderId: request.ngoId,
          title: 'New Request Received',
          message: '${request.ngoName} requested your "${request.donationTitle}" donation.',
          type: NotificationType.requestReceived,
          entityId: docRef.id,
          createdAt: DateTime.now(),
        );
        await _notificationRepo.createNotification(notification);
        print('✅ Notification sent to Vendor');
      }

      // Update donation status to 'requested' (NGO has permission via Firestore rules)
      print('🔵 Updating donation status to requested...');
      await _donationRepo.updateDonationStatus(request.donationId, DonationStatus.requested);
      print('✅ Donation status updated to requested');

      return docRef.id;
    } catch (e) {
      print('❌ ERROR creating request: $e');
      rethrow;
    }
  }

  /// Update request status (Approve/Reject by Vendor)
  Future<void> updateRequestStatus({
    required String requestId, 
    required RequestStatus status,
    required String vendorId, // Current user (the vendor)
  }) async {
    // 1. Get current request to know who sent it
    final requestDoc = await _requests.doc(requestId).get();
    if (!requestDoc.exists) throw Exception('Request not found');
    
    final request = RequestMapper.fromDocumentSnapshot(requestDoc.data());
    if (request == null) throw Exception('Invalid request data');

    // Determine effective status to save
    // If approving a self-pickup request, auto-complete it
    RequestStatus effectiveStatus = status;
    if (status == RequestStatus.approved && request.deliveryMode == DeliveryMode.selfPickup) {
      effectiveStatus = RequestStatus.completed;
      print('🔵 Self-pickup approval: Auto-completing request');
    }

    // 2. Update Request Status
    await _requests.doc(requestId).update({
      'status': effectiveStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Handle Approval Logic (Update Donation & Task)
    if (status == RequestStatus.approved) {
      // User is Vendor (Donor), so they HAVE permission to update their valid donation
      if (request.deliveryMode == DeliveryMode.volunteer) {
        try {
          print('🔵 Handling Volunteer Delivery Approval...');
          await _donationRepo.updateDonationStatus(
            request.donationId,
            DonationStatus.assigned,
          );
          print('✅ Donation status updated to assigned');
          
          // Fetch Donation to get Vendor Name and Pickup Address
          final donation = await _donationRepo.getDonation(request.donationId);
          print('Retrieved donation for task creation: ${donation?.id}');

          if (donation != null) {
            // Create delivery task
            print('Creating DeliveryTask object...');
            final task = DeliveryTask(
              id: '', 
              donationId: request.donationId,
              donationTitle: request.donationTitle,
              description: donation.description, // Populate description
              quantity: donation.quantity, // Populate quantity
              requestId: requestId,
              vendorId: donation.vendorId,
              ngoId: request.ngoId,
              volunteerId: null,
              imageUrl: (donation.photos != null && donation.photos!.isNotEmpty) ? donation.photos!.first : null,
              pickupAddress: donation.pickupAddress, 
              dropoffAddress: request.dropoffAddress.isNotEmpty 
                  ? request.dropoffAddress 
                  : 'Contact NGO for details',
              pickupName: donation.vendorName,
              dropoffName: request.ngoName,
              status: TaskStatus.open,
              createdAt: DateTime.now(),
            );
            
            print('Saving Task to Firestore...');
            await _taskRepo.createTask(task);
            print('✅ Delivery Task Created for: ${request.donationTitle}');
          } else {
            print('⚠️ Could not find donation ${request.donationId}, task creation skipped.');
          }
        } catch (e, stack) {
          print('❌ CRITICAL ERROR during Task Creation: $e');
          print(stack);
          // Do not rethrow, we still want to notify the user if possible, or at least not crash the UI
        }
          
      } else {
        // Self pick-up
        print('🔵 Handling Self-Pickup Approval...');
        // Auto-complete donation as well
        await _donationRepo.updateDonationStatus(
          request.donationId,
          DonationStatus.completed, 
        );
        print('✅ Donation status updated to completed (Self-Pickup)');
      }
    } else if (status == RequestStatus.rejected) {
      // If rejected, set donation back to available so other NGOs can request it
      await _donationRepo.updateDonationStatus(
        request.donationId,
        DonationStatus.available,
      );
    }

    // 4. Send Notification to NGO
    try {
      print('🔔 Sending notification to NGO (${request.ngoId}) about status: ${effectiveStatus.name}');
      
      final notification = NotificationItem(
        id: '',
        recipientId: request.ngoId,
        senderId: vendorId,
        title: 'Request ${effectiveStatus.label}',
        message: 'Your request has been ${effectiveStatus.label.toLowerCase()} by the donor.',
        type: status == RequestStatus.approved 
            ? NotificationType.requestApproved 
            : NotificationType.requestRejected,
        entityId: requestId,
        createdAt: DateTime.now(),
      );
      
      await _notificationRepo.createNotification(notification);
      print('✅ Notification sent to NGO successfully');
    } catch (e) {
      print('❌ ERROR sending notification to NGO: $e');
      // Don't rethrow, as the main action (update status) succeeded
    }
  }

  /// Get a single request by ID
  Future<DonationRequest?> getRequest(String id) async {
    final doc = await _requests.doc(id).get();
    if (!doc.exists) return null;
    return RequestMapper.fromDocumentSnapshot(doc.data());
  }

  /// Stream NGO's requests (real-time)
  Stream<List<DonationRequest>> watchNgoRequests(String ngoId) {
    return _requests
        .where('ngoId', isEqualTo: ngoId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RequestMapper.fromFirestore(doc.data()))
          .toList();
    });
  }

  /// Stream requests for a specific donation
  Stream<List<DonationRequest>> watchDonationRequests(String donationId) {
    return _requests
        .where('donationId', isEqualTo: donationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RequestMapper.fromFirestore(doc.data()))
          .toList();
    });
  }

  /// Get all requests (for admin purposes)
  Stream<List<DonationRequest>> watchAllRequests() {
    return _requests
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RequestMapper.fromFirestore(doc.data()))
          .toList();
    });
  }

  /// Check if donation already has a request from this NGO
  Future<bool> hasExistingRequest(String donationId, String ngoId) async {
    final snapshot = await _requests
        .where('donationId', isEqualTo: donationId)
        .where('ngoId', isEqualTo: ngoId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get stats for NGO Profile
  Future<Map<String, dynamic>> getNgoRequestStats(String ngoId) async {
    final snapshot = await _requests
        .where('ngoId', isEqualTo: ngoId)
        .get();

    final requests = snapshot.docs
        .map((doc) => RequestMapper.fromDocumentSnapshot(doc.data()))
        .where((r) => r != null)
        .cast<DonationRequest>()
        .toList();

    int totalRequests = requests.length;
    int received = requests.where((r) => r.status == RequestStatus.completed).length;
    
    // Pending requests (waiting for approval)
    int pending = requests.where((r) => r.status == RequestStatus.pending).length;

    return {
      'requests': totalRequests,
      'received': received,
      'pending': pending,
    };
  }
}
