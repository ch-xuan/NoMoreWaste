import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../data/models/user_role.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/donation_repository.dart';
import '../../data/repositories/request_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../auth/auth_shell_screen.dart';
import 'personal_information_screen.dart';
import 'privacy_data_screen.dart';
import 'widgets/appearance_dialog.dart';
import 'widgets/contact_support_sheet.dart';
import 'widgets/notification_settings_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.role, required this.displayName});

  final UserRole role;
  final String displayName;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepo = UserRepository();
  final _imagePicker = ImagePicker();
  String? _profilePhotoBase64;
  bool _isLoadingPhoto = false;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _displayName = widget.displayName;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final userData = await _userRepo.getUserProfile(userId);
      if (userData != null && mounted) {
        setState(() {
          _profilePhotoBase64 = userData['profilePhotoBase64'];
          _displayName = userData['displayName'] ?? widget.displayName;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() => _isLoadingPhoto = true);
        
        final bytes = await image.readAsBytes(); // Use XFile's readAsBytes instead of File
        final base64Image = base64Encode(bytes);
        
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await _userRepo.updateUserProfile(
            uid: userId,
            profilePhotoBase64: base64Image,
          );
          
          if (mounted) {
            setState(() {
              _profilePhotoBase64 = base64Image;
              _isLoadingPhoto = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated')),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating picture: $e')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'No email';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "My Profile" Title
                const Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A2C23),
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Card (Photo, Name, Role, UID)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                      // Profile Photo
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _themeColor.withOpacity(0.1),
                                border: Border.all(color: _themeColor, width: 3),
                                image: _profilePhotoBase64 != null
                                    ? DecorationImage(
                                        image: MemoryImage(base64Decode(_profilePhotoBase64!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _isLoadingPhoto
                                  ? const CircularProgressIndicator()
                                  : (_profilePhotoBase64 == null
                                      ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: _themeColor,
                                        )
                                      : null),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _themeColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Name
                      Text(
                        _displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A2C23),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: _themeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getRoleLabel(widget.role),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // UID
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fingerprint, size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'UID: ${userId.substring(0, 8)}...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Mini Dashboard Stats
                if (userId.isNotEmpty)
                  FutureBuilder<Map<String, dynamic>>(
                    future: _getStats(userId),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? {'primary': 0, 'secondary': 0, 'tertiary': 0.0};
                      return Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              _getPrimaryStatLabel(widget.role),
                              '${stats['primary']}',
                              _getPrimaryStatIcon(widget.role),
                            ),
                            Container(width: 1, height: 50, color: Colors.grey.shade200),
                            _buildStatItem(
                              _getSecondaryStatLabel(widget.role),
                              '${stats['secondary']}',
                              _getSecondaryStatIcon(widget.role),
                            ),
                            Container(width: 1, height: 50, color: Colors.grey.shade200),
                            _buildStatItem(
                              _getTertiaryStatLabel(widget.role),
                              stats['tertiary'] is double 
                                ? stats['tertiary'].toStringAsFixed(1)
                                : '${stats['tertiary']}',
                              _getTertiaryStatIcon(widget.role),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // General Settings Header
                const Text(
                  'General Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A2C23),
                  ),
                ),
                const SizedBox(height: 16),

                // Settings Menu Items
                _buildSettingsItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  subtitle: 'Phone, Email, Addresses, Documents',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonalInformationScreen(themeColor: _themeColor),
                      ),
                    );
                    // Reload user data when returning from Personal Information screen
                    _loadUserData();
                  },
                ),
                const SizedBox(height: 12),
                
                _buildSettingsItem(
                  context,
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Theme and Display Settings',
                  onTap: () {
                    showAppearanceDialog(context, _themeColor);
                  },
                ),
                const SizedBox(height: 12),
                
                _buildSettingsItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notification',
                  subtitle: 'Reminders and Check-in Alerts',
                  onTap: () {
                    showNotificationSettings(context, _themeColor);
                  },
                ),
                const SizedBox(height: 12),
                
                _buildSettingsItem(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Privacy & Data',
                  subtitle: 'Your information stays private',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivacyDataScreen(themeColor: _themeColor),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                _buildSettingsItem(
                  context,
                  icon: Icons.support_agent,
                  title: 'Contact Support',
                  subtitle: 'Get Assistance & Support',
                  onTap: () {
                    showContactSupportSheet(context, _themeColor);
                  },
                ),
                const SizedBox(height: 12),
                
                _buildSettingsItem(
                  context,
                  icon: Icons.system_update_outlined,
                  title: 'Check for Updates',
                  subtitle: 'Restarts the app',
                  onTap: () {
                    _showUpdateDialog(context);
                  },
                ),

                const SizedBox(height: 32),

                // Logout Button (Borderless)
                InkWell(
                  onTap: () => _showLogoutDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.grey.shade700, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // App Version
                Center(
                  child: Text(
                    'NoMoreWaste v.1.0.0 (Android)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _themeColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3A2C23),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _themeColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3A2C23),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItemWithToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _themeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _themeColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A2C23),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _themeColor,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9800), // Orange
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A2C23),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'No',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const AuthShellScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BC34A), // Light green
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Yes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _themeColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Do you want to restart the app?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A2C23),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will check for updates and restart the application.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'No',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          // Close dialog
                          Navigator.pop(context);
                          // Restart app by navigating to auth shell screen
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthShellScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _themeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Yes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getStats(String userId) async {
    try {
      switch (widget.role) {
        case UserRole.volunteer:
          final taskRepo = TaskRepository();
          final stats = await taskRepo.getVolunteerStats(userId);
          return {
            'primary': stats['deliveriesCompleted'] ?? 0,
            'secondary': stats['hoursVolunteered'] ?? 0,
            'tertiary': 0.0, // Rating - TODO: implement
          };
        case UserRole.ngo:
          final requestRepo = RequestRepository();
          final stats = await requestRepo.getNgoRequestStats(userId);
          return {
            'primary': stats['requests'] ?? 0,
            'secondary': stats['received'] ?? 0,
            'tertiary': stats['pending'] ?? 0,
          };
        case UserRole.donor:
          final donationRepo = DonationRepository();
          final stats = await donationRepo.getDonationStats(userId);
          return {
            'primary': stats['totalDonations'] ?? 0,
            'secondary': stats['totalMeals'] ?? 0,
            'tertiary': stats['totalCO2'] ?? 0.0,
          };
      }
    } catch (e) {
      return {'primary': 0, 'secondary': 0, 'tertiary': 0.0};
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.volunteer:
        return 'Volunteer';
      case UserRole.ngo:
        return 'NGO';
      case UserRole.donor:
        return 'Donor';
    }
  }

  String _getPrimaryStatLabel(UserRole role) {
    switch (role) {
      case UserRole.volunteer:
        return 'Deliveries';
      case UserRole.ngo:
        return 'Requests';
      case UserRole.donor:
        return 'Donations';
    }
  }

  IconData _getPrimaryStatIcon(UserRole role) {
    switch (role) {
      case UserRole.volunteer:
        return Icons.local_shipping;
      case UserRole.ngo:
        return Icons.inbox;
      case UserRole.donor:
        return Icons.volunteer_activism;
    }
  }

  String _getSecondaryStatLabel(UserRole role) {
    switch (role) {
      case UserRole.volunteer:
        return 'Hours';
      case UserRole.ngo:
        return 'Received';
      case UserRole.donor:
        return 'Meals';
    }
  }

  IconData _getSecondaryStatIcon(UserRole role) {
    switch (role) {
      case UserRole.volunteer:
        return Icons.schedule;
      case UserRole.ngo:
        return Icons.check_circle;
      case UserRole.donor:
        return Icons.restaurant;
    }
  }

  String _getTertiaryStatLabel(UserRole role) {
    switch (role) {
      case UserRole.volunteer:
        return 'Rating';
      case UserRole.ngo:
        return 'Pending';
      case UserRole.donor:
        return 'CO2 (kg)';
    }
  }

  IconData _getTertiaryStatIcon(UserRole role) {
    switch (role) {
      case UserRole.volunteer:
        return Icons.star;
      case UserRole.ngo:
        return Icons.hourglass_empty;
      case UserRole.donor:
        return Icons.eco;
    }
  }
}
