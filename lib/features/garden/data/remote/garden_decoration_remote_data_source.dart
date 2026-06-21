import '../../../shared/network/api_client.dart';
import '../dto/garden_decoration_dto.dart';

/// Thin wrapper over the Phase 9 backend's `/garden/decorations` endpoints.
///
/// All paths are relative to `/api/v1` (ApiClient prepends this automatically).
/// Responses use the `{ "data": ... }` envelope; this class unwraps `body['data']`.
class GardenDecorationRemoteDataSource {
  GardenDecorationRemoteDataSource(this._client);
  final ApiClient _client;

  /// GET /garden/decorations → PaginatedResponse[GardenDecorationRead].
  ///
  /// Returns all decorations for the authenticated user.
  Future<List<GardenDecorationDto>> list() async {
    final body = await _client.get('/garden/decorations');
    final data = (body is Map ? body['data'] : null) as List? ?? const [];
    return data
        .map((e) =>
            GardenDecorationDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// POST /garden/decorations — place a new decoration.
  ///
  /// Sends the full create payload (including client-supplied `id` for
  /// idempotent offline-queue replay).
  Future<GardenDecorationDto> create(GardenDecorationDto decoration) async {
    final body = await _client.post(
      '/garden/decorations',
      body: decoration.toCreateJson(),
    );
    final data = (body is Map ? body['data'] : null);
    final map = (data is Map ? data : body as Map).cast<String, dynamic>();
    return GardenDecorationDto.fromJson(map);
  }

  /// PUT /garden/decorations/{id} — partial update (position fields).
  Future<GardenDecorationDto> update(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final body = await _client.put('/garden/decorations/$id', body: patch);
    final data = (body is Map ? body['data'] : null);
    final map = (data is Map ? data : body as Map).cast<String, dynamic>();
    return GardenDecorationDto.fromJson(map);
  }

  /// DELETE /garden/decorations/{id} — soft-delete on the backend.
  Future<void> delete(String id) => _client.delete('/garden/decorations/$id');
}
