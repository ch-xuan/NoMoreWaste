import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/user_role.dart';
import '../vendor/dashboard/vendor_dashboard_screen.dart';
import '../ngo/dashboard/ngo_dashboard_screen.dart';
import '../volunteer/dashboard/volunteer_dashboard_screen.dart';
import '../../features/history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../qr_scan/qr_scan_screen.dart';
import '../chat/chat_threads_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.role,
    required this.displayNameOrOrg,
  });

  final UserRole role;
  final String displayNameOrOrg;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Widget _dashboard() {
    switch (widget.role) {
      case UserRole.donor:
        return VendorDashboardScreen(companyName: widget.displayNameOrOrg);
      case UserRole.ngo:
        return NgoDashboardScreen(ngoName: widget.displayNameOrOrg);
      case UserRole.volunteer:
        return VolunteerDashboardScreen(volunteerName: widget.displayNameOrOrg);
    }
  }

  List<Widget> get _tabs => [
        _dashboard(),
        ChatThreadsScreen(role: widget.role),
        QRScanScreen(role: widget.role),
        HistoryScreen(role: widget.role),
        ProfileScreen(role: widget.role, displayName: widget.displayNameOrOrg),
      ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() => _index = 0);
      },
      child: Scaffold(
        body: _index == 2 // QR Screen index
            ? QRScanScreen(
                role: widget.role,
                onBackToDashboard: () => setState(() => _index = 0),
              )
            : _tabs[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFB57A3E),
          unselectedItemColor: Colors.black.withOpacity(0.35),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'QR Scan'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
