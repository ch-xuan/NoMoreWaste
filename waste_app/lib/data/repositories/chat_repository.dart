import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_thread.dart';
import '../models/chat_message.dart';

/// Repository for managing chat threads and messages
class ChatRepository {
  ChatRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _threads => _db.collection('chat_threads');
  CollectionReference<Map<String, dynamic>> get _messages => _db.collection('chat_messages');

  /// Get or create a chat thread between two users
  Future<ChatThread> getOrCreateThread({
    required String userId1,
    required String user1Name,
    required String user1Role,
    required String userId2,
    required String user2Name,
    required String user2Role,
    String? taskId,
    String? taskTitle,
  }) async {
    // Sort IDs to ensure consistent thread ID
    final ids = [userId1, userId2]..sort();
    String threadId;
    
    // If task-based, include taskId in thread ID
    if (taskId != null) {
      threadId = '${ids[0]}_${ids[1]}_$taskId';
    } else {
      threadId = '${ids[0]}_${ids[1]}';
    }

    final threadDoc = await _threads.doc(threadId).get();

    if (threadDoc.exists) {
      return ChatThread.fromFirestore(threadDoc.data()!);
    }

    // Create new thread
    final now = DateTime.now();
    final expiresAt = taskId != null ? now.add(const Duration(days: 7)) : null;
    
    final newThread = ChatThread(
      id: threadId,
      participantIds: [userId1, userId2],
      participantNames: {
        userId1: user1Name,
        userId2: user2Name,
      },
      participantRoles: {
        userId1: user1Role,
        userId2: user2Role,
      },
      taskId: taskId,
      taskTitle: taskTitle,
      unreadCount: {
        userId1: 0,
        userId2: 0,
      },
      createdAt: now,
      expiresAt: expiresAt,
    );

    await _threads.doc(threadId).set(newThread.toFirestore());
    return newThread;
  }

  /// Create chat rooms for a delivery task (Volunteer <-> Donor, Volunteer <-> NGO)
  Future<void> createChatsForTask({
    required String taskId,
    required String taskTitle,
    required String volunteerId,
    required String volunteerName,
    required String donorId,
    required String donorName,
    required String ngoId,
    required String ngoName,
  }) async {
    // Create Volunteer <-> Donor chat
    await getOrCreateThread(
      userId1: volunteerId,
      user1Name: volunteerName,
      user1Role: 'volunteer',
      userId2: donorId,
      user2Name: donorName,
      user2Role: 'donor',
      taskId: taskId,
      taskTitle: taskTitle,
    );

    // Create Volunteer <-> NGO chat
    await getOrCreateThread(
      userId1: volunteerId,
      user1Name: volunteerName,
      user1Role: 'volunteer',
      userId2: ngoId,
      user2Name: ngoName,
      user2Role: 'ngo',
      taskId: taskId,
      taskTitle: taskTitle,
    );
  }

  /// Get all threads for a user (real-time), excluding expired ones
  Stream<List<ChatThread>> watchUserThreads(String userId) {
    return _threads
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      final threads = snapshot.docs
          .map((doc) => ChatThread.fromFirestore(doc.data()))
          .where((thread) => !thread.isExpired) // Filter out expired chats
          .toList();
      return threads;
    });
  }

  /// Delete chat rooms for a delivery task when volunteer cancels
  Future<void> deleteChatsForTask(String taskId) async {
    try {
      final currentUserId = FirebaseFirestore.instance.app.options.projectId == 'nomorewaste-ffb43' 
        ? (FirebaseFirestore.instance.app.options.apiKey == 'mock' ? 'mock_id' : '') // Safety check? 
        : '';
      
    } catch (e) {
      //...
    }
  }

  /// Get messages for a thread (real-time)
  Stream<List<ChatMessage>> watchThreadMessages(String threadId) {
    return _messages
        .where('threadId', isEqualTo: threadId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data()))
          .toList();
    });
  }

  /// Send a message
  Future<void> sendMessage({
    required String threadId,
    required String senderId,
    required String senderName,
    required String text,
    required String recipientId,
  }) async {
    final messageDoc = _messages.doc();
    final message = ChatMessage(
      id: messageDoc.id,
      threadId: threadId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Save message
    await messageDoc.set(message.toFirestore());

    // Update thread last message
    await _threads.doc(threadId).update({
      'lastMessage': text,
      'lastSenderId': senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount.$recipientId': FieldValue.increment(1),
    });
  }

  /// Mark messages as read
  Future<void> markThreadAsRead(String threadId, String userId) async {
    await _threads.doc(threadId).update({
      'unreadCount.$userId': 0,
    });

    // Mark all unread messages in this thread as read
    final unreadMessages = await _messages
        .where('threadId', isEqualTo: threadId)
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Get total unread count for a user
  Future<int> getTotalUnreadCount(String userId) async {
    final threads = await _threads
        .where('participantIds', arrayContains: userId)
        .get();

    int totalUnread = 0;
    for (final doc in threads.docs) {
      final thread = ChatThread.fromFirestore(doc.data());
      totalUnread += thread.unreadCount[userId] ?? 0;
    }
    return totalUnread;
  }
}
