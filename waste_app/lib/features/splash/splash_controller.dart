import '../../core/local/prefs.dart';
import '../../data/datasources/local/onboarding_local_ds.dart';
import '../onboarding/onboarding_controller.dart';

enum SplashNext { onboarding, roleSelect }

class SplashController {
  Future<SplashNext> determineNext() async {
    // ✅ Dev mode: always show onboarding
    if (!OnboardingController.enableOnboardingPersistence) {
      return SplashNext.onboarding;
    }

    // ✅ Prod mode: show onboarding only if not seen
    final prefs = await Prefs.create();
    final local = OnboardingLocalDataSource(prefs);
    final seen = local.hasSeenOnboarding();
    return seen ? SplashNext.roleSelect : SplashNext.onboarding;
  }
}

// class SplashController {
//   Future<SplashNext> determineNext() async {
//     final prefs = await Prefs.create();
//     final local = OnboardingLocalDataSource(prefs);

//     final seen = local.hasSeenOnboarding();
//     return seen ? SplashNext.roleSelect : SplashNext.onboarding;
//   }
// }
