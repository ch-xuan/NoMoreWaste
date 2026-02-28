import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';
import '../models/notification_item.dart';
import 'notification_repository.dart';

class UserRepository {
  UserRepository({
    FirebaseFirestore? db,
    NotificationRepository? notificationRepo,
  }) : _db = db ?? FirebaseFirestore.instance,
       _notificationRepo = notificationRepo ?? NotificationRepository();

  final FirebaseFirestore _db;
  final NotificationRepository _notificationRepo;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required UserRole role,
    String? displayName,
    String? orgName,
    String? phone,
    String? verificationDocument,
    String? verificationDocBase64,
  }) async {
    final now = FieldValue.serverTimestamp();

    await _userDoc(uid).set({
      'uid': uid,
      'email': email,
      'role': role.key,
      'displayName': (displayName ?? '').trim(),
      'orgName': (orgName ?? '').trim(),
      'phone': (phone ?? '').trim(),
      
      'uploadDocsBase64': verificationDocBase64, // Stored directly in user doc

      'verificationStatus': 'pending',
      'verificationReason': null,
      'isDisabled': false,
      
      'lastLoginAt': now,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
    
    // Send "account pending verification" notification
    try {
      final notification = NotificationItem(
        id: '',
        recipientId: uid,
        senderId: uid, // Self-sent to ensure permissions match
        title: 'Account Pending Verification',
        message: 'Your account is currently pending admin verification. You\'ll receive a notification once your account has been approved.',
        type: NotificationType.accountPending,
        entityId: uid,
        createdAt: DateTime.now(),
      );
      await _notificationRepo.createNotification(notification);
      print('✅ Sent pending verification notification to $uid');
    } catch (e) {
      print('⚠️ Failed to send pending notification: $e');
      // Don't throw - notification is supplementary, not critical
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? orgName,
    String? phone,
    String? address,
    String? profilePhotoBase64,
    String? uploadDocsBase64,
    String? verificationStatus, // pending | approved | rejected
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) data['displayName'] = displayName.trim();
    if (orgName != null) data['orgName'] = orgName.trim();
    if (phone != null) data['phone'] = phone.trim();
    if (address != null) data['address'] = address.trim();
    if (profilePhotoBase64 != null) data['profilePhotoBase64'] = profilePhotoBase64;
    if (uploadDocsBase64 != null) data['uploadDocsBase64'] = uploadDocsBase64;
    if (verificationStatus != null) data['verificationStatus'] = verificationStatus;

    await _userDoc(uid).set(data, SetOptions(merge: true));
    
    // Send notification if account was verified
    if (verificationStatus == 'approved') {
      try {
        final notification = NotificationItem(
          id: '',
          recipientId: uid,
          senderId: 'system',
          title: 'Account Verified',
          message: 'Congratulations! Your account has been verified by our admin team. You can now access all features of the app.',
          type: NotificationType.accountVerified,
          entityId: uid,
          createdAt: DateTime.now(),
        );
        await _notificationRepo.createNotification(notification);
        print('✅ Sent account verified notification to $uid');
      } catch (e) {
        print('⚠️ Failed to send verified notification: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    return snap.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserProfile(String uid) {
    return _userDoc(uid).snapshots();
  }
}
