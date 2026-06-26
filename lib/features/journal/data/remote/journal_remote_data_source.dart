import '../../../shared/network/api_client.dart';
import '../dto/journal_dto.dart';

/// Thin wrapper over the Phase 11-01 backend's `/journals` endpoints.
///
/// All paths are relative to `/api/v1` (ApiClient prepends this automatically).
/// Responses use the `{ message, data, ... }` envelope; this class unwraps
/// `body['data']`.
///
/// NOTE: the backend returns 404 when the user has zero journals — [list]
/// treats that as an empty list (not an error).
class JournalRemoteDataSource {
  JournalRemoteDataSource(this._client);
  final ApiClient _client;

  /// GET /journals/search-all-journals?page=&page_size=
  ///
  /// Returns a paginated, newest-first list of the user's journals. A 404
  /// (zero journals) is mapped to an empty list rather than an error.
  Future<List<JournalDto>> list({int page = 1, int pageSize = 20}) async {
    try {
      final body = await _client.get(
        '/journals/search-all-journals',
        query: {'page': page, 'page_size': pageSize},
      );
      final data = (body is Map ? body['data'] : null) as List? ?? const [];
      return data
          .map((e) => JournalDto.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// POST /journals/ — create a new journal.
  ///
  /// The backend returns the created journal in `data` (Plan 11 fix), so the
  /// caller can adopt the server-assigned id. If an older backend returns no
  /// `data`, the input [journal] is returned unchanged as a fallback.
  Future<JournalDto> create(JournalDto journal) async {
    final body = await _client.post('/journals/', body: journal.toCreateJson());
    final data = (body is Map ? body['data'] : null);
    if (data is Map) {
      return JournalDto.fromJson(data.cast<String, dynamic>());
    }
    return journal;
  }

  /// GET /journals/{id} → SuccessResponse[JournalResponse].
  Future<JournalDto> getOne(String id) async {
    final body = await _client.get('/journals/$id');
    final data = (body is Map ? body['data'] : null);
    final map = (data is Map ? data : body as Map).cast<String, dynamic>();
    return JournalDto.fromJson(map);
  }

  /// PUT /journals/{id} — metadata update (title/emoji/visibility/color).
  Future<void> update(String id, Map<String, dynamic> patch) =>
      _client.put('/journals/$id', body: patch);

  /// DELETE /journals/{id}.
  Future<void> delete(String id) => _client.delete('/journals/$id');

  /// POST /journals/{id}/page/entry — append one entry to the page.
  ///
  /// Body `{id, content}`; the client supplies [entryId] for idempotent
  /// offline-queue replay.
  Future<void> appendEntry(
    String id, {
    required String entryId,
    required String content,
  }) =>
      _client.post(
        '/journals/$id/page/entry',
        body: {'id': entryId, 'content': content},
      );

  /// PUT /journals/{id}/page — REPLACE the whole page object.
  ///
  /// Used for entry edit AND entry delete (rebuild the index-keyed [page] from
  /// the current entry list via [JournalDto.entriesToPage]).
  Future<void> replacePage(String id, Map<String, dynamic> page) =>
      _client.put('/journals/$id/page', body: {'page': page});
}
