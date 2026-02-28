import 'package:cloud_firestore/cloud_firestore.dart';

/// Task status lifecycle
enum TaskStatus {
  open,
  accepted,
  pickedUp,
  delivered,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case TaskStatus.open:
        return 'Open';
      case TaskStatus.accepted:
        return 'In Progress'; // User requested "in-progress" for accepted state
      case TaskStatus.pickedUp:
        return 'Picked Up';
      case TaskStatus.delivered:
        return 'Delivered';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  static TaskStatus fromString(String value) {
    // Handle user's "in-progress" mapping if needed, or just standard enum names
    return TaskStatus.values.firstWhere(
      (e) => e.name == value || (value == 'in-progress' && e == TaskStatus.accepted),
      orElse: () => TaskStatus.open,
    );
  }
}

/// Represents a delivery task for volunteers
class DeliveryTask {
  final String id;
  final String donationId;
  final String donationTitle;
  final String? description;
  final String? pickupWindowStart;
  final String? pickupWindowEnd;
  final String quantity; 
  final String? unit; // Added unit
  final String requestId; // Kept for reference
  
  final String vendorId;
  final String ngoId;
  final String? volunteerId;
  final String? imageUrl;
  
  final String pickupAddress;
  final String dropoffAddress;
  final String pickupName;
  final String dropoffName;
  
  final TaskStatus status;
  
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt; // Usually same as deliveredAt if auto-complete

  // Proof data
  final Map<String, dynamic> proof;

  const DeliveryTask({
    required this.id,
    required this.donationId,
    required this.donationTitle,
    this.description,
    this.pickupWindowStart,
    this.pickupWindowEnd,

    required this.quantity,
    this.unit,
    required this.requestId,
    required this.vendorId,
    required this.ngoId,
    this.volunteerId,
    this.imageUrl,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupName,
    required this.dropoffName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.completedAt,
    this.proof = const {
      'pickupCode': null,
      'deliveryCode': null,
      'deliveryNote': null,
      'pickupPhotos': [],
      'deliveryPhotos': [],
    },
  });

  /// Create a copy with updated fields
  DeliveryTask copyWith({
    String? id,
    String? donationId,
    String? donationTitle,
    String? description,
    String? pickupWindowStart,
    String? pickupWindowEnd,
    String? quantity,
    String? unit,
    String? requestId,
    String? vendorId,
    String? ngoId,
    String? volunteerId,
    String? imageUrl,
    String? pickupAddress,
    String? dropoffAddress,
    String? pickupName,
    String? dropoffName,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? completedAt,
    Map<String, dynamic>? proof,
  }) {
    return DeliveryTask(
      id: id ?? this.id,
      donationId: donationId ?? this.donationId,
      donationTitle: donationTitle ?? this.donationTitle,
      description: description ?? this.description,
      pickupWindowStart: pickupWindowStart ?? this.pickupWindowStart,
      pickupWindowEnd: pickupWindowEnd ?? this.pickupWindowEnd,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      requestId: requestId ?? this.requestId,
      vendorId: vendorId ?? this.vendorId,
      ngoId: ngoId ?? this.ngoId,
      volunteerId: volunteerId ?? this.volunteerId,
      imageUrl: imageUrl ?? this.imageUrl,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      pickupName: pickupName ?? this.pickupName,
      dropoffName: dropoffName ?? this.dropoffName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      completedAt: completedAt ?? this.completedAt,
      proof: proof ?? this.proof,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donationId': donationId,
      'donationTitle': donationTitle,
      'description': description,
      'pickupWindowStart': pickupWindowStart,
      'pickupWindowEnd': pickupWindowEnd,
      'quantity': quantity,
      'unit': unit,
      'requestId': requestId,
      'vendorId': vendorId,
      'ngoId': ngoId,
      'volunteerId': volunteerId,
      'imageUrl': imageUrl,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'pickupName': pickupName,
      'dropoffName': dropoffName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'proof': proof,
    };
  }

  /// Create from Firestore JSON
  factory DeliveryTask.fromJson(Map<String, dynamic> json) {
    return DeliveryTask(
      id: json['id'] as String? ?? '',
      donationId: json['donationId'] as String? ?? '',
      donationTitle: json['donationTitle'] as String? ?? 'Untitled Donation',
      description: json['description'] as String?,
      pickupWindowStart: json['pickupWindowStart'] as String?,
      pickupWindowEnd: json['pickupWindowEnd'] as String?,
      quantity: json['quantity'] as String? ?? '1 unit',
      unit: json['unit'] as String?,
      requestId: json['requestId'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? '',
      ngoId: json['ngoId'] as String? ?? '',
      volunteerId: json['volunteerId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      pickupAddress: json['pickupAddress'] as String? ?? '',
      dropoffAddress: json['dropoffAddress'] as String? ?? '',
      pickupName: json['pickupName'] as String? ?? '',
      dropoffName: json['dropoffName'] as String? ?? '',
      status: TaskStatus.fromString(json['status'] as String? ?? 'open'),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null ? (json['updatedAt'] as Timestamp).toDate() : null,
      acceptedAt: json['acceptedAt'] != null ? (json['acceptedAt'] as Timestamp).toDate() : null,
      pickedUpAt: json['pickedUpAt'] != null ? (json['pickedUpAt'] as Timestamp).toDate() : null,
      deliveredAt: json['deliveredAt'] != null ? (json['deliveredAt'] as Timestamp).toDate() : null,
      completedAt: json['completedAt'] != null ? (json['completedAt'] as Timestamp).toDate() : null,
      proof: json['proof'] != null ? Map<String, dynamic>.from(json['proof']) : {
        'pickupCode': null,
        'deliveryCode': null,
        'deliveryNote': null,
        'pickupPhotos': [],
        'deliveryPhotos': [],
      },
    );
  }

  /// Calculate estimated delivery duration in minutes
  /// This is a placeholder - would integrate with maps API in production
  int get estimatedDurationMinutes => 30;

  /// Calculate distance in km
  /// This is a placeholder - would integrate with maps API in production
  double get estimatedDistanceKm => 5.0;

  @override
  String toString() {
    return 'DeliveryTask(id: $id, status: ${status.label}, title: $donationTitle)';
  }
}
