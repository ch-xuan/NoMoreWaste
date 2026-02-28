import 'package:flutter/material.dart';
import 'dart:convert'; // Added for base64 decoding
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/models/delivery_task.dart';
import '../../../data/models/notification_item.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../volunteer/delivery/active_delivery_screen.dart';
import '../../notifications/notification_screen.dart';

class VolunteerDashboardScreen extends StatelessWidget {
  const VolunteerDashboardScreen({super.key, required this.volunteerName});
  final String volunteerName;

  Future<void> _acceptTask(BuildContext context, DeliveryTask task) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD), // Light blue bg
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping, size: 40, color: Color(0xFF2196F3)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Accept Delivery Task',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to accept this delivery request from ${task.pickupName}?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         foregroundColor: Colors.grey.shade600,
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final taskRepo = TaskRepository();
      // userId is already defined at start of function
      final success = await taskRepo.acceptTask(task.id, userId);

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        if (success) {
          // Navigate to Active Delivery Screen immediately
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActiveDeliveryScreen(task: task.copyWith(status: TaskStatus.accepted)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task was already taken by another volunteer'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF7F3EA);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final taskRepo = TaskRepository();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Good Evening, $volunteerName',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                        color: Color(0xFF3A2C23),
                      ),
                    ),
                  ),
                  _NotificationButton(userId: userId),
                ],
              ),
              const SizedBox(height: 16),

              // Active Delivery Banner
              StreamBuilder<List<DeliveryTask>>(
                stream: taskRepo.watchVolunteerTasks(userId),
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? [];
                  final activeTask = tasks.where((t) => 
                    t.status == TaskStatus.accepted || t.status == TaskStatus.pickedUp
                  ).firstOrNull;

                  if (activeTask == null) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3949AB), Color(0xFF283593)], // Indigo gradient
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3949AB).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActiveDeliveryScreen(task: activeTask),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.local_shipping, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Delivery in Progress',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Tap to continue',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),


              // Blue Impact Card
              const Text(
                'My Impact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3A2C23),
                ),
              ),
              const SizedBox(height: 12),
              
              FutureBuilder<Map<String, dynamic>>(
                future: taskRepo.getVolunteerStats(userId),
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {
                    'deliveriesCompleted': 0,
                    'hoursVolunteered': 0,
                  };
                  return _ImpactStatsCard(
                    deliveries: stats['deliveriesCompleted'] ?? 0,
                    hours: stats['hoursVolunteered'] ?? 0,
                    rating: 0.0, 
                  );
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Available Delivery Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 12),

              // Available Tasks Stream
              StreamBuilder<List<DeliveryTask>>(
                stream: taskRepo.watchAvailableTasks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF1B7F5A))));
                  }

                  if (snapshot.hasError) {
                    return _SoftCard(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Builder(
                          builder: (context) {
                            debugPrint('Error loading tasks: ${snapshot.error}');
                            return const Text('Error loading tasks', textAlign: TextAlign.center);
                          }
                        ),
                      ),
                    );
                  }

                  final tasks = snapshot.data ?? [];

                  if (tasks.isEmpty) {
                    return _SoftCard(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.task_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No available tasks',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for new delivery opportunities',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: tasks.map((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TaskCard(
                          task: task,
                          onAccept: () => _acceptTask(context, task),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// NOTIFICATION BUTTON & UI COMPONENTS
// ==========================================

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final notificationRepo = NotificationRepository();

    return StreamBuilder<List<NotificationItem>>(
      stream: notificationRepo.watchNotifications(userId),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return Stack(
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => NotificationScreen(userId: userId)),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EA), // Match dashboard bg
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.notifications_outlined, size: 24, color: Color(0xFF3A2C23)),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child, this.padding, this.color});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ImpactStatsCard extends StatelessWidget {
  const _ImpactStatsCard({
    required this.deliveries,
    required this.hours,
    required this.rating,
  });

  final int deliveries;
  final int hours;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('DELIVERIES', '$deliveries', Icons.local_shipping, '+2'),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          _buildStat('HOURS', '$hours', Icons.schedule, '+5h'),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          _buildStat('RATING', '$rating', Icons.star, null),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData? icon, String? change) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        if (change != null)
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
             decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.2),
               borderRadius: BorderRadius.circular(12),
             ),
             child: Text(
               change,
               style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
             ),
           )
        else if (icon != null)
           Icon(icon, color: Colors.amber, size: 20),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onAccept,
  });

  final DeliveryTask task;
  final VoidCallback onAccept;

  ImageProvider? _getImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    try {
      return MemoryImage(base64Decode(url));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    image: task.imageUrl != null 
                        ? DecorationImage(
                            image: _getImageProvider(task.imageUrl!)!,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: task.imageUrl == null
                      ? Icon(Icons.image_not_supported, color: Colors.grey.shade400)
                      : null,
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.donationTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Description
                      if (task.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            task.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                      const SizedBox(height: 12),
                      
                      // Stepper: Pickup
                      Row(
                        children: [
                          Icon(Icons.radio_button_checked, size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(text: 'Pickup: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold)),
                                  TextSpan(text: task.pickupName, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Connector line
                      Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Container(
                          width: 2,
                          height: 12,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      
                      // Stepper: Dropoff
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Color(0xFF2196F3)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(text: 'Dropoff: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold)),
                                  TextSpan(text: task.dropoffName, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Divider(height: 1, color: Colors.grey.shade100),
          
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.directions_car, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${task.estimatedDistanceKm} km', 
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('•', style: TextStyle(color: Colors.grey.shade400)),
                ),
                
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${task.estimatedDurationMinutes} min',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                
                const Spacer(),
                
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

