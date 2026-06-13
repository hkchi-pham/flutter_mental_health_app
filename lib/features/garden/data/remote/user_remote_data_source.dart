import '../../../shared/network/api_client.dart';

/// Reads the current user's currency. On the backend, `points` and
/// `water_units` live on the User (not the Tree), and are server-authoritative
/// — the client reads them but cannot push them (UserUpdate has no such fields).
class UserRemoteDataSource {
  UserRemoteDataSource(this._client);
  final ApiClient _client;

  /// GET /users/{user_name} → SuccessResponse[UserResponse].
  Future<({int points, int water})> currency(String userName) async {
    final body = await _client.get('/users/$userName');
    final data = (body is Map ? body['data'] : null);
    final map = data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
    return (
      points: (map['points'] as num?)?.toInt() ?? 0,
      water: (map['water_units'] as num?)?.toInt() ?? 0,
    );
  }
}
