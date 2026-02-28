import '../../../core/local/prefs.dart';

class OnboardingLocalDataSource {
  OnboardingLocalDataSource(this._prefs);

  final Prefs _prefs;

  static const String _kSeenOnboarding = 'seen_onboarding';

  bool hasSeenOnboarding() {
    return _prefs.getBool(_kSeenOnboarding, defaultValue: false);
  }

  Future<void> setSeenOnboarding() async {
    await _prefs.setBool(_kSeenOnboarding, true);
  }
}
