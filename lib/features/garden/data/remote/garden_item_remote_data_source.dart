import '../../../shared/network/api_client.dart';
import '../dto/garden_item_dto.dart';

/// Thin wrapper over the Phase 9 backend's `/garden/items` endpoints.
///
/// All paths are relative to `/api/v1` (ApiClient prepends this automatically).
/// Responses use the `{ "data": ... }` envelope; this class unwraps `body['data']`.
///
/// Water contract: POST /garden/items/{id}/water expects all four fields
/// (health, growth_stage, growth_points, water_units) from the CLIENT.
/// The backend persists them verbatim (no server-side game math).
class GardenItemRemoteDataSource {
  GardenItemRemoteDataSource(this._client);
  final ApiClient _client;

  /// GET /garden/items → PaginatedResponse[GardenItemRead].
  ///
  /// Returns all garden items for the authenticated user.
  Future<List<GardenItemDto>> list() async {
    final body = await _client.get('/garden/items');
    final data = (body is Map ? body['data'] : null) as List? ?? const [];
    return data
        .map((e) => GardenItemDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// POST /garden/items — plant a new garden item.
  ///
  /// Sends the full create payload (including client-supplied `id` for
  /// idempotent offline-queue replay).
  Future<GardenItemDto> create(GardenItemDto item) async {
    final body = await _client.post('/garden/items', body: item.toCreateJson());
    final data = (body is Map ? body['data'] : null);
    final map = (data is Map ? data : body as Map).cast<String, dynamic>();
    return GardenItemDto.fromJson(map);
  }

  /// PUT /garden/items/{id} — partial update (position + growth fields).
  Future<GardenItemDto> update(String id, Map<String, dynamic> patch) async {
    final body = await _client.put('/garden/items/$id', body: patch);
    final data = (body is Map ? body['data'] : null);
    final map = (data is Map ? data : body as Map).cast<String, dynamic>();
    return GardenItemDto.fromJson(map);
  }

  /// DELETE /garden/items/{id} — soft-delete on the backend.
  Future<void> delete(String id) => _client.delete('/garden/items/$id');

  /// POST /garden/items/{id}/water — client-authoritative post-water state.
  ///
  /// The client computes heal/grow math; the backend persists all four fields
  /// verbatim and writes `user.water_units = waterUnits` (the water-spend
  /// debit happens inside this call — confirmed in GardenItemCrud.water_item).
  ///
  /// Returns the updated [GardenItemDto] for optimistic-state reconciliation.
  Future<GardenItemDto> water(
    String id, {
    required int health,
    required int growthStage,
    required int growthPoints,
    required int waterUnits,
  }) async {
    final body = await _client.post('/garden/items/$id/water', body: {
      'health': health,
      'growth_stage': growthStage,
      'growth_points': growthPoints,
      'water_units': waterUnits,
    });
    final data = (body is Map ? body['data'] : null);
    final map = (data is Map ? data : body as Map).cast<String, dynamic>();
    return GardenItemDto.fromJson(map);
  }
}
