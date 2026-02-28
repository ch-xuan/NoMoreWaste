import 'package:flutter/foundation.dart';
import '../../data/datasources/local/onboarding_local_ds.dart';

/// Controls onboarding state:
/// - current page index
/// - language toggle (EN/BM)
/// - optional persistence (mark onboarding as completed)
class OnboardingController extends ChangeNotifier {
  OnboardingController({required OnboardingLocalDataSource local})
      : _local = local;

  /// Local datasource to store "seen onboarding" (SharedPreferences)
  final OnboardingLocalDataSource _local;

  /// ✅ TURN THIS OFF FOR NOW (as you requested)
  /// When false: onboarding will ALWAYS show (no persistence).
  /// Later in production: set to true so it shows only first time.
  static const bool enableOnboardingPersistence = false;

  /// Tracks which onboarding page user is on (0,1,2)
  int _index = 0;
  int get index => _index;

  /// Language toggle:
  /// false = English (EN)
  /// true  = Bahasa Melayu (BM)
  bool _isBM = false;
  bool get isBM => _isBM;

  /// Number of onboarding pages (fixed = 3)
  static const int pageCount = 3;

  /// Determines if user is on last page (page index 2)
  bool get isLastPage => _index == pageCount - 1;

  /// Called whenever PageView changes pages (swipe)
  void setIndex(int value) {
    if (_index == value) return;
    _index = value;
    notifyListeners(); // ✅ this triggers UI updates for buttons & dots
  }

  /// Toggle language EN <-> BM
  void toggleLanguage(bool value) {
    if (_isBM == value) return;
    _isBM = value;
    notifyListeners(); // ✅ this triggers text updates immediately
  }

  /// Called when user finishes onboarding
  Future<void> markCompleteIfEnabled() async {
    // ✅ For now: DO NOTHING (always show onboarding)
    if (!enableOnboardingPersistence) return;

    // ✅ Production mode: store flag
    await _local.setSeenOnboarding();
  }

  /// Helper getter for translated text
  String t({required String en, required String bm}) => _isBM ? bm : en;
}
