import 'profile_remote_data_source.dart';
import 'profile_user.dart';

/// Thin facade over [ProfileRemoteDataSource].
///
/// Keeps the provider (Plan 03) decoupled from [ApiClient] — mirrors the
/// layering used in [GardenRepository] / [JournalRepository].
///
/// This phase has NO offline cache (SharedPreferences caching of /users/me is
/// OFFL-03, deferred to Phase 14). All operations are live network calls.
///
/// Provider contract:
///   - [me]             → fetch identity + six live stat counts
///   - [updateName]     → optimistic name edit; provider applies copyWith first
///   - [changePassword] → let [ApiException] propagate; provider maps 400
///                        "INVALID_OLD_PASSWORD" to Vietnamese error string
class ProfileRepository {
  ProfileRepository(this._remote);
  final ProfileRemoteDataSource _remote;

  /// Fetches the current user's full profile including six stat counts.
  ///
  /// Delegates to [ProfileRemoteDataSource.me].
  Future<ProfileUser> me() => _remote.me();

  /// Updates the authenticated user's display name.
  ///
  /// Delegates to [ProfileRemoteDataSource.updateName].
  /// The provider applies an optimistic [ProfileUser.copyWith] before awaiting
  /// this call so the UI updates immediately.
  Future<void> updateName({
    required String userId,
    required String fullname,
  }) =>
      _remote.updateName(userId: userId, fullname: fullname);

  /// Changes the authenticated user's password.
  ///
  /// Delegates to [ProfileRemoteDataSource.changePassword].
  /// [ApiException] propagates — the provider (Plan 03) handles 400 errors
  /// with a descriptive Vietnamese message for wrong old password.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) =>
      _remote.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
}
