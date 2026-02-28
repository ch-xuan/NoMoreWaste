import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/donation_repository.dart';
import '../../../data/models/donation.dart';
import '../../../data/models/donation_request.dart';
import '../../../data/models/notification_item.dart';
import '../../../data/repositories/donation_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/request_repository.dart';
import '../donation_form/create_donation_screen.dart';
import '../../notifications/notification_screen.dart';
import '../widgets/donation_details_screen.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key, required this.companyName});
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF7F3EA);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final donationRepo = DonationRepository();

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD0893E),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateDonationScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Stream auto-refreshes, just wait briefly for UX
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Good Evening, $companyName',
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
              const SizedBox(height: 8),
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 14),

              // Stats Section - Real-time
              FutureBuilder<Map<String, dynamic>>(
                future: donationRepo.getDonationStats(userId),
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {
                    'totalKg': 0.0,
                    'totalMeals': 0,
                    'totalCO2': 0.0,
                    'totalDonations': 0,
                  };

                  return GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.55,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _StatTile(
                        title: 'Kilograms\nDonated',
                        value: '${stats['totalKg'].toStringAsFixed(0)}kg',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFFE08E36),
                      ),
                      _StatTile(
                        title: 'CO2\nAvoided',
                        value: '${stats['totalCO2'].toStringAsFixed(0)}kg',
                        icon: Icons.eco_outlined,
                        color: const Color(0xFF4FA463),
                      ),
                      _StatTile(
                        title: 'Meals\nProvided',
                        value: '${stats['totalMeals']}',
                        icon: Icons.restaurant_outlined,
                        color: const Color(0xFF4E8CCB),
                      ),
                      _StatTile(
                        title: 'Total\nDonations',
                        value: '${stats['totalDonations']}',
                        icon: Icons.all_inbox_outlined,
                        color: const Color(0xFF8A63B8),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              Text(
                'Donation Listings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 12),

              // Active Listings - Real-time stream
              StreamBuilder<List<Donation>>(
                stream: donationRepo.watchVendorDonations(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B7F5A),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final donations = snapshot.data ?? [];

                  if (donations.isEmpty) {
                    return _SoftCard(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No donations yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to create your first donation',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }


                  // Horizontal carousel for donations
                  return SizedBox(
                    height: 320,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 16),
                      itemCount: donations.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _ListingCard(
                            donation: donations[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DonationDetailsScreen(donation: donations[index]),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
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
// NOTIFICATION SYSTEM UI COMPONENTS
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

        // Format tooltip with 3 most recent notifications
        String tooltipMessage;
        if (notifications.isEmpty) {
          tooltipMessage = 'No notifications';
        } else {
          final recent = notifications.take(3);
          tooltipMessage = recent.map((n) => '• ${n.title}').join('\n');
          if (notifications.length > 3) {
            tooltipMessage += '\n...and ${notifications.length - 3} more';
          }
        }

        return Stack(
          alignment: Alignment.center, // Ensure alignment for badge
          children: [
            Tooltip(
              message: tooltipMessage,
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(fontSize: 12, color: Colors.white, height: 1.5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationScreen(userId: userId),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
  const _SoftCard({required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 8),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 8),
            color: Color(0x12000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.donation,
    required this.onTap,
  });

  final Donation donation;
  final VoidCallback onTap;

  String get _foodEmoji {
    switch (donation.foodType) {
      case FoodType.bakedGoods:
        return '🥐';
      case FoodType.freshProduce:
        return '🥬';
      case FoodType.cookedFood:
        return '🍱';
      case FoodType.drinks:
        return '🥤';
      case FoodType.packagedFood:
        return '📦';
      case FoodType.other:
        return '🍽️';
    }
  }

  Color get _statusColor {
    switch (donation.status) {
      case DonationStatus.available:
        return const Color(0xFF4CAF50); // Brighter green
      case DonationStatus.requested:
        return const Color(0xFFE7C69F);
      case DonationStatus.assigned:
        return const Color(0xFFB8D4F1);
      case DonationStatus.completed:
        return const Color(0xFFE0E0E0);
      case DonationStatus.expired:
        return const Color(0xFFE57373);
      case DonationStatus.cancelled:
        return Colors.grey;
    }
  }

  String get _expiryText {
    final now = DateTime.now();
    final difference = donation.expiryTime.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inHours < 24) {
      return 'Expires in ${difference.inHours}h';
    } else {
      return 'Expires in ${difference.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: donation.photos != null && donation.photos!.isNotEmpty
                  ? Image.memory(
                      base64Decode(donation.photos!.first),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 160,
                      width: double.infinity,
                      color: const Color(0xFFF2E8D8),
                      child: Center(
                        child: Text(_foodEmoji, style: const TextStyle(fontSize: 60)),
                      ),
                    ),
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          donation.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A2C23),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          donation.status.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Quantity
                  Text(
                    '${donation.quantity} ${donation.unit ?? ""}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Expiry
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _expiryText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // View Details Link
                  InkWell(
                    onTap: onTap,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: Color(0xFFD0893E),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: Color(0xFFD0893E),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
