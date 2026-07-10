import 'package:flutter/foundation.dart';

import '../data/profile_repository.dart';
import '../data/profile_user.dart';
import '../../shared/network/api_client.dart';

/// Possible states for the profile screen load lifecycle.
enum ProfileStatus { loading, loaded, error }

/// ChangeNotifier for the Profile feature.
///
/// Owns three categories of state:
///   1. Load state — [status] / [user] / [errorMessage] driven by [load].
///   2. Name edit  — [editName] applies an optimistic [ProfileUser.copyWith]
///                   and reverts on failure (PROF-03).
///   3. Password   — [changePassword] maps error codes to Vietnamese strings
///                   without storing password state on the provider (SET-03).
///
/// Lifecycle:
///   - Plan 04 (profile screen) calls [load] in its initState via
///     `context.read<ProfileProvider>().load()`.
///   - The provider is registered in main.dart via
///     `ChangeNotifierProxyProvider<ProfileRepository, ProfileProvider>`.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required ProfileRepository repository})
      : _repository = repository;

  final ProfileRepository _repository;

  // ── State fields ────────────────────────────────────────────────────────────

  ProfileStatus _status = ProfileStatus.loading;

  /// Current load state — drives loading skeleton / content / error widget.
  ProfileStatus get status => _status;

  ProfileUser? _user;

  /// The loaded profile, or null while loading/errored.
  ProfileUser? get user => _user;

  String? _errorMessage;

  /// Human-readable error shown when [status] == [ProfileStatus.error].
  String? get errorMessage => _errorMessage;

  // ── Methods ─────────────────────────────────────────────────────────────────

  /// Loads the current user's profile from the backend.
  ///
  /// Sets [status] to [ProfileStatus.loading], attempts `GET /users/me` via the
  /// repository, then transitions to [ProfileStatus.loaded] on success or
  /// [ProfileStatus.error] on failure. Always calls [notifyListeners] at the
  /// end.
  ///
  /// Used for initial load AND manual retry (the screen can call [load] again
  /// after showing an error state).
  Future<void> load() async {
    _status = ProfileStatus.loading;
    notifyListeners();
    try {
      _user = await _repository.me();
      _status = ProfileStatus.loaded;
      _errorMessage = null;
    } catch (_) {
      _status = ProfileStatus.error;
      _errorMessage = 'Không tải được hồ sơ. Thử lại.';
    }
    notifyListeners();
  }

  /// Optimistically edits the user's display name.
  ///
  /// Applies [ProfileUser.copyWith(fullname:)] immediately so the header
  /// updates before the network round-trip completes. On success returns
  /// `true`. On failure, reverts the user to the previous value, notifies
  /// listeners, and returns `false`.
  ///
  /// Does NOT change [status] — the profile is still "loaded" during and
  /// after the edit (regardless of success or failure).
  Future<bool> editName(String fullname, {required String userId}) async {
    final previous = _user;
    _user = _user?.copyWith(fullname: fullname);
    notifyListeners();

    try {
      await _repository.updateName(userId: userId, fullname: fullname);
      return true;
    } catch (_) {
      _user = previous;
      notifyListeners();
      return false;
    }
  }

  /// Changes the user's password and returns a Vietnamese error string on
  /// failure, or `null` on success.
  ///
  /// Error mapping (SET-03):
  ///   - [ApiException] with statusCode 400 → wrong old password message
  ///   - [ApiException] with statusCode 0   → no network message
  ///   - Any other error                     → generic failure message
  ///
  /// Password values are NOT stored on this provider — the caller (settings
  /// dialog) owns the text fields and discards them after calling this method.
  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return null; // null == success
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        return 'Mật khẩu cũ không đúng.';
      } else if (e.statusCode == 0) {
        return 'Không có kết nối mạng.';
      } else {
        return 'Đổi mật khẩu thất bại. Thử lại.';
      }
    } catch (_) {
      return 'Đổi mật khẩu thất bại. Thử lại.';
    }
  }
}
