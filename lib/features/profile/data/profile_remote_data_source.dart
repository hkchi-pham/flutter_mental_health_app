import '../../shared/network/api_client.dart';
import 'profile_user.dart';

/// Remote data source for the Profile feature.
///
/// Wraps three backend endpoints (all paths relative to `/api/v1` — ApiClient
/// prepends this automatically):
///
///   GET  /users/me          → [me] → [ProfileUser]
///   PUT  /users/{id}        → [updateName] (name-only; avatar upload deferred)
///   PUT  /auth/password     → [changePassword]
///
/// Envelope-unwrap pattern (mirrors GardenUserRemoteDataSource):
///   The backend wraps all success responses in `{ "message": ..., "data": ... }`.
///   This class unwraps `body['data']` before passing to [ProfileUser.fromJson].
///
/// Error handling:
///   [ApiException] propagates to the caller ([ProfileRepository] → provider).
///   The provider (Plan 03) maps `statusCode == 400` with detail containing
///   "INVALID_OLD_PASSWORD" to a descriptive Vietnamese message for the UI.
class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client);
  final ApiClient _client;

  /// GET /users/me → extended MeRead → [ProfileUser].
  ///
  /// Reads identity + six live stat counts: points, water_units, tree_grown,
  /// journal_count, conversation_count, badge_count.
  Future<ProfileUser> me() async {
    final body = await _client.get('/users/me');
    final data = (body is Map ? body['data'] : null);
    final map =
        (data is Map ? data : (body is Map ? body : <String, dynamic>{}))
            .cast<String, dynamic>();
    return ProfileUser.fromJson(map);
  }

  /// PUT /users/{userId} — update the user's display name.
  ///
  /// Sends only `{ "fullname": fullname }` (UserUpdate is partial — ONLY the
  /// fields present in the body are written; omitting avatar leaves it unchanged).
  ///
  /// Note: TRUE image upload is DEFERRED (Phase 14 / OFFL-03). This phase
  /// supports name-only editing via the existing 256-char `avatar` string field.
  Future<void> updateName({
    required String userId,
    required String fullname,
  }) =>
      _client.put('/users/$userId', body: {'fullname': fullname});

  /// PUT /auth/password — change the authenticated user's password.
  ///
  /// Body: `{ "old_password": oldPassword, "new_password": newPassword }`.
  ///
  /// On success: backend returns 200 `{ "message": "CHANGE_PASSWORD_SUCCESSFULLY" }`.
  /// On wrong old password: backend returns 400 with detail "INVALID_OLD_PASSWORD".
  ///   → [ApiException] with statusCode 400 is thrown; the provider maps this
  ///     to a friendly Vietnamese error string (SET-03).
  ///
  /// [ApiException] propagates on any error — no swallowing here.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) =>
      _client.put('/auth/password', body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
}
