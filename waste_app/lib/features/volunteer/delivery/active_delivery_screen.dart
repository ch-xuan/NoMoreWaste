import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../data/models/delivery_task.dart';
import '../../../../data/models/donation.dart';
import '../../../../data/repositories/task_repository.dart';
import '../../../../data/repositories/donation_repository.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key, required this.task});

  final DeliveryTask task;

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  late DeliveryTask _task;
  final _taskRepo = TaskRepository();
  final _donationRepo = DonationRepository();
  bool _isLoading = false;
  
  // Local state for the "Scan -> Complete" flow at dropoff
  bool _isDropoffScanned = false; 

  Donation? _donation;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _fetchDonationDetails();
  }

  Future<void> _fetchDonationDetails() async {
    try {
      final donation = await _donationRepo.getDonation(_task.donationId);
      if (mounted) {
        setState(() {
          _donation = donation;
        });
      }
    } catch (e) {
      print('Error fetching donation details: $e');
    }
  }

  Future<void> _handleScanPickup() async {
    // Simulated Camera/Photo for Pickup
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Capture Pickup Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              const Text('Take a photo of the package to confirm pickup.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity, height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.grey, size: 50),
                    SizedBox(height: 8),
                    Text('Tap to Capture', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B7F5A),
                      ),
                      child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _taskRepo.markAsPickedUp(_task.id);
      final updated = await _taskRepo.getTask(_task.id);
      if (updated != null) {
        setState(() => _task = updated);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pickup Confirmed! Proceed to drop-off.')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleScanDropoff() async {
    // Simulated Camera/Photo for Dropoff
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Capture Dropoff Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              const Text('Take a photo of the delivered package.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity, height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.camera_alt, color: Colors.grey, size: 50),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD0893E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simulate Capture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      // Change state to show "Complete Delivery" button
      setState(() => _isDropoffScanned = true);
    }
  }

  Future<void> _handleCompleteDelivery() async {
    setState(() => _isLoading = true);
    try {
      await _taskRepo.completeTask(_task.id);
      setState(() {
        _task = _task.copyWith(status: TaskStatus.completed);
        _isDropoffScanned = false; // Reset local state
      });
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Delivery Completed!'),
            content: const Text('Great job! You have successfully delivered the donation and earned 50 points.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop(); // Back to dashboard
                  }
                },
                child: const Text('Awesome'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCancel() async {
    // If picked up, cannot cancel
    if (_task.status != TaskStatus.accepted && _task.status != TaskStatus.open) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot cancel active delivery. Please complete the task.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Delivery?'),
        content: const Text('Are you sure you want to cancel? This will release the task for other volunteers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _taskRepo.releaseTask(_task.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

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

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  String _getTimeWindowText() {
    if (_donation != null && _donation!.pickupWindowStart != null && _donation!.pickupWindowEnd != null) {
      return '${_formatTime(_donation!.pickupWindowStart)} - ${_formatTime(_donation!.pickupWindowEnd)}';
    }
    return '${_task.pickupWindowStart ?? "10:00 AM"} - ${_task.pickupWindowEnd ?? "5:00 PM"}';
  }

  String _getQuantityText() {
    final qty = _donation?.quantity ?? _task.quantity;
    final unit = _donation?.unit ?? _task.unit ?? 'units';
    return '$qty $unit';
  }

  @override
  Widget build(BuildContext context) {
    // Status helpers
    final isAccepted = _task.status == TaskStatus.accepted;
    final isPickedUp = _task.status == TaskStatus.pickedUp;
    final isCompleted = _task.status == TaskStatus.completed || _task.status == TaskStatus.delivered;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Active Delivery', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFD0893E)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Card 
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top Row: Delivery ID + Reward Points
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Delivery #${_task.id.substring(0, 4).toUpperCase()}', 
                             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Roboto')), // Larger, bolder
                          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text('50 pts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2196F3))),
                              Text('Reward', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      // Bottom Row: Time Window + Est. Distance (Side by Side)
                      Row(
                        children: [
                          // Time Window
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                                  child: const Icon(Icons.access_time_filled, color: Color(0xFF2196F3), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Time Window', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(_getTimeWindowText(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Est. Distance
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                                  child: const Icon(Icons.location_on, color: Color(0xFF2196F3), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Est. Distance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const Text('5 km', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text('Route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                
                // 2. Vertical Route Stepper (With Buttons Inside)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Pickup Node
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle),
                                child: Icon(Icons.store, color: (isPickedUp || isCompleted) ? Colors.grey : const Color(0xFF1B7F5A)),
                              ),
                              Container(
                                width: 2,
                                height: 100, // Taller to accommodate larger button space
                                color: const Color(0xFFE0E0E0),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('PICKUP', style: TextStyle(color: Color(0xFF1B7F5A), fontWeight: FontWeight.bold, fontSize: 12)),
                                        if (isPickedUp || isCompleted) 
                                          const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check_circle, size: 16, color: Color(0xFF1B7F5A))),
                                      ],
                                    ),
                                    // Navigation Icon (Restored)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                                      child: const Icon(Icons.navigation, color: Colors.blue, size: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(_task.pickupName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                Text(_task.pickupAddress, style: const TextStyle(color: Colors.grey)),
                                
                                const SizedBox(height: 12),
                                // Pickup Button Logic
                                if (!isPickedUp && !isCompleted && isAccepted)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: ElevatedButton.icon(
                                      onPressed: _handleScanPickup,
                                      icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                      label: const Text('Confirm Pickup (Photo)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF43A047), // Lighter Green
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Taller
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  )
                                else if (isPickedUp || isCompleted)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: ElevatedButton.icon(
                                      onPressed: null, // Disabled look
                                      icon: const Icon(Icons.check_circle, size: 20, color: Colors.white),
                                      label: const Text('Complete Pickup', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                      style: ElevatedButton.styleFrom(
                                        disabledBackgroundColor: const Color(0xFF1565C0), // Blue (Matching Complete Delivery)
                                        disabledForegroundColor: Colors.white, // Ensure text/icon is white
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Taller
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Dropoff Node
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(color: const Color(0xFFFFEBEE), shape: BoxShape.circle),
                             child: Icon(Icons.location_on, color: isCompleted ? Colors.grey : const Color(0xFFE53935)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('DROP-OFF', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 12)),
                                    // Phone Icon (Restored)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                      child: const Icon(Icons.call, color: Colors.grey, size: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(_task.dropoffName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                Text(_task.dropoffAddress, style: const TextStyle(color: Colors.grey)),
                                
                                // Dropoff Button (Orange or Blue)
                                if (isPickedUp && !isCompleted) ...[
                                  const SizedBox(height: 12),
                                  if (!_isDropoffScanned)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton.icon(
                                        onPressed: _handleScanDropoff,
                                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                        label: const Text('Confirm Dropoff (Photo)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFEF6C00), // Orange
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Taller
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    )
                                  else
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: ElevatedButton.icon(
                                        onPressed: _handleCompleteDelivery,
                                        icon: const Icon(Icons.check_circle, size: 20, color: Colors.white),
                                        label: const Text('Complete Delivery', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1565C0), // Blue for finish
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Taller
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                ],
                                
                                if (isCompleted) ...[
                                   const SizedBox(height: 8),
                                   const Text('Delivery Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ],

                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: Color(0xFFFBC02D), size: 20),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Please leave the package at the door',
                                          style: TextStyle(color: Color(0xFFF57F17), fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text('Food Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),

                 
                 // Food Details (Matching Route Style)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, // White background
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                       Container(
                         width: 60, height: 60,
                         decoration: BoxDecoration(
                           color: Colors.grey.shade100,
                           borderRadius: BorderRadius.circular(12),
                           image: _task.imageUrl != null 
                             ? DecorationImage(image: _getImageProvider(_task.imageUrl!)!, fit: BoxFit.cover)
                             : null,
                         ),
                         child: _getImageProvider(_task.imageUrl) == null 
                           ? const Icon(Icons.restaurant_menu, color: Colors.grey, size: 30)
                           : null,
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               _task.donationTitle,
                               style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               'Quantity: ${_getQuantityText()}',
                               style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                             ),
                           ],
                         ),
                       ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Bottom Action (Cancel or Back)
                if (isCompleted)
                   SizedBox(
                     height: 56,
                     child: ElevatedButton(
                       onPressed: () => Navigator.pop(context),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.grey,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       ),
                       child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                     ),
                   )
                else
                   Center(
                     child: TextButton(
                       onPressed: (isPickedUp && !isCompleted) ? null : _handleCancel,
                       child: Text(
                         (isPickedUp && !isCompleted) ? 'Please complete delivery' : 'Cancel Delivery', 
                         style: TextStyle(color: (isPickedUp && !isCompleted) ? Colors.grey : Colors.red)
                       ),
                     ),
                   ),
                 
                 // Show disabled message if user tries to cancel
                 if (isPickedUp && !isCompleted)
                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 8),
                     child: Text(
                       'Delivery is in progress and cannot be cancelled.',
                       textAlign: TextAlign.center,
                       style: TextStyle(color: Colors.grey, fontSize: 12),
                     ),
                   ),
                   
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
