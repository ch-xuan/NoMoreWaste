import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/user_role.dart';
import '../home/home_shell.dart';

class PostLoginRouter extends StatelessWidget {
  const PostLoginRouter({super.key});

  Future<Map<String, dynamic>> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not logged in. Please login again.');
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) {
      throw Exception('User profile not found in Firestore.');
    }
    return data;
  }

  UserRole _roleFromKey(String? key) {
    switch (key) {
      case 'donor':
        return UserRole.donor;
      case 'ngo':
        return UserRole.ngo;
      case 'volunteer':
        return UserRole.volunteer;
      default:
        return UserRole.volunteer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadProfile(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Routing error:\n${snap.error}'),
              ),
            ),
          );
        }

        final data = snap.data!;
        final role = _roleFromKey(data['role'] as String?);
        final verificationStatus = data['verificationStatus'] as String? ?? 'pending';

        final name = (role == UserRole.volunteer)
            ? ((data['displayName'] ?? '') as String).trim()
            : ((data['orgName'] ?? '') as String).trim();

        return HomeShell(
          role: role,
          displayNameOrOrg: name.isEmpty ? 'Name' : name,
        );
      },
    );
  }
}
