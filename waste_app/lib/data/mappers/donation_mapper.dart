import '../models/donation.dart';

/// Mapper for converting between Donation objects and Firestore documents
class DonationMapper {
  /// Convert Firestore document to Donation object
  static Donation fromFirestore(Map<String, dynamic> data) {
    return Donation.fromJson(data);
  }

  /// Convert Donation object to Firestore document
  static Map<String, dynamic> toFirestore(Donation donation) {
    return donation.toJson();
  }

  /// Convert Firestore document snapshot to Donation object
  /// Returns null if document doesn't exist
  static Donation? fromDocumentSnapshot(Map<String, dynamic>? data) {
    if (data == null) return null;
    return fromFirestore(data);
  }
}
