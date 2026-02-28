import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of notifications in the system
enum NotificationType {
  requestReceived, // For Vendor: New request from NGO
  requestApproved, // For NGO: Vendor approved request
  requestRejected, // For NGO: Vendor rejected request
  accountPending,  // For User: Account awaiting verification
  accountVerified, // For User: Account has been verified
  deliveryUpdate,  // Future use
}

/// Represents a notification for a user (Vendor or NGO)
class NotificationItem {
  final String id;
  final String recipientId; // User who gets the notification
  final String senderId;    // User who triggered it
  final String title;
  final String message;
  final NotificationType type;
  final String entityId;    // ID of the related object (requestId)
  final bool isRead;
  final DateTime createdAt;
  
  const NotificationItem({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.title,
    required this.message,
    required this.type,
    required this.entityId,
    this.isRead = false,
    required this.createdAt,
  });
  
  /// Create a copy with updated fields
  NotificationItem copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? title,
    String? message,
    NotificationType? type,
    String? entityId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'senderId': senderId,
      'title': title,
      'message': message,
      'type': type.name,
      'entityId': entityId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  /// Create from Firestore JSON
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      recipientId: json['recipientId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (json['type'] as String),
        orElse: () => NotificationType.deliveryUpdate,
      ),
      entityId: json['entityId'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}
