import '../../../shared/network/api_client.dart';
import '../dto/currency_dto.dart';

/// Thin wrapper over the Phase 9 backend's `/users/me` endpoints.
///
/// Supersedes the stale [UserRemoteDataSource] which targeted the legacy
/// `/users/{user_name}` path. That file is left untouched — this class adds
/// the new surface alongside.
///
/// All paths are relative to `/api/v1` (ApiClient prepends this automatically).
/// Responses use the `{ "data": ... }` envelope; this class unwraps `body['data']`.
///
/// Currency mapping (PINNED):
/// - local `water`  ↔  backend `water_units`
/// - local `points` ↔  backend `points`
class GardenUserRemoteDataSource {
  GardenUserRemoteDataSource(this._client);
  final ApiClient _client;

  /// GET /users/me → slim MeRead → [CurrencyDto].
  ///
  /// Reads only `points` and `water_units` from the slim MeRead response;
  /// all other MeRead fields are out of scope this phase.
  Future<CurrencyDto> me() async {
    final body = await _client.get('/users/me');
    final data = (body is Map ? body['data'] : null);
    final map =
        (data is Map ? data : (body is Map ? body : <String, dynamic>{}))
            .cast<String, dynamic>();
    return CurrencyDto.fromJson(map);
  }

  /// PUT /users/me/currency — absolute-set both currency fields.
  ///
  /// The backend persists [points] and [water] verbatim (no server-side math).
  /// Idempotent: safe to replay from the offline queue.
  ///
  /// Body: `{ "points": points, "water_units": water }`.
  Future<void> setCurrency({required int points, required int water}) =>
      _client.put('/users/me/currency', body: {
        'points': points,
        'water_units': water,
      });
}
