import 'package:cloud_firestore/cloud_firestore.dart';

/// Delivery mode options for NGO requests
enum DeliveryMode {
  selfPickup,
  volunteer;

  String get label {
    switch (this) {
      case DeliveryMode.selfPickup:
        return 'Self Pick-up';
      case DeliveryMode.volunteer:
        return 'Volunteer Delivery';
    }
  }

  String get key {
    switch (this) {
      case DeliveryMode.selfPickup:
        return 'self_pickup';
      case DeliveryMode.volunteer:
        return 'volunteer';
    }
  }

  static DeliveryMode fromString(String value) {
    switch (value) {
      case 'self_pickup':
        return DeliveryMode.selfPickup;
      case 'volunteer':
        return DeliveryMode.volunteer;
      default:
        return DeliveryMode.selfPickup;
    }
  }
}

/// Request status lifecycle
enum RequestStatus {
  pending,
  approved,
  assigned,
  completed,
  cancelled,
  rejected;

  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.assigned:
        return 'Assigned';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }

  static RequestStatus fromString(String value) {
    return RequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RequestStatus.pending,
    );
  }
}

/// Represents an NGO's request for a donation
class DonationRequest {
  final String id;
  final String donationId;
  final String donationTitle;
  final String ngoId;
  final String ngoName;
  final DeliveryMode deliveryMode;
  final RequestStatus status;
  final String dropoffAddress; // Added for delivery tasks
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DonationRequest({
    required this.id,
    required this.donationId,
    this.donationTitle = '',
    required this.ngoId,
    required this.ngoName,
    required this.deliveryMode,
    required this.status,
    this.dropoffAddress = '', // Default empty if not provided
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a copy with updated fields
  DonationRequest copyWith({
    String? id,
    String? donationId,
    String? donationTitle,
    String? ngoId,
    String? ngoName,
    DeliveryMode? deliveryMode,
    RequestStatus? status,
    String? dropoffAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DonationRequest(
      id: id ?? this.id,
      donationId: donationId ?? this.donationId,
      donationTitle: donationTitle ?? this.donationTitle,
      ngoId: ngoId ?? this.ngoId,
      ngoName: ngoName ?? this.ngoName,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      status: status ?? this.status,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donationId': donationId,
      'donationTitle': donationTitle,
      'ngoId': ngoId,
      'ngoName': ngoName,
      'deliveryMode': deliveryMode.key,
      'status': status.name,
      'dropoffAddress': dropoffAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create from Firestore JSON
  factory DonationRequest.fromJson(Map<String, dynamic> json) {
    return DonationRequest(
      id: json['id'] as String,
      donationId: json['donationId'] as String,
      donationTitle: json['donationTitle'] as String? ?? 'Untitled Donation',
      ngoId: json['ngoId'] as String,
      ngoName: json['ngoName'] as String,
      deliveryMode: DeliveryMode.fromString(json['deliveryMode'] as String),
      status: RequestStatus.fromString(json['status'] as String),
      dropoffAddress: json['dropoffAddress'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  String toString() {
    return 'DonationRequest(id: $id, donationId: $donationId, deliveryMode: ${deliveryMode.label}, status: ${status.label})';
  }
}
