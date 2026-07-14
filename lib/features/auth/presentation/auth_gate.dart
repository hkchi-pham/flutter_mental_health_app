import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/auth_repository.dart';
import '../data/auth_session.dart';
import '../../shared/network/api_client.dart';
import '../../shared/presentation/app_shell.dart';
import '../../onboarding/data/onboarding_store.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'splash_screen.dart';

/// Two-phase gate:
///   [_Phase.restoring] — shown immediately on startup while [AuthRepository.restore]
///                        reads the secure store; displays [SplashScreen].
///   [_Phase.ready]     — restore complete; build switches on
///                        [AuthSession.isAuthenticated] to show login or garden.
enum _Phase { restoring, ready }

/// Top-level routing widget that controls which screen is visible.
///
/// Responsibilities:
///   1. Show [SplashScreen] during the async token restore (cold-launch).
///   2. Switch between [LoginScreen]/[RegisterScreen] and [AppShell] (the
///      4-tab post-login surface) based on [AuthSession.isAuthenticated].
///   3. Wire [ApiClient.onUnauthorized] so any 401 from any API call clears the
///      session and returns the user to the login screen with a one-shot
///      "Session expired — please log in again" inline message.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  _Phase _phase = _Phase.restoring;

  /// Controls which of login / register is visible when unauthenticated.
  bool _showRegister = false;

  /// One-shot flag set by [_handleUnauthorized]; causes the next [LoginScreen]
  /// build to receive the "Session expired" notice via [initialMessage].
  bool _sessionExpired = false;

  /// Thin SharedPreferences wrapper — constructed ad hoc (not in the provider
  /// tree) mirroring how other stores are used in this project.
  final OnboardingStore _onboardingStore = OnboardingStore();

  /// Whether the device has already completed (or skipped) onboarding.
  ///
  /// Defaults to `true` so that a [SharedPreferences] read failure degrades
  /// gracefully to "skip onboarding, show garden" rather than trapping the
  /// user in the onboarding flow on every launch.
  bool _onboardingComplete = true;

  @override
  void initState() {
    super.initState();
    // Defer until the first frame so context.read<T> can safely traverse the
    // provider tree (providers are available after the first build).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Wire the 401 hook before restore so any 401 during restore is caught.
      context.read<ApiClient>().onUnauthorized = _handleUnauthorized;

      // restore() reads TokenStore, populates ApiClient token + AuthSession.
      // After it returns we flip to ready and let context.watch<AuthSession>
      // drive the screen switch.
      await context.read<AuthRepository>().restore();

      // Read the onboarding flag alongside restore so the authenticated branch
      // already knows whether to show OnboardingScreen or go straight to
      // AppShell — no second full-screen flash.
      final complete = await _onboardingStore.isComplete();

      if (!mounted) return;
      setState(() {
        _onboardingComplete = complete;
        _phase = _Phase.ready;
      });
    });
  }

  @override
  void dispose() {
    // Unhook so a stale callback can't fire into a disposed State.
    // Wrapped in try/catch because context may be unavailable in some test
    // teardown paths (mirrors the garden_screen onTreesWilted teardown pattern).
    try {
      context.read<ApiClient>().onUnauthorized = null;
    } catch (_) {}
    super.dispose();
  }

  /// Called by [ApiClient] whenever the backend returns 401.
  ///
  /// Clears the session (which flips [AuthSession.isAuthenticated] → false and
  /// triggers a rebuild routing to login) and sets [_sessionExpired] so the
  /// next [LoginScreen] shows the "Session expired" notice exactly once.
  void _handleUnauthorized() {
    if (!mounted) return;

    // Guard against being called mid-build (e.g. if a listener fires during a
    // widget tree rebuild) by scheduling through addPostFrameCallback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthSession>().clear(); // notifyListeners → gate rebuilds
      setState(() {
        _sessionExpired = true;
        _showRegister = false; // always land on login after a 401
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Phase: restoring ─────────────────────────────────────────────────────
    if (_phase == _Phase.restoring) {
      return const SplashScreen();
    }

    // ── Phase: ready — watch session for live switches ───────────────────────
    final session = context.watch<AuthSession>();

    if (session.isAuthenticated) {
      // Clear transient flags so a subsequent logout + re-login starts fresh.
      _sessionExpired = false;
      _showRegister = false;

      // ── Onboarding gate ─────────────────────────────────────────────────────
      // Show the intro flow exactly once — before the garden — when the device
      // has not yet completed (or skipped) onboarding.  The flag was read
      // during the restore phase so there is no extra async wait here.
      //
      // onDone persists the flag via markComplete() THEN calls setState so the
      // next build falls straight through to AppShell.  Both Skip and Bắt đầu
      // on OnboardingScreen call onDone — so skipping also persists the flag
      // (ONBOARD-02/03: never re-shows after skip).
      if (!_onboardingComplete) {
        return OnboardingScreen(
          onDone: () async {
            await _onboardingStore.markComplete();
            if (!mounted) return;
            setState(() => _onboardingComplete = true); // rebuild → AppShell
          },
        );
      }

      return const AppShell();
    }

    // ── Unauthenticated — login or register ───────────────────────────────────
    if (_showRegister) {
      return RegisterScreen(
        onLoginTap: () => setState(() => _showRegister = false),
      );
    }

    // Build the LoginScreen, passing the session-expired notice if needed.
    // The notice is seeded into LoginScreen's initState via initialMessage,
    // so it renders inside the framed panel exactly once.  We schedule a
    // post-frame reset of the flag so a future rebuild doesn't re-seed it
    // into a newly-constructed LoginScreen (the copy is already displayed).
    final String? expiredMessage =
        _sessionExpired ? 'Session expired — please log in again' : null;

    if (_sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sessionExpired) {
          setState(() => _sessionExpired = false);
        }
      });
    }

    return LoginScreen(
      onRegisterTap: () => setState(() => _showRegister = true),
      initialMessage: expiredMessage,
    );
  }
}
