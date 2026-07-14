import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed store for the one-time onboarding completion flag.
///
/// SCOPE: global per device.
/// A single bool is stored under [_key] without any per-user namespace. This
/// means a second account logging in on the same device will NOT re-see the
/// onboarding flow — an accepted tradeoff for simplicity (per CONTEXT §Flag
/// scope). Both "Skip" and finishing the final screen call [markComplete]
/// identically; the flag does not distinguish between the two paths.
///
/// [OnboardingStore] is deliberately unregistered in any provider. Plan 02
/// (AuthGate wiring) threads it into the authenticated branch of AuthGate.
class OnboardingStore {
  static const String _key = 'onboarding_complete_v1';

  /// Returns `true` when the user has already completed (or skipped)
  /// onboarding on this device.
  ///
  /// Returns `false` when the key is absent — i.e. a fresh install or a
  /// device that has never reached the end of onboarding.
  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  /// Persists the completion flag so onboarding is never shown again on this
  /// device.
  ///
  /// Called by both the "Skip" control and the final-screen "Bắt đầu" button
  /// (via the parent's `onDone` callback — this store is not called from
  /// [OnboardingScreen] directly).
  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Removes the completion flag so onboarding will be shown again on the next
  /// launch.
  ///
  /// Provided for development / testing convenience and as an optional
  /// logout hook. Not wired anywhere by default — Plan 02 may call this on
  /// logout if the product decides to reset per-account onboarding.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
