import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_item.dart';

/// Repository for managing notifications in Firestore
class NotificationRepository {
  NotificationRepository({
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  /// Create a new notification
  Future<void> createNotification(NotificationItem notification) async {
    try {
      print('🔔 Creating notification for recipient: ${notification.recipientId}');
      print('   Title: ${notification.title}');
      print('   Message: ${notification.message}');
      print('   Type: ${notification.type}');
      
      final docRef = _notifications.doc();
      final newNotification = notification.copyWith(id: docRef.id);
      
      print('   Document ID: ${docRef.id}');
      print('   JSON: ${newNotification.toJson()}');
      
      await docRef.set(newNotification.toJson());
      
      print('✅ Notification created successfully with ID: ${docRef.id}');
    } catch (e, stackTrace) {
      print('❌ ERROR creating notification: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snapshot = await _notifications
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).delete();
  }

  /// Stream notifications for a specific user
  Stream<List<NotificationItem>> watchNotifications(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        // .orderBy('createdAt', descending: true) // Removed to avoid index requirement
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationItem.fromJson(doc.data()))
          .toList();
      
      // Sort client-side
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return notifications;
    });
  }
  
  /// Get unread count stream
  Stream<int> watchUnreadCount(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
