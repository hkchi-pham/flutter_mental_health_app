import '../../../shared/network/api_client.dart';
import '../dto/tree_dto.dart';

/// Thin wrapper over the backend's `/tree` endpoints. These are the granular
/// calls the GardenProvider should make for economy mutations — the backend has
/// NO bulk "save whole garden" endpoint, and currency/growth are server-owned.
class TreeRemoteDataSource {
  TreeRemoteDataSource(this._client);
  final ApiClient _client;

  /// GET /tree/ → PaginatedResponse[TreeRead]. Returns the current user's trees.
  Future<List<TreeDto>> list() async {
    final body = await _client.get('/tree/');
    final data = (body is Map ? body['data'] : null) as List? ?? const [];
    return data
        .map((e) => TreeDto.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// POST /tree/ — plant a new tree.
  Future<void> create(TreeDto tree) =>
      _client.post('/tree/', body: tree.toCreateJson());

  /// PUT /tree/{id}/water — the backend `water_tree`: server heals + grows the
  /// tree and debits the user's water/points. No request body; re-read after.
  Future<void> water(String treeId) => _client.put('/tree/$treeId/water');

  /// POST /tree/{id}/grow — soft-deletes the current tree and plants a new one.
  Future<void> grow(String treeId, TreeDto seed) =>
      _client.post('/tree/$treeId/grow', body: seed.toCreateJson());

  /// DELETE /tree/{id} — soft-delete on the backend.
  Future<void> delete(String treeId) => _client.delete('/tree/$treeId');
}
