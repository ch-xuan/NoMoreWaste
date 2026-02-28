import 'package:flutter/material.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/auth_shell_screen.dart';
import 'splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _controller = SplashController();

  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    // Let the logo breathe a little (nice UX)
    await Future.delayed(const Duration(milliseconds: 1000));

    final next = await _controller.determineNext();

    if (!mounted) return;

    switch (next) {
      case SplashNext.onboarding:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OnboardingScreen(
              onFinished: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthShellScreen()),
                );
              },
            ),
          ),
        );
        break;

      case SplashNext.roleSelect:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthShellScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9FAEA), // soft white
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/branding/logo_nmw.png',
            width: 500,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
