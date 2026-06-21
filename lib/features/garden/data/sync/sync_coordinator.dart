import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../../../../features/auth/data/auth_session.dart';
import '../api_garden_repository.dart';

/// Drives the three sync triggers defined in Phase 10 CONTEXT:
///   1. App-open  — fires once in [start] after the first frame.
///   2. Reconnect — fires when connectivity transitions from offline -> online.
///   3. Resume    — fires when the app returns to foreground ([AppLifecycleState.resumed]).
///
/// All sync work is silent: no SnackBar, no UI indicator, no setState on any
/// visible widget. A thrown [ApiException] (or any error) is swallowed — the
/// repository itself is already resilient to offline failures.
///
/// No polling: there is no [Timer] or [Stream.periodic] anywhere in this class.
class SyncCoordinator with WidgetsBindingObserver {
  SyncCoordinator({
    required ApiGardenRepository repo,
    required AuthSession session,
  })  : _repo = repo,
        _session = session;

  final ApiGardenRepository _repo;
  final AuthSession _session;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Tracks whether the last known connectivity state included any live
  /// network — used to detect the offline -> online EDGE and ignore repeats.
  bool _wasOnline = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Registers the lifecycle observer, subscribes to connectivity changes, and
  /// schedules the app-open sync after the first frame (so the widget tree is
  /// fully mounted before any async work begins).
  void start() {
    WidgetsBinding.instance.addObserver(this);

    // Subscribe to connectivity changes — detect offline -> online edge only.
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);

    // App-open sync: schedule after the first frame so the Provider tree is
    // complete and the repository is fully wired before we touch it.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _syncIfAuthed();
    });
  }

  /// Removes the lifecycle observer and cancels the connectivity subscription.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  // ---------------------------------------------------------------------------
  // WidgetsBindingObserver
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Resume-from-background trigger.
      _syncIfAuthed();
    }
    // All other states (paused, inactive, detached, hidden) are ignored.
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline =
        results.any((r) => r != ConnectivityResult.none);

    if (isOnline && !_wasOnline) {
      // Offline -> online edge detected — reconnect trigger.
      _syncIfAuthed();
    }
    // online -> online or online -> offline: no action.
    _wasOnline = isOnline;
  }

  /// Fires [ApiGardenRepository.backgroundSync] only when the user is logged
  /// in. Uses [unawaited] so callers are never blocked, and wraps in try/catch
  /// so any thrown offline [ApiException] is silently swallowed.
  void _syncIfAuthed() {
    if (_session.userName == null) return;
    // ignore: discarded_futures
    unawaited(() async {
      try {
        await _repo.backgroundSync();
      } catch (_) {
        // Swallow all errors — offline or server errors must never surface.
      }
    }());
  }
}
