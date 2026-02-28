import 'package:cloud_firestore/cloud_firestore.dart';

enum FoodType {
  bakedGoods,
  freshProduce,
  cookedFood,
  drinks, // Renamed from rawIngredients
  packagedFood,
  other;

  String get label {
    switch (this) {
      case FoodType.bakedGoods:
        return 'Baked Goods';
      case FoodType.freshProduce:
        return 'Fresh Produce';
      case FoodType.cookedFood:
        return 'Cooked Food';
      case FoodType.drinks:
        return 'Drinks';
      case FoodType.packagedFood:
        return 'Packaged Food';
      case FoodType.other:
        return 'Other';
    }
  }

  static FoodType fromString(String value) {
    return FoodType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FoodType.other,
    );
  }
}

/// Donation status lifecycle
enum DonationStatus {
  available,
  requested,
  assigned,
  completed,
  expired,
  cancelled;

  String get label {
    switch (this) {
      case DonationStatus.available:
        return 'Available';
      case DonationStatus.requested:
        return 'Requested';
      case DonationStatus.assigned:
        return 'Assigned';
      case DonationStatus.completed:
        return 'Completed';
      case DonationStatus.expired:
        return 'Expired';
      case DonationStatus.cancelled:
        return 'Cancelled';
    }
  }

  static DonationStatus fromString(String value) {
    return DonationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DonationStatus.available,
    );
  }
}

/// Represents a food donation created by vendors/donors
class Donation {
  final String id;
  final String vendorId;
  final String vendorName;
  final FoodType foodType;
  final String title;
  final String? description;
  final String quantity;
  final String? unit;
  final DateTime expiryTime;
  final DateTime? pickupWindowStart;
  final DateTime? pickupWindowEnd;
  final String pickupAddress;
  final GeoPoint? location;
  final bool containsAllergens;
  final List<String>? photos; // Changed from photoBase64 to support multiple photos
  final DonationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Donation({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.foodType,
    required this.title,
    this.description,
    required this.quantity,
    this.unit,
    required this.expiryTime,
    this.pickupWindowStart,
    this.pickupWindowEnd,
    required this.pickupAddress,
    this.location,
    this.containsAllergens = false,
    this.photos,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a copy with updated fields
  Donation copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    FoodType? foodType,
    String? title,
   String? description,
    String? quantity,
    String? unit,
    DateTime? expiryTime,
    DateTime? pickupWindowStart,
    DateTime? pickupWindowEnd,
    String? pickupAddress,
    GeoPoint? location,
    bool? containsAllergens,
    List<String>? photos,
    DonationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Donation(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      foodType: foodType ?? this.foodType,
      title: title ?? this.title,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryTime: expiryTime ?? this.expiryTime,
      pickupWindowStart: pickupWindowStart ?? this.pickupWindowStart,
      pickupWindowEnd: pickupWindowEnd ?? this.pickupWindowEnd,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      location: location ?? this.location,
      containsAllergens: containsAllergens ?? this.containsAllergens,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'foodType': foodType.name,
      'title': title,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'expiryTime': Timestamp.fromDate(expiryTime),
      'pickupWindowStart': pickupWindowStart != null ? Timestamp.fromDate(pickupWindowStart!) : null,
      'pickupWindowEnd': pickupWindowEnd != null ? Timestamp.fromDate(pickupWindowEnd!) : null,
      'pickupAddress': pickupAddress,
      'location': location,
      'containsAllergens': containsAllergens,
      'photos': photos,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create from Firestore JSON
  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String,
      foodType: FoodType.fromString(json['foodType'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as String,
      unit: json['unit'] as String?,
      expiryTime: (json['expiryTime'] as Timestamp).toDate(),
      pickupWindowStart: json['pickupWindowStart'] != null ? (json['pickupWindowStart'] as Timestamp).toDate() : null,
      pickupWindowEnd: json['pickupWindowEnd'] != null ? (json['pickupWindowEnd'] as Timestamp).toDate() : null,
      pickupAddress: json['pickupAddress'] as String,
      location: json['location'] as GeoPoint?,
      containsAllergens: json['containsAllergens'] as bool? ?? false,
      photos: json['photos'] != null ? List<String>.from(json['photos'] as List) : null,
      status: DonationStatus.fromString(json['status'] as String),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  String toString() {
    return 'Donation(id: $id, title: $title, status: ${status.label}, expiryTime: $expiryTime)';
  }
}
