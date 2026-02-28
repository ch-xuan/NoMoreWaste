// lib/features/onboarding/onboarding_screen.dart
//
// ✅ Full updated onboarding screen:
// - Dynamic dots (updates on swipe)
// - Dynamic footer:
//    • Page 1/2 → Skip + Next
//    • Page 3   → ONE big centered Get Started button
// - EN/BM toggle (custom pill toggle like your screenshot)
// - Buttons also switch language (Skip/Next/Get Started)
// - Persistence is controlled in OnboardingController (enableOnboardingPersistence flag)
// - Layout is overflow-safe across Android/Windows/Web using Expanded PageView + responsive OnboardingPage

import 'package:flutter/material.dart';

// ✅ Local persistence (SharedPreferences wrapper + local DS)
import '../../core/local/prefs.dart';
import '../../data/datasources/local/onboarding_local_ds.dart';

// ✅ Controller + widgets
import 'onboarding_controller.dart';
import 'widgets/onboarding_dots.dart';
import 'widgets/onboarding_footer.dart';
import 'widgets/onboarding_page.dart';

// ✅ Next screen after onboarding
import '../auth/auth_shell_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required Null Function() onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // ✅ Controls swiping between onboarding pages
  late final PageController _pageController;

  // ✅ Controller is async-initialized because it needs SharedPreferences
  OnboardingController? _controller;

  @override
  void initState() {
    super.initState();

    // ✅ Create PageController
    _pageController = PageController();

    // ✅ Initialize controller (needs async SharedPreferences)
    _initController();
  }

  Future<void> _initController() async {
    // ✅ Create prefs instance (SharedPreferences wrapper)
    final prefs = await Prefs.create();

    // ✅ Local DS to store onboarding flags (seen_onboarding)
    final local = OnboardingLocalDataSource(prefs);

    // ✅ Create controller and trigger rebuild
    setState(() {
      _controller = OnboardingController(local: local);
    });
  }

  @override
  void dispose() {
    // ✅ Clean up controllers
    _pageController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  /// ✅ Finishes onboarding:
  /// - Persists completion only if enabled (controller flag)
  /// - Navigates to Role Select
  Future<void> _finish() async {
    final c = _controller!;

    // ✅ Save seen flag only if persistence is enabled
    await c.markCompleteIfEnabled();

    if (!mounted) return;

    // ✅ Move to Role Select screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthShellScreen()),
    );
  }

  /// ✅ Next button behavior:
  /// - If last page → Get Started → finish
  /// - Else → go to next onboarding page
  Future<void> _onNextPressed() async {
    final c = _controller!;

    if (c.isLastPage) {
      await _finish();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ While controller is initializing
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final c = _controller!;

    // ✅ AnimatedBuilder rebuilds whenever controller changes:
    // - page index
    // - language toggle
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        // ✅ Localized page content
        final pages = [
          OnboardingPage(
            imagePath: 'assets/illustrations/onboarding_sandwich.png',
            title: c.t(
              en: 'Rescue Surplus Food',
              bm: 'Selamatkan Makanan Lebihan',
            ),
            subtitle: c.t(
              en: 'Find delicious food from local partners at a great value.',
              bm: 'Dapatkan makanan sedap daripada rakan tempatan pada harga berpatutan.',
            ),
          ),
          OnboardingPage(
            imagePath: 'assets/illustrations/onboarding_earth.png',
            title: c.t(
              en: 'Reduce Food Waste',
              bm: 'Kurangkan Pembaziran Makanan',
            ),
            subtitle: c.t(
              en: 'Every meal rescued helps the planet. Be a food hero!',
              bm: 'Setiap makanan yang diselamatkan membantu bumi. Jadilah wira makanan!',
            ),
          ),
          OnboardingPage(
            imagePath: 'assets/illustrations/onboarding_community.png',
            title: c.t(
              en: 'Join Our Community',
              bm: 'Sertai Komuniti Kami',
            ),
            subtitle: c.t(
              en: "Ready to make a difference?\nLet's get you started.",
              bm: 'Bersedia untuk membawa perubahan?\nMari mulakan sekarang.',
            ),
          ),
        ];

        return Scaffold(
          body: Container(
            // ✅ Background gradient like your screenshots
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8ED1C1),
                  Color(0xFFCDEDE6),
                ],
              ),
            ),
            child: SafeArea(
              // ✅ LayoutBuilder helps with correct sizing & avoids overflows
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      // ─────────────────────────────
                      // Top-right EN/BM toggle (custom pill)
                      // ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _LanguageToggle(
                            isBM: c.isBM,
                            onChanged: c.toggleLanguage,
                          ),
                        ),
                      ),

                      // ─────────────────────────────
                      // PageView MUST be Expanded so footer doesn't overflow
                      // ─────────────────────────────
                      Expanded(
                        child: PageView(
                          controller: _pageController,

                          // ✅ Updates dots + button state dynamically
                          onPageChanged: c.setIndex,

                          children: pages,
                        ),
                      ),

                      // ─────────────────────────────
                      // Dots (dynamic)
                      // ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: OnboardingDots(
                          count: pages.length,
                          activeIndex: c.index,
                        ),
                      ),

                      // ─────────────────────────────
                      // Footer (dynamic + localized)
                      // Page 1/2 → Skip + Next
                      // Page 3   → one centered Get Started
                      // ─────────────────────────────
                      OnboardingFooter(
                        isLast: c.isLastPage,
                        onSkip: _finish,
                        onNext: _onNextPressed,
                        skipText: c.t(en: 'Skip', bm: 'Langkau'),
                        nextText: c.t(en: 'Next', bm: 'Seterusnya'),
                        getStartedText: c.t(en: 'Get Started', bm: 'Mulakan'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ✅ EN/BM Toggle matching your screenshot:
/// EN  [pill toggle with round knob + shadow]  BM
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.isBM,
    required this.onChanged,
  });

  final bool isBM;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangLabel(text: 'EN', isActive: !isBM),
        const SizedBox(width: 10),

        GestureDetector(
          onTap: () => onChanged(!isBM),
          child: _TogglePill(isOn: isBM),
        ),

        const SizedBox(width: 10),
        _LangLabel(text: 'BM', isActive: isBM),
      ],
    );
  }
}

class _LangLabel extends StatelessWidget {
  const _LangLabel({
    required this.text,
    required this.isActive,
  });

  final String text;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black.withOpacity(isActive ? 0.75 : 0.55),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({required this.isOn});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    // Tuned to resemble your design
    const double width = 56;
    const double height = 28;
    const double knob = 22;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: width,
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18), // subtle dark track
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: knob,
              height: knob,
              decoration: BoxDecoration(
                color: const Color(0xFFF7EEDB), // warm off-white knob
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 12,
                    offset: Offset(0, 6),
                    color: Color(0x33000000),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
