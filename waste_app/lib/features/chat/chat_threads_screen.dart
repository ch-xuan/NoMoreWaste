import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/chat_thread.dart';
import '../../data/models/user_role.dart';
import 'chat_room_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatThreadsScreen extends StatefulWidget {
  const ChatThreadsScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<ChatThreadsScreen> createState() => _ChatThreadsScreenState();
}

class _ChatThreadsScreenState extends State<ChatThreadsScreen> {
  final _chatRepo = ChatRepository();
  final _userRepo = UserRepository();

  Color get _themeColor {
    switch (widget.role) {
      case UserRole.volunteer:
        return const Color(0xFF2196F3); // Blue
      case UserRole.ngo:
        return const Color(0xFFFF9800); // Orange
      case UserRole.donor:
        return const Color(0xFF4CAF50); // Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3A2C23),
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatThread>>(
        stream: _chatRepo.watchUserThreads(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final threads = snapshot.data ?? [];

          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No Messages Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              final otherUserId = thread.getOtherParticipantId(currentUser.uid);
              final otherUserName = thread.getOtherParticipantName(currentUser.uid);
              final otherUserRole = thread.getOtherParticipantRole(currentUser.uid);
              final unreadCount = thread.unreadCount[currentUser.uid] ?? 0;
              final isUnread = unreadCount > 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isUnread ? 3 : 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: _getRoleColor(otherUserRole),
                    child: Text(
                      otherUserName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (thread.lastMessageTime != null)
                        Text(
                          timeago.format(thread.lastMessageTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnread ? _themeColor : Colors.grey.shade600,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleColor(otherUserRole).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getRoleLabel(otherUserRole),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getRoleColor(otherUserRole),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (thread.taskTitle != null) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '• ${thread.taskTitle}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.lastMessage ?? 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isUnread ? const Color(0xFF3A2C23) : Colors.grey.shade600,
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _themeColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    // Mark as read when opening
                    _chatRepo.markThreadAsRead(thread.id, currentUser.uid);
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          threadId: thread.id,
                          otherUserId: otherUserId,
                          otherUserName: otherUserName,
                          otherUserRole: otherUserRole,
                          currentUserRole: widget.role,
                          taskTitle: thread.taskTitle,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'volunteer':
        return const Color(0xFF2196F3);
      case 'ngo':
        return const Color(0xFFFF9800);
      case 'donor':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'volunteer':
        return 'Volunteer';
      case 'ngo':
        return 'NGO';
      case 'donor':
        return 'Donor';
      default:
        return 'User';
    }
  }
}
