import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/donation.dart';
import '../../../data/repositories/donation_repository.dart';
import 'edit_donation_screen.dart';

/// Donation Details Screen showing full information about a donation
class DonationDetailsScreen extends StatefulWidget {
  const DonationDetailsScreen({super.key, required this.donation});

  final Donation donation;

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final _donationRepo = DonationRepository();
  late Donation _donation;

  @override
  void initState() {
    super.initState();
    _donation = widget.donation;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use local _donation variable instead of widget.donation
    final hasPhotos = _donation.photos != null && _donation.photos!.isNotEmpty;
    final photoCount = _donation.photos?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      appBar: AppBar(
        title: const Text('Donation Details'),
        backgroundColor: const Color(0xFF22A45D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditDonationScreen(donation: _donation),
                ),
              );

              if (result is Donation && mounted) {
                // Update local state immediately
                setState(() {
                  _donation = result;
                  _currentImageIndex = 0; // Reset slider
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Details updated!')),
                );
              }
            },
            tooltip: 'Edit Donation',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Cancel Donation',
            onPressed: () async {
               final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Donation?'),
                  content: const Text(
                    'Are you sure you want to cancel this donation? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Yes, Cancel'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                try {
                  await _donationRepo.cancelDonation(_donation.id);
                  
                  if (mounted) {
                    Navigator.pop(context); // Go back
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Donation cancelled')),
                    );
                  }
                } catch (e) {
                   if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slider with Indicators
            if (hasPhotos)
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 250,
                          child: PageView.builder(
                            physics: const BouncingScrollPhysics(),
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _currentImageIndex = index);
                            },
                            itemCount: photoCount,
                            itemBuilder: (context, index) {
                              return Image.memory(
                                base64Decode(_donation.photos![index]),
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                      // Previous Button
                      if (_currentImageIndex > 0)
                        Positioned(
                          left: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            radius: 18,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                      // Next Button
                      if (_currentImageIndex < photoCount - 1)
                        Positioned(
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            radius: 18,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (photoCount > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        photoCount,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                              ? const Color(0xFF22A45D)
                              : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 20),

            // Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    _donation.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A2C23),
                    ),
                  ),
                ),
                _StatusBadge(status: _donation.status),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            if (_donation.description != null && _donation.description!.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3A2C23)),
              ),
              const SizedBox(height: 8),
              Text(
                _donation.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
              ),
              const SizedBox(height: 20),
            ],

            // Details Grid
            _DetailCard(
              children: [
                _DetailRow(icon: Icons.category, label: 'Category', value: _donation.foodType.label),
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.inventory_2,
                  label: 'Quantity',
                  value: '${_donation.quantity} ${_donation.unit ?? ""}',
                ),
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.access_time,
                  label: 'Expires',
                  value: _formatDateTime(_donation.expiryTime),
                ),
                if (_donation.pickupWindowStart != null && _donation.pickupWindowEnd != null) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.schedule,
                    label: 'Pickup Window',
                    value: '${_formatTime(_donation.pickupWindowStart!)} - ${_formatTime(_donation.pickupWindowEnd!)}',
                  ),
                ],
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'Pickup Location',
                  value: _donation.pickupAddress,
                ),
                if (_donation.containsAllergens) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.warning_amber,
                    label: 'Allergens',
                    value: 'Contains allergens',
                    valueColor: Colors.orange,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${_formatTime(dt)}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DonationStatus status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    switch (status) {
      case DonationStatus.available:
        backgroundColor = const Color(0xFF4CAF50);
        break;
      case DonationStatus.requested:
        backgroundColor = const Color(0xFFE7C69F);
        break;
      case DonationStatus.assigned:
        backgroundColor = const Color(0xFFB8D4F1);
        break;
      case DonationStatus.completed:
        backgroundColor = const Color(0xFFE0E0E0);
        break;
      case DonationStatus.expired:
        backgroundColor = const Color(0xFFE57373);
        break;
      case DonationStatus.cancelled:
        backgroundColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF22A45D)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? const Color(0xFF3A2C23),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
