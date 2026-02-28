import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/user_repository.dart';
import 'post_login_router.dart';
import 'unified_auth_screen.dart';

class AuthShellScreen extends StatefulWidget {
  const AuthShellScreen({super.key});

  @override
  State<AuthShellScreen> createState() => _AuthShellScreenState();
}

class _AuthShellScreenState extends State<AuthShellScreen> {
  final _auth = AuthService();
  final _users = UserRepository();

  Future<void> _goDashboard() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PostLoginRouter()),
    );
  }

  /// ✅ Login: Auto-detects role in PostLoginRouter
  Future<void> _login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmail(email: email, password: password);
    final uid = cred.user!.uid;

    final profile = await _users.getUserProfile(uid);
    if (profile == null) {
      await _auth.signOut();
      throw Exception('Account profile not found. Please sign up again.');
    }

    await _goDashboard();
  }

  /// ✅ Signup: create Firebase Auth user + Firestore profile with selected role
  Future<void> _signup({
    required String fullNameOrOrg,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? verificationDocBase64,
    String? verificationDocFilename,
    int? verificationDocSize,
  }) async {
    final cred = await _auth.signUpWithEmail(email: email, password: password);
    final uid = cred.user!.uid;

    // Create user profile (includes verification doc)
    await _users.createUserProfile(
      uid: uid,
      email: email,
      role: role,
      phone: phone,
      orgName: role == UserRole.volunteer ? null : fullNameOrOrg,
      displayName: role == UserRole.volunteer ? fullNameOrOrg : null,
      verificationDocBase64: verificationDocBase64,
    );

    // Navigate to dashboard automatically via post-login router
    await _goDashboard();
  }

  /// ✅ Google login
  Future<void> _googleLogin() async {
    final cred = await _auth.signInWithGoogle();
    final user = cred.user!;
    final uid = user.uid;
    final email = user.email ?? '';

    final profile = await _users.getUserProfile(uid);

    // First-time Google login -> we don't know the role yet!
    if (profile == null) {
      // NOTE: For Google sign-up, we currently don't collect docs/role upfront.
      // We will set them as volunteer by default for now, or require a separate flow later.
      // For this revamp, let's create a generic "pending" profile or default to volunteer.
      await _users.createUserProfile(
        uid: uid,
        email: email,
        role: UserRole.volunteer, // Default fallback
        displayName: user.displayName ?? '',
        orgName: null,
        phone: '',
      );
    }

    await _goDashboard();
  }

  Future<void> _forgotPassword(String email) async {
    await _auth.sendPasswordResetEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedAuthScreen(
      onForgotPassword: _forgotPassword,
      onGoogleLogin: _googleLogin,
      onLogin: ({required email, required password}) async {
        await _login(email: email, password: password);
      },
      onSignUp: ({
        required fullNameOrOrg,
        required email,
        required password,
        required phone,
        required role,
        verificationDocBase64,
        verificationDocFilename,
        verificationDocSize,
      }) async {
        await _signup(
          fullNameOrOrg: fullNameOrOrg,
          email: email,
          password: password,
          phone: phone,
          role: role,
          verificationDocBase64: verificationDocBase64,
          verificationDocFilename: verificationDocFilename,
          verificationDocSize: verificationDocSize,
        );
      },
    );
  }
}
