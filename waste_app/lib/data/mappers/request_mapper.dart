import '../models/donation_request.dart';

/// Mapper for converting between DonationRequest objects and Firestore documents
class RequestMapper {
  /// Convert Firestore document to DonationRequest object
  static DonationRequest fromFirestore(Map<String, dynamic> data) {
    return DonationRequest.fromJson(data);
  }

  /// Convert DonationRequest object to Firestore document
  static Map<String, dynamic> toFirestore(DonationRequest request) {
    return request.toJson();
  }

  /// Convert Firestore document snapshot to DonationRequest object
  /// Returns null if document doesn't exist
  static DonationRequest? fromDocumentSnapshot(Map<String, dynamic>? data) {
    if (data == null) return null;
    return fromFirestore(data);
  }
}
