import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat conversation between two users
class ChatThread {
  final String id;
  final List<String> participantIds; // [userId1, userId2]
  final Map<String, String> participantNames; // {userId: displayName}
  final Map<String, String> participantRoles; // {userId: role}
  final String? taskId; // Delivery task this chat is for
  final String? taskTitle; // e.g., "Bakery Surplus Pickup"
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount; // {userId: count}
  final DateTime createdAt;
  final DateTime? expiresAt; // Auto-delete after 7 days

  const ChatThread({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantRoles,
    this.taskId,
    this.taskTitle,
    this.lastMessage,
    this.lastSenderId,
    this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
    this.expiresAt,
  });

  /// Create from Firestore document
  factory ChatThread.fromFirestore(Map<String, dynamic> data) {
    return ChatThread(
      id: data['id'] as String,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantRoles: Map<String, String>.from(data['participantRoles'] ?? {}),
      taskId: data['taskId'] as String?,
      taskTitle: data['taskTitle'] as String?,
      lastMessage: data['lastMessage'] as String?,
      lastSenderId: data['lastSenderId'] as String?,
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantRoles': participantRoles,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  /// Get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId);
  }

  /// Get the other participant's name
  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown';
  }

  /// Get the other participant's role
  String getOtherParticipantRole(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantRoles[otherId] ?? 'user';
  }

  /// Check if chat has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
