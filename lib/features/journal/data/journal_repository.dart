import 'dart:async';

import '../../auth/data/auth_session.dart';
import '../../shared/network/api_client.dart';
import 'cache/journal_cache_store.dart';
import 'cache/journal_change_op.dart';
import 'cache/journal_change_queue.dart';
import 'dto/journal_dto.dart';
import 'models/notebook.dart';
import 'remote/journal_remote_data_source.dart';

/// Offline-first journal repository, mirroring [ApiGardenRepository]'s pattern:
///   - [JournalCacheStore] is the UI's source of truth (SharedPreferences).
///   - [JournalRemoteDataSource] talks to `/journals` (Plan 11-01 contract).
///   - [JournalChangeQueue] holds durable offline ops that replay on reconnect.
///
/// ## Read path
/// [loadNotebooks] returns the cache instantly when present, then fires a
/// background server refresh (swallowing offline errors). On cold start (no
/// cache) it awaits the server, falling back to an empty list when offline.
///
/// ## Write path
/// Every mutation writes to cache first (optimistic), then attempts the matching
/// REST call. On [ApiException] with `statusCode == 0` (offline) the op is
/// enqueued for later replay. When logged out (`session.userName == null`) the
/// repository operates cache-only and makes no network calls.
class JournalRepository {
  JournalRepository({
    required JournalRemoteDataSource remote,
    required JournalCacheStore cache,
    required JournalChangeQueue queue,
    required AuthSession session,
  })  : _remote = remote,
        _cache = cache,
        _queue = queue,
        _session = session;

  final JournalRemoteDataSource _remote;
  final JournalCacheStore _cache;
  final JournalChangeQueue _queue;
  final AuthSession _session;

  bool get _loggedIn => _session.userName != null;

  /// `true` when the [ApiException] means the request never reached the server.
  bool _isOffline(Object e) => e is ApiException && e.statusCode == 0;

  // =========================================================================
  // Read
  // =========================================================================

  /// Returns notebooks cache-first. On a cache hit, returns immediately and
  /// fires a background server refresh. On cold start, awaits the server
  /// (returning `[]` when offline / logged out).
  Future<List<Notebook>> loadNotebooks() async {
    final cached = await _cache.read();

    if (cached != null) {
      if (_loggedIn) {
        unawaited(_backgroundRefresh());
      }
      return cached;
    }

    // Cold start — no cache.
    if (!_loggedIn) return const [];
    try {
      return await _refreshFromServer();
    } catch (_) {
      // Offline or auth error on cold start.
      return const [];
    }
  }

  /// Fetches a page from the server for infinite scroll. Returns `[]` when
  /// offline (ApiException status 0) or logged out.
  Future<List<Notebook>> fetchPage(int page, int pageSize) async {
    if (!_loggedIn) return const [];
    try {
      final dtos = await _remote.list(page: page, pageSize: pageSize);
      return dtos.map((d) => d.toLocal()).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 0) return const [];
      rethrow;
    }
  }

  // =========================================================================
  // Write — notebooks
  // =========================================================================

  /// Optimistically adds [draft] to the cache, then creates it on the server.
  ///
  /// The POST returns no body, so on success we refresh the cache from the
  /// server (the draft's client-supplied id remains the local identity). When
  /// offline the create op is enqueued and the optimistic local copy is kept.
  Future<Notebook> createNotebook(Notebook draft) async {
    final list = await _readOrEmpty();
    await _writeCache([...list, draft]);

    if (!_loggedIn) return draft;

    final dto = JournalDto.fromLocal(draft, userId: _session.userId ?? '');
    try {
      await _remote.create(dto);
      // POST returns no body — refresh to adopt the server record.
      unawaited(_backgroundRefresh());
    } catch (e) {
      if (_isOffline(e)) {
        await _queue.enqueue(JournalChangeOp.create(
          kind: JournalChangeKind.createNotebook,
          entityId: draft.id,
          payload: dto.toCreateJson(),
        ));
      } else {
        rethrow;
      }
    }
    return draft;
  }

  /// Updates notebook metadata (title/emoji/visibility/color) optimistically,
  /// then PUTs to the server (enqueue on offline).
  Future<void> updateNotebook(Notebook nb) async {
    final list = await _readOrEmpty();
    await _writeCache([
      for (final n in list)
        if (n.id == nb.id) nb else n,
    ]);

    if (!_loggedIn) return;

    final patch = JournalDto.fromLocal(nb, userId: _session.userId ?? '')
        .toUpdateJson();
    try {
      await _remote.update(nb.id, patch);
    } catch (e) {
      if (_isOffline(e)) {
        await _queue.enqueue(JournalChangeOp.create(
          kind: JournalChangeKind.updateNotebook,
          entityId: nb.id,
          payload: patch,
        ));
      } else {
        rethrow;
      }
    }
  }

  /// Removes the notebook from cache optimistically, then DELETEs on the server
  /// (enqueue on offline).
  Future<void> deleteNotebook(String id) async {
    final list = await _readOrEmpty();
    await _writeCache(list.where((n) => n.id != id).toList());

    if (!_loggedIn) return;

    try {
      await _remote.delete(id);
    } catch (e) {
      if (_isOffline(e)) {
        await _queue.enqueue(JournalChangeOp.create(
          kind: JournalChangeKind.deleteNotebook,
          entityId: id,
        ));
      } else {
        rethrow;
      }
    }
  }

  // =========================================================================
  // Write — entries
  // =========================================================================

  /// Appends [entry] to [nb] optimistically (cache), then POSTs the single
  /// entry to the server (enqueue on offline). Returns the updated notebook.
  Future<Notebook> addEntry(Notebook nb, NotebookEntry entry) async {
    final updated = nb.copyWith(
      entries: [...nb.entries, entry]
        ..sort((a, b) => a.date.compareTo(b.date)),
    );
    final list = await _readOrEmpty();
    await _writeCache([
      for (final n in list)
        if (n.id == nb.id) updated else n,
    ]);

    if (!_loggedIn) return updated;

    try {
      await _remote.appendEntry(nb.id,
          entryId: entry.id, content: entry.content);
    } catch (e) {
      if (_isOffline(e)) {
        await _queue.enqueue(JournalChangeOp.create(
          kind: JournalChangeKind.addEntry,
          entityId: nb.id,
          payload: {'id': entry.id, 'content': entry.content},
        ));
      } else {
        rethrow;
      }
    }
    return updated;
  }

  /// Replaces the whole page with [nb].entries optimistically (cache), then
  /// PUTs the rebuilt page object to the server. Used for entry edit AND delete.
  Future<void> replacePage(Notebook nb) async {
    final list = await _readOrEmpty();
    await _writeCache([
      for (final n in list)
        if (n.id == nb.id) nb else n,
    ]);

    if (!_loggedIn) return;

    final page = JournalDto.entriesToPage(nb.entries);
    try {
      await _remote.replacePage(nb.id, page);
    } catch (e) {
      if (_isOffline(e)) {
        await _queue.enqueue(JournalChangeOp.create(
          kind: JournalChangeKind.replacePage,
          entityId: nb.id,
          payload: {'page': page},
        ));
      } else {
        rethrow;
      }
    }
  }

  // =========================================================================
  // Sync hooks (Plan 03 reconnect)
  // =========================================================================

  /// Drains the offline queue FIFO, applying each op via REST. Removes the op
  /// on success; stops on [ApiException] status 0 (still offline); drops the op
  /// on a server rejection (>= 400) and continues.
  Future<void> flushQueue() async {
    final pending = await _queue.all();
    if (pending.isEmpty) return;

    for (final op in pending) {
      try {
        await _applyOp(op);
        await _queue.removeById(op.opId);
      } on ApiException catch (e) {
        if (e.statusCode == 0) return; // still offline — stop
        await _queue.removeById(op.opId); // server rejection — drop, continue
      } catch (_) {
        return; // unexpected — leave queued, stop
      }
    }
  }

  /// Full reconnect sync: flush the queue then refresh the cache from server.
  /// Swallows errors so it can be fired unawaited from a connectivity listener.
  Future<void> backgroundSync() async {
    if (!_loggedIn) return;
    await flushQueue();
    try {
      await _refreshFromServer();
    } catch (_) {
      // offline / transient — ignore
    }
  }

  // =========================================================================
  // Private
  // =========================================================================

  Future<List<Notebook>> _readOrEmpty() async =>
      (await _cache.read()) ?? const [];

  Future<void> _writeCache(List<Notebook> notebooks) =>
      _cache.write(notebooks);

  /// Fire-and-forget server refresh — swallows all errors so it can be passed
  /// to [unawaited] without an unhandled-future warning.
  Future<void> _backgroundRefresh() async {
    try {
      await _refreshFromServer();
    } catch (_) {
      // offline / transient — ignore
    }
  }

  /// Fetches the newest-first first page and writes it to cache. Returns the
  /// refreshed list.
  Future<List<Notebook>> _refreshFromServer() async {
    final dtos = await _remote.list(page: 1, pageSize: 20);
    final notebooks = dtos.map((d) => d.toLocal()).toList();
    await _cache.write(notebooks);
    return notebooks;
  }

  /// Replays a single queued op against the remote. Throws [ApiException] so
  /// [flushQueue] can decide to stop, drop, or continue.
  Future<void> _applyOp(JournalChangeOp op) async {
    switch (op.kind) {
      case JournalChangeKind.createNotebook:
        await _remote.create(JournalDto.fromJson(op.payload));
      case JournalChangeKind.updateNotebook:
        await _remote.update(op.entityId, op.payload);
      case JournalChangeKind.deleteNotebook:
        await _remote.delete(op.entityId);
      case JournalChangeKind.addEntry:
        await _remote.appendEntry(
          op.entityId,
          entryId: '${op.payload['id'] ?? ''}',
          content: '${op.payload['content'] ?? ''}',
        );
      case JournalChangeKind.replacePage:
        final page = (op.payload['page'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        await _remote.replacePage(op.entityId, page);
    }
  }
}
