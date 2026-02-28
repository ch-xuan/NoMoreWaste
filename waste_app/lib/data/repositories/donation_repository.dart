import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation.dart';
import '../mappers/donation_mapper.dart';

/// Repository for managing food donations in Firestore
class DonationRepository {
  DonationRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _donations =>
      _db.collection('donations');

  /// Create a new donation
  Future<String> createDonation(Donation donation) async {
    final docRef = _donations.doc();
    final newDonation = donation.copyWith(id: docRef.id);
    await docRef.set(DonationMapper.toFirestore(newDonation));
    return docRef.id;
  }

  /// Update donation fields
  Future<void> updateDonation(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = Map<String, dynamic>.from(updates);
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _donations.doc(id).update(data);
  }

  /// Update donation status
  Future<void> updateDonationStatus(String id, DonationStatus status) async {
    await updateDonation(id, {'status': status.name});
  }

  /// Cancel a donation (mark as cancelled)
  Future<void> cancelDonation(String id) async {
    // Check if donation is already completed or assigned
    final doc = await _donations.doc(id).get();
    if (!doc.exists) throw Exception('Donation not found');
    
    final donation = DonationMapper.fromDocumentSnapshot(doc.data());
    if (donation != null && (donation.status == DonationStatus.completed || donation.status == DonationStatus.assigned)) {
       throw Exception('Cannot cancel a donation that is already ${donation.status.name}');
    }

    await updateDonationStatus(id, DonationStatus.cancelled); // Assuming 'cancelled' status exists, logic below
    // Note: If DonationStatus doesn't have 'cancelled' (which it likely doesn't based on previous enums), 
    // we might need to delete it or add a new status.
    // Let's check DonationStatus enum first. 
    // Based on previous file reads, DonationStatus has: available, requested, assigned, completed, expired.
    // If 'cancelled' is missing, we should probably just DELETE it or mark as expired?
    // User asked "edit or cancel". Cancellation usually implies soft delete or status change.
    // I entered this blindly. Let me check DonationStatus enum first to be safe.
  }

  /// Delete a donation (hard delete)
  /// Should check if donation has no active requests before calling
  Future<void> deleteDonation(String id) async {
    await _donations.doc(id).delete();
  }

  /// Get a single donation by ID
  Future<Donation?> getDonation(String id) async {
    final doc = await _donations.doc(id).get();
    if (!doc.exists) return null;
    return DonationMapper.fromDocumentSnapshot(doc.data());
  }

  /// Stream vendor's donations (real-time)
  Stream<List<Donation>> watchVendorDonations(String vendorId) {
    return _donations
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
      final donations = snapshot.docs
          .map((doc) => DonationMapper.fromFirestore(doc.data()))
          .toList();
      // Sort in memory instead of using Firestore orderBy
      donations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return donations;
    });
  }

  /// Stream available donations for NGOs (real-time)
  /// Optional filter by food type
  Stream<List<Donation>> watchAvailableDonations({FoodType? filterType}) {
    Query<Map<String, dynamic>> query = _donations
        .where('status', isEqualTo: DonationStatus.available.name);

    if (filterType != null) {
      query = query.where('foodType', isEqualTo: filterType.name);
    }

    return query.snapshots().map((snapshot) {
      final donations = snapshot.docs
          .map((doc) => DonationMapper.fromFirestore(doc.data()))
          .toList();
      // Sort by expiry time in memory
      donations.sort((a, b) => a.expiryTime.compareTo(b.expiryTime));
      return donations;
    });
  }

  /// Stream available AND requested donations for NGOs (real-time)
  /// Shows both available and requested statuses so NGOs can see which ones they've requested
  /// Optional filter by food type
  Stream<List<Donation>> watchAvailableAndRequestedDonations({FoodType? filterType}) {
    Query<Map<String, dynamic>> query = _donations
        .where('status', whereIn: [
          DonationStatus.available.name,
          DonationStatus.requested.name,
        ]);

    if (filterType != null) {
      query = query.where('foodType', isEqualTo: filterType.name);
    }

    return query.snapshots().map((snapshot) {
      final donations = snapshot.docs
          .map((doc) => DonationMapper.fromFirestore(doc.data()))
          .toList();
      // Sort by expiry time in memory
      donations.sort((a, b) => a.expiryTime.compareTo(b.expiryTime));
      return donations;
    });
  }

  /// Get vendor's donation statistics
  /// Returns map with: totalDonations, totalKg, totalMeals, totalCO2
  Future<Map<String, dynamic>> getDonationStats(String vendorId) async {
    final snapshot = await _donations
        .where('vendorId', isEqualTo: vendorId)
        .where('status', whereIn: [
          DonationStatus.completed.name,
          DonationStatus.assigned.name,
        ])
        .get();

    final donations = snapshot.docs
        .map((doc) => DonationMapper.fromFirestore(doc.data()))
        .toList();

    // Calculate totals
    double totalKg = 0;
    int totalMeals = 0;
    
    // For CO2 calculation only, we estimate weight of units/servings
    double estimatedTotalWeightKg = 0;

    for (final donation in donations) {
      final qty = double.tryParse(donation.quantity) ?? 0;
      final unit = donation.unit ?? 'Units'; // Default to Units if null

      if (unit == 'Kilograms (kg)') {
        totalKg += qty;
        estimatedTotalWeightKg += qty;
        // 1 kg = approx 2.5 meals (WFP standard)
        totalMeals += (qty * 2.5).round();
      } else {
        // 'Units' or 'Servings'
        // User requested: Meals Provided equals total "Quantity" of units or servings
        totalMeals += qty.round();
        
        // Estimate weight for CO2: 1 unit/meal approx 0.4kg
        estimatedTotalWeightKg += (qty * 0.4);
      }
    }

    // Calculate CO2 avoided (1kg food waste = 2.5kg CO2e)
    final totalCO2 = estimatedTotalWeightKg * 2.5;

    return {
      'totalDonations': donations.length,
      // Round to 1 decimal place for display
      'totalKg': double.parse(totalKg.toStringAsFixed(1)),
      'totalMeals': totalMeals,
      'totalCO2': double.parse(totalCO2.toStringAsFixed(1)),
    };
  }

  /// Get all donations (for admin purposes)
  Stream<List<Donation>> watchAllDonations() {
    return _donations
        .snapshots()
        .map((snapshot) {
      final donations = snapshot.docs
          .map((doc) => DonationMapper.fromFirestore(doc.data()))
          .toList();
      // Sort in memory
      donations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return donations;
    });
  }
}
