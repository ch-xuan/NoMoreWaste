import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/models/user_role.dart';
import '../../data/models/delivery_task.dart';
import '../../data/models/donation_request.dart';
import '../../data/models/donation.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/request_repository.dart';
import '../../data/repositories/donation_repository.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      appBar: AppBar(
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(userId),
    );
  }

  Widget _buildBody(String userId) {
    switch (role) {
      case UserRole.volunteer:
        return _VolunteerHistoryList(userId: userId);
      case UserRole.ngo:
        return _NgoHistoryList(userId: userId);
      case UserRole.donor: // Vendor
        return _VendorHistoryList(userId: userId);
    }
  }
}

class _VolunteerHistoryList extends StatelessWidget {
  const _VolunteerHistoryList({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final taskRepo = TaskRepository();
    // Use existing WatchVolunteerTasks - filter for completed on the UI side if query doesn't support it yet, 
    // or assume the repo method returns all and we filter.
    // TaskRepository.watchVolunteerTasks returns all tasks for the volunteer.
    return StreamBuilder<List<DeliveryTask>>(
      stream: taskRepo.watchVolunteerTasks(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? [];
        final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();
        
        // Sort by completedAt descending
        completedTasks.sort((a, b) {
           final aTime = a.completedAt ?? a.createdAt;
           final bTime = b.completedAt ?? b.createdAt;
           return bTime.compareTo(aTime);
        });

        if (completedTasks.isEmpty) {
          return const Center(child: Text('No completed deliveries yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: completedTasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final task = completedTasks[index];
            return _HistoryCard(
              title: task.donationTitle,
              subtitle: 'Delivered to ${task.dropoffName}',
              date: task.completedAt ?? task.createdAt,
              status: 'Delivered',
              statusColor: Colors.green,
              icon: Icons.check_circle_outline,
            );
          },
        );
      },
    );
  }
}

class _NgoHistoryList extends StatelessWidget {
  const _NgoHistoryList({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final requestRepo = RequestRepository();
    
    // We need a watchNgoRequests method. 
    // Assuming RequestRepository has a method to watch requests for an NGO.
    // If not, we might need to add it. Based on plan check, I need to verify its existence.
    // But for now, I'll assume standard naming pattern or use what I found.
    // I found `watchNgoRequests` in previous grep.
    return StreamBuilder<List<DonationRequest>>(
      stream: requestRepo.watchNgoRequests(userId),
      builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? [];
        
        // Filter for requests relevant to history (Completed, Rejected, Cancelled, Approved, Pending, Assigned)
        final historyRequests = requests.where((r) {
          return r.status == RequestStatus.completed || 
          r.status == RequestStatus.rejected ||
          r.status == RequestStatus.cancelled ||
          r.status == RequestStatus.approved ||
          r.status == RequestStatus.assigned ||
          r.status == RequestStatus.pending;
        }).toList();
        
        if (historyRequests.isEmpty) {
          return const Center(child: Text('No history available.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: historyRequests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final req = historyRequests[index];
            Color statusColor = Colors.grey;
            String statusText = req.status.name.toUpperCase();
            IconData icon = Icons.history;

            if (req.status == RequestStatus.completed) {
              statusColor = Colors.green;
              statusText = 'RECEIVED';
              icon = Icons.check_circle;
            } else if (req.status == RequestStatus.approved) {
              statusColor = Colors.blue;
              statusText = 'APPROVED';
              icon = Icons.thumb_up;
            } else if (req.status == RequestStatus.rejected) {
            } else if (req.status == RequestStatus.rejected) {
              statusColor = Colors.red;
              statusText = 'REJECTED';
              icon = Icons.cancel;
            } else if (req.status == RequestStatus.pending) {
              statusColor = Colors.orange;
              statusText = 'PENDING';
              icon = Icons.hourglass_empty;
            } else if (req.status == RequestStatus.assigned) {
              statusColor = Colors.blue; 
              statusText = 'ASSIGNED';
              icon = Icons.local_shipping;
            }

            return _HistoryCard(
              title: req.donationTitle,
              subtitle: 'From ${req.ngoName}', // Actually this is TO the NGO, but req.ngoName is the NGO's name. Maybe show Vendor name? Request model might not have vendor name directly? Request has `donationId`.
              // Let's stick to simple info.
              date: req.updatedAt ?? req.createdAt,
              status: statusText,
              statusColor: statusColor,
              icon: icon,
            );
          },
        );
      },
    );
  }
}

class _VendorHistoryList extends StatelessWidget {
  const _VendorHistoryList({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    final donationRepo = DonationRepository();

    return StreamBuilder<List<Donation>>(
      stream: donationRepo.watchVendorDonations(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final donations = snapshot.data ?? [];
        // Filter for completed/claimed/expired
        final historyDonations = donations.where((d) => 
          d.status == DonationStatus.completed || 
          d.status == DonationStatus.assigned || // Assigned to volunteer/NGO
          d.status == DonationStatus.expired
        ).toList();

        if (historyDonations.isEmpty) {
          return const Center(child: Text('No donation history.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: historyDonations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final donation = historyDonations[index];
             Color statusColor = Colors.grey;
            String statusText = donation.status.name.toUpperCase();
            IconData icon = Icons.history;

            if (donation.status == DonationStatus.completed) {
              statusColor = Colors.green;
              statusText = 'DONATED';
              icon = Icons.volunteer_activism;
            } else if (donation.status == DonationStatus.expired) {
              statusColor = Colors.orange;
              statusText = 'EXPIRED';
              icon = Icons.timer_off;
            }

            return _HistoryCard(
              title: donation.title,
              subtitle: '${donation.quantity} ${donation.unit}',
              date: donation.updatedAt ?? donation.createdAt,
              status: statusText,
              statusColor: statusColor,
              icon: icon,
            );
          },
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final DateTime date;
  final String status;
  final Color statusColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                 Text(
                   '${date.day}/${date.month}/${date.year}', 
                   style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                 ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
