import '../../../shared/network/api_client.dart';
import '../dto/garden_badge_dto.dart';

/// Thin wrapper over the Phase 9 backend's `/garden/badges` endpoints.
///
/// All paths are relative to `/api/v1` (ApiClient prepends this automatically).
/// Responses use the `{ "data": ... }` envelope; this class unwraps `body['data']`.
class GardenBadgeRemoteDataSource {
  GardenBadgeRemoteDataSource(this._client);
  final ApiClient _client;

  /// GET /garden/badges → PaginatedResponse[GardenBadgeRead].
  ///
  /// Returns all badges for the authenticated user.
  Future<List<GardenBadgeDto>> list() async {
    final body = await _client.get('/garden/badges');
    final data = (body is Map ? body['data'] : null) as List? ?? const [];
    return data
        .map((e) =>
            GardenBadgeDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// POST /garden/badges/{id}/trade — trade a badge for water or seeds.
  ///
  /// [tradeType] must be "water" or "seeds".
  /// Returns the updated [GardenBadgeDto] with `traded = true` and
  /// `trade_type` set.
  Future<GardenBadgeDto> trade(String id, String tradeType) async {
    final body = await _client.post(
      '/garden/badges/$id/trade',
      body: {'trade_type': tradeType},
    );
    final data = (body is Map ? body['data'] : null);
    final map = (data is Map ? data : body as Map).cast<String, dynamic>();
    return GardenBadgeDto.fromJson(map);
  }
}
