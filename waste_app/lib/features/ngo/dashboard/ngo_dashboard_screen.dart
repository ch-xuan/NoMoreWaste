import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/recommendation_service.dart';
import '../../../data/repositories/donation_repository.dart';
import '../../../data/repositories/request_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/donation.dart';
import '../../../data/models/donation_request.dart';
import '../../../data/models/notification_item.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../notifications/notification_screen.dart';

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key, required this.ngoName});
  final String ngoName;

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  int selectedChip = 0;
  final chips = const ['All', 'Bakery', 'Produce', 'Meals', 'Drinks', 'Packaged'];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  final _donationRepo = DonationRepository();
  final _requestRepo = RequestRepository();
  final _userRepo = UserRepository();
  final _recommendationService = RecommendationService();

  // AI Picks state
  bool _aiPicksEnabled = true; // Default ON
  String? _ngoAddress;
  GeoPoint? _ngoLocation;
  List<DonationRequest> _requestHistory = [];

  @override
  void initState() {
    super.initState();
    _loadNgoProfile();
  }

  Future<void> _loadNgoProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final profile = await _userRepo.getUserProfile(uid);
      if (profile != null && mounted) {
        setState(() {
          _ngoAddress = profile['address'] as String?;
          // Check if profile has a GeoPoint location
          if (profile['location'] is GeoPoint) {
            _ngoLocation = profile['location'] as GeoPoint;
          }
        });
      }
    } catch (e) {
      print('⚠️ Failed to load NGO profile: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  FoodType? get _selectedFoodType {
    switch (selectedChip) {
      case 1:
        return FoodType.bakedGoods;
      case 2:
        return FoodType.freshProduce;
      case 3:
        return FoodType.cookedFood;
      case 4:
        return FoodType.drinks;
      case 5:
        return FoodType.packagedFood;
      default:
        return null; // All
    }
  }

// ... (omitting unchanged parts)



  List<Donation> _filterDonations(List<Donation> donations) {
    if (_searchQuery.isEmpty) return donations;
    
    final query = _searchQuery.toLowerCase();
    return donations.where((donation) {
      return donation.title.toLowerCase().contains(query) ||
             donation.vendorName.toLowerCase().contains(query) ||
             (donation.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _requestDonation(
    BuildContext context,
    Donation donation,
    DeliveryMode deliveryMode,
  ) async {
    print('🟢 === REQUEST DONATION INITIATED ===');
    print('🟢 Donation ID: ${donation.id}');
    print('🟢 Delivery Mode: ${deliveryMode.label}');
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    print('🟢 User ID: $userId');
    
    if (userId == null) {
      print('❌ User not authenticated!');
      return;
    }

    // Check verification status
    print('🟢 Fetching user profile...');
    final userProfile = await _userRepo.getUserProfile(userId);
    print('🟢 User profile: $userProfile');
    print('🟢 User role: ${userProfile?['role']}');
    print('🟢 Verification status: ${userProfile?['verificationStatus']}');
    
    if (userProfile?['verificationStatus'] != 'approved') {
      print('❌ User not approved! Verification status: ${userProfile?['verificationStatus']}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your account is pending verification (Status: ${userProfile?['verificationStatus'] ?? 'unknown'})'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check if already requested
    final hasRequested = await _requestRepo.hasExistingRequest(
      donation.id,
      userId,
    );

    if (hasRequested) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already requested this donation'),
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    if (context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Request'),
          content: Text(
            deliveryMode == DeliveryMode.selfPickup
                ? 'Request this donation for self pick-up?'
                : 'Request volunteer delivery for this donation?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B7F5A),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;
    }

    // Create request
    try {
      final request = DonationRequest(
        id: '',
        donationId: donation.id,
        donationTitle: donation.title,
        ngoId: userId,
        ngoName: userProfile?['orgName'] ?? userProfile?['displayName'] ?? 'Unknown NGO',
        deliveryMode: deliveryMode,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
      );

      // Get current user's address for dropoff
      final dropoffAddress = userProfile?['address'] ?? 'Address not set';

      await _requestRepo.createRequest(
        request,
        pickupAddress: donation.pickupAddress,
        dropoffAddress: dropoffAddress,
        pickupName: donation.vendorName,
        dropoffName: userProfile?['orgName'] ?? 'NGO',
        vendorId: donation.vendorId, // Pass vendorId for notification
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF7F3EA);

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
                      'Good Afternoon, ${widget.ngoName}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                        color: Color(0xFF3A2C23),
                      ),
                    ),
                  ),
                  const _NotificationButton(),
                ],
              ),
              const SizedBox(height: 10),

              // Search bar with filter icon
              _SoftCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search food donations...',
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                            fontWeight: FontWeight.w700,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0893E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // AI Picks toggle + Filter chips
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    // AI Picks toggle
                    GestureDetector(
                      onTap: () => setState(() => _aiPicksEnabled = !_aiPicksEnabled),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: _aiPicksEnabled
                              ? const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                                )
                              : null,
                          color: _aiPicksEnabled ? null : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: _aiPicksEnabled
                              ? [
                                  BoxShadow(
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: _aiPicksEnabled ? Colors.white : Colors.grey.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'AI Picks',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: _aiPicksEnabled ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: chips.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final selected = selectedChip == i;
                          return _ChipPill(
                            text: chips[i],
                            selected: selected,
                            onTap: () => setState(() => selectedChip = i),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Map button
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Map view coming soon!')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0893E),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(blurRadius: 10, offset: Offset(0, 6), color: Color(0x0F000000)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_outlined, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'Map',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                _aiPicksEnabled ? '✨ Recommended for You' : 'Available Near You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 12),

              // Track NGO's requests to show "Requested" tags
              StreamBuilder<List<DonationRequest>>(
                stream: _requestRepo.watchNgoRequests(
                  FirebaseAuth.instance.currentUser?.uid ?? '',
                ),
                builder: (context, requestsSnapshot) {
                  // Build set of requested donation IDs
                  final requestedDonationIds = <String>{};
                  if (requestsSnapshot.hasData) {
                    requestedDonationIds.addAll(
                      requestsSnapshot.data!.map((req) => req.donationId),
                    );
                    // Cache request history for AI recommendation
                    _requestHistory = requestsSnapshot.data!;
                  }

                  // Available AND Requested Donations Stream (so NGO can see their requests)
                  return StreamBuilder<List<Donation>>(
                    stream: _donationRepo.watchAvailableAndRequestedDonations(
                      filterType: _selectedFoodType,
                    ),
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
                        return _SoftCard(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'Welcome to WasteNoMore!',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Available food donations will appear here once vendors start posting.',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final donations = snapshot.data ?? [];
                      final filteredDonations = _filterDonations(donations);

                      if (filteredDonations.isEmpty) {
                        return _SoftCard(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No donations available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters or check back later',
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

                      // Apply AI scoring if enabled
                      if (_aiPicksEnabled) {
                        final scoredDonations = _recommendationService.rankDonations(
                          donations: filteredDonations,
                          ngoAddress: _ngoAddress,
                          ngoLocation: _ngoLocation,
                          requestHistory: _requestHistory,
                        );

                        return Column(
                          children: scoredDonations.asMap().entries.map((entry) {
                            final index = entry.key;
                            final scored = entry.value;
                            final donation = scored.donation;
                            final isRequested = donation.status == DonationStatus.requested;
                            final isTopPick = index < 3;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _NgoDonationCard(
                                donation: donation,
                                isRequested: isRequested,
                                matchPercent: scored.matchPercent,
                                isTopPick: isTopPick,
                                onSelfPickup: () => _requestDonation(
                                  context,
                                  donation,
                                  DeliveryMode.selfPickup,
                                ),
                                onRequestVolunteer: () => _requestDonation(
                                  context,
                                  donation,
                                  DeliveryMode.volunteer,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }

                      // Normal mode (no AI)
                      return Column(
                        children: filteredDonations.map((donation) {
                          final isRequested = donation.status == DonationStatus.requested;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NgoDonationCard(
                              donation: donation,
                              isRequested: isRequested,
                              onSelfPickup: () => _requestDonation(
                                context,
                                donation,
                                DeliveryMode.selfPickup,
                              ),
                              onRequestVolunteer: () => _requestDonation(
                                context,
                                donation,
                                DeliveryMode.volunteer,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
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
          BoxShadow(blurRadius: 18, offset: Offset(0, 8), color: Color(0x14000000)),
        ],
      ),
      child: child,
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({required this.text, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD0893E) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: const [
            BoxShadow(blurRadius: 10, offset: Offset(0, 6), color: Color(0x0F000000)),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : Colors.black.withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}

class _NgoDonationCard extends StatelessWidget {
  const _NgoDonationCard({
    required this.donation,
    required this.isRequested,
    required this.onSelfPickup,
    required this.onRequestVolunteer,
    this.matchPercent,
    this.isTopPick = false,
  });

  final Donation donation;
  final bool isRequested;
  final VoidCallback onSelfPickup;
  final VoidCallback onRequestVolunteer;
  final int? matchPercent;
  final bool isTopPick;

  String get _foodEmoji {
    switch (donation.foodType) {
      case FoodType.bakedGoods:
        return '🥐';
      case FoodType.freshProduce:
        return '🥕';
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
    final hasPhoto = donation.photos != null && donation.photos!.isNotEmpty;
    
    return Container(
      decoration: isTopPick
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  color: const Color(0xFF8B5CF6).withOpacity(0.08),
                ),
              ],
            )
          : null,
      child: _SoftCard(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 100,
                  width: 100,
                  color: const Color(0xFFF2E8D8),
                  child: hasPhoto
                      ? Image.memory(
                          base64Decode(donation.photos![0]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        )
                      : _buildPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      donation.vendorName,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${donation.pickupAddress} • 0.5 km',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCFE9D7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _expiryText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${donation.quantity} ${donation.unit ?? ""}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            text: 'Self Pick-up',
                            bg: isRequested ? Colors.grey : const Color(0xFFD0893E),
                            onTap: isRequested ? () {} : onSelfPickup,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionBtn(
                            text: 'Request Volunteer\nDelivery',
                            bg: isRequested ? Colors.grey : const Color(0xFF4E8CCB),
                            onTap: isRequested ? () {} : onRequestVolunteer,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),

          // "Requested" badge overlay
          if (isRequested)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Requested',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

          // Match % badge (AI Picks mode)
          if (matchPercent != null && !isRequested)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '$matchPercent% match',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF2E8D8),
      child: Center(
        child: Text(
          _foodEmoji,
          style: const TextStyle(fontSize: 38),
        ),
      ),
    );
  }
}

// Helper widget for action buttons
class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.text, required this.bg, required this.onTap});
  final String text;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

// ==========================================
// NOTIFICATION SYSTEM UI COMPONENTS for NGO
// ==========================================

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();

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
          alignment: Alignment.center,
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


