import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../data/models/user_role.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({
    super.key, 
    required this.role,
    this.onBackToDashboard,
  });
  
  final UserRole role;
  final VoidCallback? onBackToDashboard;

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MobileScannerController? _cameraController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        // Scanner tab - initialize camera
        _cameraController ??= MobileScannerController();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

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

  String get _myQRData {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final roleKey = widget.role.key;
    
    // Format: role:userId:context
    switch (widget.role) {
      case UserRole.donor:
        return 'donor:$userId:pickup';
      case UserRole.ngo:
        return 'ngo:$userId:dropoff';
      case UserRole.volunteer:
        return 'volunteer:$userId:rating';
    }
  }

  String get _qrCodeTitle {
    switch (widget.role) {
      case UserRole.donor:
        return 'My Pickup QR Code';
      case UserRole.ngo:
        return 'My Dropoff QR Code';
      case UserRole.volunteer:
        return 'My Rating QR Code';
    }
  }

  String get _qrCodeDescription {
    switch (widget.role) {
      case UserRole.donor:
        return 'Show this QR code to NGO or Volunteer for food pickup verification';
      case UserRole.ngo:
        return 'Show this QR code to Volunteer for food dropoff verification';
      case UserRole.volunteer:
        return 'Share this QR code to receive ratings from Donors and NGOs';
    }
  }

  void _handleQRDetected(BarcodeCapture barcodes) async {
    if (_isProcessing) return;
    
    final barcode = barcodes.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);
    
    final qrData = barcode!.rawValue!;
    
    // Parse QR data: role:userId:context
    final parts = qrData.split(':');
    if (parts.length != 3) {
      _showError('Invalid QR Code format');
      setState(() => _isProcessing = false);
      return;
    }

    final scannedRole = parts[0];
    final scannedUserId = parts[1];
    final context = parts[2];

    // Role-based validation
    bool isValid = false;
    String message = '';

    switch (widget.role) {
      case UserRole.ngo:
        // NGO can scan Donor QR for pickup
        if (scannedRole == 'donor' && context == 'pickup') {
          isValid = true;
          message = 'Donor pickup verified!';
        }
        // NGO can scan Volunteer QR for rating
        else if (scannedRole == 'volunteer' && context == 'rating') {
          isValid = true;
          await _showRatingDialog(scannedUserId);
          setState(() => _isProcessing = false);
          return;
        }
        break;
        
      case UserRole.volunteer:
        // Volunteer can scan Donor QR for pickup
        if (scannedRole == 'donor' && context == 'pickup') {
          isValid = true;
          message = 'Donor pickup verified!';
        }
        // Volunteer can scan NGO QR for dropoff
        else if (scannedRole == 'ngo' && context == 'dropoff') {
          isValid = true;
          message = 'NGO dropoff verified!';
        }
        break;
        
      case UserRole.donor:
        // Donor can scan Volunteer QR for rating
        if (scannedRole == 'volunteer' && context == 'rating') {
          isValid = true;
          await _showRatingDialog(scannedUserId);
          setState(() => _isProcessing = false);
          return;
        }
        break;
    }

    if (isValid) {
      _showSuccess(message);
    } else {
      _showError('Cannot scan this QR code with your role');
    }
    
    setState(() => _isProcessing = false);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showRatingDialog(String volunteerId) async {
    int rating = 0;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Color(0xFF2196F3).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.star, color: Color(0xFF2196F3), size: 36),
                ),
                SizedBox(height: 20),
                Text(
                  'Rate Volunteer',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A2C23),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'How was your experience?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => rating = index + 1);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          rating > index ? Icons.star : Icons.star_border,
                          color: Color(0xFFFFC107), // Golden
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: rating > 0 ? () {
                      // TODO: Save rating to Firestore
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Thank you for rating $rating stars!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Submit Rating',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBackToDashboard != null) {
              widget.onBackToDashboard!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text('QR Code'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3A2C23),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _themeColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _themeColor,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2), text: 'My QR Code'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyQRTab(),
          _buildScannerTab(),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    _cameraController ??= MobileScannerController();
    
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _cameraController!,
            onDetect: _handleQRDetected,
          ),
          
          // Overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          
          // Scanning Frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _themeColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          // Controls & Instructions
          SafeArea(
            child: Column(
              children: [
                // Camera controls
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          _cameraController?.torchEnabled == true ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => _cameraController?.toggleTorch(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                        onPressed: () => _cameraController?.switchCamera(),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Instructions
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner, color: _themeColor, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _getScannerTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A2C23),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getScannerDescription(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      // Simulation Button (Only for testing/demo)
                      if (widget.role != UserRole.volunteer) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            // Simulate scanning a volunteer rating QR code
                            _handleQRDetected(
                              BarcodeCapture(
                                barcodes: [
                                  Barcode(
                                    rawValue: 'volunteer:simulated_volunteer_123:rating',
                                    format: BarcodeFormat.qrCode,
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.star_rate_rounded, color: Colors.amber),
                          label: const Text('Simulate Volunteer Scan'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyQRTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            _qrCodeTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3A2C23),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _qrCodeDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // QR Code Container
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _themeColor, width: 3),
                  ),
                  child: QrImageView(
                    data: _myQRData,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                ),
                const SizedBox(height: 20),
                
                // User Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, color: _themeColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.role.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _themeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: const Color(0xFF1976D2), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.role == UserRole.volunteer
                        ? 'Others can scan your QR to rate your service!'
                        : 'Keep this QR code ready for quick verification',
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getScannerTitle() {
    switch (widget.role) {
      case UserRole.volunteer:
        return 'Scan Pickup or Dropoff QR';
      case UserRole.ngo:
        return 'Scan Donor Pickup QR';
      case UserRole.donor:
        return 'Scan Volunteer Rating QR';
    }
  }

  String _getScannerDescription() {
    switch (widget.role) {
      case UserRole.volunteer:
        return 'Scan Donor QR for pickup, NGO QR for dropoff';
      case UserRole.ngo:
        return 'Scan Donor QR to verify pickup, or Volunteer QR to rate';
      case UserRole.donor:
        return 'Scan Volunteer QR to give them a rating';
    }
  }
}
