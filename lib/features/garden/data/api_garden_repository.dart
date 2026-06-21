import 'dart:async';

import '../../auth/data/auth_session.dart';
import '../../shared/network/api_client.dart';
import '../../shared/models/garden_model.dart';
import 'cache/change_op.dart';
import 'cache/change_queue.dart';
import 'cache/garden_cache_store.dart';
import 'dto/garden_badge_dto.dart';
import 'dto/garden_decoration_dto.dart';
import 'dto/garden_item_dto.dart';
import 'garden_diff.dart';
import 'garden_repository.dart';
import 'remote/garden_badge_remote_data_source.dart';
import 'remote/garden_decoration_remote_data_source.dart';
import 'remote/garden_item_remote_data_source.dart';
import 'remote/garden_user_remote_data_source.dart';

/// Offline-first [GardenRepository] backed by:
///   - [GardenCacheStore] as the UI's source of truth (SharedPreferences).
///   - Per-resource remote data sources for /garden/* + /users/me (Plan 01).
///   - [ChangeQueue] for durable offline ops that replay on reconnect (Plan 02).
///   - [diffGarden] to derive granular [ChangeOp]s from full-state snapshots.
///
/// ## Read path
/// [getGardenState] returns the cached state instantly (if available) and fires
/// a background server refresh that does NOT block the returned future. On cold
/// start (no cache), awaits the server; on cold start + offline, returns a seed
/// default matching [MockGardenRepository] so first-run UX is unchanged.
///
/// ## Write path
/// [saveGardenState] writes to cache immediately (optimistic), then diffs the
/// new state against [_lastKnown] to derive [ChangeOp]s. Online: each op is
/// applied via REST with targeted cache reconciliation. Offline (ApiException
/// status 0) or queue already non-empty: ops are enqueued instead. Network
/// errors never surface to the provider — they are silently caught and the op
/// is enqueued or dropped per the conflict policy below.
///
/// ## Conflict policy (per Phase 10 CONTEXT)
/// - Local-queue-wins: queued ops replay in FIFO order on reconnect.
/// - Currency: replay-then-reread — after a full queue drain, [_refreshFromServer]
///   adopts the server's final currency as truth.
/// - Server rejections (ApiException status >= 400): drop the op + schedule a
///   background [_refreshFromServer] for self-healing.
///
/// ## Auth
/// When [AuthSession.userName] is null (logged out) the repository operates in
/// local-only mode: cache read/write proceed normally but no network calls are
/// made and the queue is not flushed.
class ApiGardenRepository implements GardenRepository {
  ApiGardenRepository({
    required GardenItemRemoteDataSource items,
    required GardenDecorationRemoteDataSource decos,
    required GardenBadgeRemoteDataSource badges,
    required GardenUserRemoteDataSource user,
    required AuthSession session,
    required GardenCacheStore cache,
    required ChangeQueue queue,
  })  : _items = items,
        _decos = decos,
        _badges = badges,
        _user = user,
        _session = session,
        _cache = cache,
        _queue = queue;

  final GardenItemRemoteDataSource _items;
  final GardenDecorationRemoteDataSource _decos;
  final GardenBadgeRemoteDataSource _badges;
  final GardenUserRemoteDataSource _user;
  final AuthSession _session;
  final GardenCacheStore _cache;
  final ChangeQueue _queue;

  /// In-memory snapshot of the last-known full state. Seeded from cache on
  /// first read; kept up-to-date on every save and server refresh. Used as the
  /// "previous" state for [diffGarden] so diffs are based on the most recent
  /// confirmed state rather than an arbitrary old cache read.
  GardenState? _lastKnown;

  // ─── Seed default ─────────────────────────────────────────────────────────
  /// Default state for cold-start + offline. Matches [MockGardenRepository]
  /// seed so first-run offline UX is identical to the local-only flow.
  static GardenState get _seedDefault =>
      GardenState(points: 1500, water: 10);

  // =========================================================================
  // GardenRepository interface
  // =========================================================================

  @override
  Future<GardenState> getGardenState() async {
    final cached = await _cache.read();

    if (cached != null) {
      // Cache hit — return immediately; refresh server in background.
      _lastKnown ??= cached;
      // Fire-and-forget; swallow any offline/network error so it never
      // propagates to the provider.
      unawaited(_refreshFromServer().then((_) {}).onError((_, st) {}));
      return cached;
    }

    // Cold start — no cache.
    if (_session.userName != null) {
      try {
        return await _refreshFromServer();
      } catch (_) {
        // Offline or auth error on cold start — return seed default.
        final seed = _seedDefault;
        await _cache.write(seed);
        _lastKnown ??= seed;
        return seed;
      }
    }

    // Not logged in + no cache — local seed.
    final seed = _seedDefault;
    await _cache.write(seed);
    _lastKnown ??= seed;
    return seed;
  }

  @override
  Future<void> saveGardenState(GardenState next) async {
    // 1. Write to cache immediately (optimistic — UI already updated).
    await _cache.write(next);

    // 2. Derive granular ops by diffing against the last-known state.
    final ops = diffGarden(_lastKnown ?? next, next);

    // 3. Advance the last-known pointer BEFORE any async work so a concurrent
    //    save arriving while we are mid-flight uses the most recent base.
    _lastKnown = next;

    // 4. Local-only mode when not logged in.
    if (_session.userName == null) return;

    // 5. Apply each op — online if possible, enqueue otherwise.
    bool offlineMode = false;
    // Check if the queue is already non-empty — if so, always enqueue (FIFO).
    if (!await _queue.isEmpty()) {
      offlineMode = true;
    }

    bool needsSelfHeal = false;

    for (final op in ops) {
      if (offlineMode) {
        await _queue.enqueue(op);
        continue;
      }

      try {
        await _applyOp(op);
      } on ApiException catch (e) {
        if (e.statusCode == 0) {
          // Network unreachable — switch to offline mode for remaining ops.
          offlineMode = true;
          await _queue.enqueue(op);
        } else {
          // Server rejection (4xx/5xx) — drop op, schedule self-heal.
          needsSelfHeal = true;
        }
      } catch (_) {
        // Unexpected error — enqueue conservatively.
        await _queue.enqueue(op);
      }
    }

    if (needsSelfHeal) {
      // Self-heal: re-read server state to reconcile after a rejection.
      unawaited(_refreshFromServer().then((_) {}).onError((_, st) {}));
    }
  }

  // =========================================================================
  // Plan 04 hooks (flushQueue / backgroundSync)
  // =========================================================================

  /// Drains the offline queue in FIFO order, applying each op via REST.
  ///
  /// On success: removes the op from the queue.
  /// On ApiException(0): stops (still offline) — remaining ops stay queued.
  /// On ApiException(>=400): drops the op (server rejection) + continues.
  ///
  /// After a fully-drained queue, runs [_refreshFromServer] so the server's
  /// final currency is adopted as truth (currency replay-then-reread).
  Future<void> flushQueue() async {
    final pending = await _queue.all();
    if (pending.isEmpty) return;

    for (final op in pending) {
      try {
        await _applyOp(op);
        await _queue.removeById(op.opId);
      } on ApiException catch (e) {
        if (e.statusCode == 0) {
          // Still offline — stop flushing.
          return;
        }
        // Server rejection — drop and continue to next op.
        await _queue.removeById(op.opId);
      } catch (_) {
        // Unexpected error — leave in queue, stop flushing.
        return;
      }
    }

    // Queue fully drained — adopt server's final state as truth.
    unawaited(_refreshFromServer().then((_) {}).onError((_, st) {}));
  }

  /// Full reconnect sync: flush offline queue then refresh from server.
  ///
  /// Called by Plan 04's connectivity listener on reconnect/app resume.
  Future<void> backgroundSync() async {
    await flushQueue();
    await _refreshFromServer();
  }

  // =========================================================================
  // Private: server refresh
  // =========================================================================

  /// Fetches the full garden state from the server concurrently and writes
  /// the result to cache + [_lastKnown]. Returns the refreshed [GardenState].
  ///
  /// Preserves local-only fields that the server does not own:
  ///   - `seen` flags on badges (merged by id from [_lastKnown]).
  ///   - `currentPalette` (server has no concept of this field).
  Future<GardenState> _refreshFromServer() async {
    // Fetch all four server resources concurrently with typed futures.
    final itemsFuture = _items.list();
    final decosFuture = _decos.list();
    final badgesFuture = _badges.list();
    final currencyFuture = _user.me();

    final itemDtos = await itemsFuture;
    final decoDtos = await decosFuture;
    final badgeDtos = await badgesFuture;
    final currency = await currencyFuture; // CurrencyDto

    // Map DTOs to local models using server row/col (backend owns layout).
    final trees = itemDtos.map((d) => d.toLocal()).toList();
    final decos = decoDtos.map((d) => d.toLocal()).toList();

    // Merge `seen` flags from last-known state (local-only field).
    final prevBadgesById = {
      for (final b in (_lastKnown?.badges ?? const <Badge>[])) b.id: b,
    };
    final badges = badgeDtos.map((d) {
      final local = d.toLocal();
      final prev = prevBadgesById[local.id];
      // Preserve the local `seen` flag if we have a prior record; otherwise
      // trust the server value (which defaults to false for new badges).
      if (prev != null) {
        return local.copyWith(seen: prev.seen);
      }
      return local;
    }).toList();

    // Preserve palette (server-unknown, client-only).
    final palette = _lastKnown?.currentPalette ?? PaletteType.calm;

    final refreshed = GardenState(
      points: currency.points,
      water: currency.water,
      trees: trees,
      decorations: decos,
      currentPalette: palette,
      badges: badges,
    );

    await _cache.write(refreshed);
    _lastKnown = refreshed;
    return refreshed;
  }

  // =========================================================================
  // Private: apply a single ChangeOp via REST + targeted cache reconciliation
  // =========================================================================

  /// Executes [op] against the matching remote data source and reconciles the
  /// affected cache slice. Throws [ApiException] on network or server error
  /// so the caller can decide whether to enqueue or drop.
  Future<void> _applyOp(ChangeOp op) async {
    switch (op.kind) {
      // ── Tree ops ──────────────────────────────────────────────────────────
      case ChangeKind.plantItem:
        final dto = await _items.create(
          GardenItemDto.fromJson(op.payload),
        );
        await _mergeTree(dto);

      case ChangeKind.moveItem:
        final dto = await _items.update(op.entityId, op.payload);
        await _mergeTree(dto);

      case ChangeKind.waterItem:
        // CLIENT-AUTHORITATIVE: pass all four fields verbatim. The server
        // persists them and debits user.water_units inside this call.
        // Do NOT separately PUT currency for this water spend — diffGarden's
        // suppression rule already prevented a duplicate setCurrency op.
        final dto = await _items.water(
          op.entityId,
          health: op.payload['health'] as int,
          growthStage: op.payload['growth_stage'] as int,
          growthPoints: op.payload['growth_points'] as int,
          waterUnits: op.payload['water_units'] as int,
        );
        await _mergeTree(dto);

      case ChangeKind.deleteItem:
        await _items.delete(op.entityId);
        await _removeTreeFromCache(op.entityId);

      // ── Decoration ops ────────────────────────────────────────────────────
      case ChangeKind.placeDecoration:
        final dto = await _decos.create(
          GardenDecorationDto.fromJson(op.payload),
        );
        await _mergeDeco(dto);

      case ChangeKind.moveDecoration:
        final dto = await _decos.update(op.entityId, op.payload);
        await _mergeDeco(dto);

      case ChangeKind.removeDecoration:
        await _decos.delete(op.entityId);
        await _removeDecoFromCache(op.entityId);

      // ── Badge ops ─────────────────────────────────────────────────────────
      case ChangeKind.tradeBadge:
        final dto = await _badges.trade(
          op.entityId,
          op.payload['trade_type'] as String,
        );
        await _mergeBadge(dto);

      // ── Currency op ───────────────────────────────────────────────────────
      case ChangeKind.setCurrency:
        await _user.setCurrency(
          points: op.payload['points'] as int,
          water: op.payload['water_units'] as int,
        );
        await _mergeCurrency(
          points: op.payload['points'] as int,
          water: op.payload['water_units'] as int,
        );
    }
  }

  // =========================================================================
  // Private: targeted cache merge helpers
  // =========================================================================

  /// Replaces or inserts a tree in the cached state by id.
  Future<void> _mergeTree(GardenItemDto dto) async {
    final cached = _lastKnown;
    if (cached == null) return;
    final local = dto.toLocal();
    final trees = [
      for (final t in cached.trees)
        if (t.id == local.id) local else t,
    ];
    // Insert if not already present (e.g. plantItem on first ever create).
    if (!cached.trees.any((t) => t.id == local.id)) {
      trees.add(local);
    }
    final updated = cached.copyWith(trees: trees);
    await _cache.write(updated);
    _lastKnown = updated;
  }

  /// Removes a tree from the cached state by id.
  Future<void> _removeTreeFromCache(String id) async {
    final cached = _lastKnown;
    if (cached == null) return;
    final updated =
        cached.copyWith(trees: cached.trees.where((t) => t.id != id).toList());
    await _cache.write(updated);
    _lastKnown = updated;
  }

  /// Replaces or inserts a decoration in the cached state by id.
  Future<void> _mergeDeco(GardenDecorationDto dto) async {
    final cached = _lastKnown;
    if (cached == null) return;
    final local = dto.toLocal();
    final decos = [
      for (final d in cached.decorations)
        if (d.id == local.id) local else d,
    ];
    if (!cached.decorations.any((d) => d.id == local.id)) {
      decos.add(local);
    }
    final updated = cached.copyWith(decorations: decos);
    await _cache.write(updated);
    _lastKnown = updated;
  }

  /// Removes a decoration from the cached state by id.
  Future<void> _removeDecoFromCache(String id) async {
    final cached = _lastKnown;
    if (cached == null) return;
    final updated = cached.copyWith(
      decorations: cached.decorations.where((d) => d.id != id).toList(),
    );
    await _cache.write(updated);
    _lastKnown = updated;
  }

  /// Replaces or inserts a badge in the cached state by id.
  Future<void> _mergeBadge(GardenBadgeDto dto) async {
    final cached = _lastKnown;
    if (cached == null) return;
    final local = dto.toLocal();
    // Preserve local `seen` flag from the prior badge state.
    final prev = cached.badges.where((b) => b.id == local.id).firstOrNull;
    final merged = prev != null ? local.copyWith(seen: prev.seen) : local;

    final badges = [
      for (final b in cached.badges)
        if (b.id == merged.id) merged else b,
    ];
    if (!cached.badges.any((b) => b.id == merged.id)) {
      badges.add(merged);
    }
    final updated = cached.copyWith(badges: badges);
    await _cache.write(updated);
    _lastKnown = updated;
  }

  /// Updates points and water in the cached state (absolute set).
  Future<void> _mergeCurrency({required int points, required int water}) async {
    final cached = _lastKnown;
    if (cached == null) return;
    final updated = cached.copyWith(points: points, water: water);
    await _cache.write(updated);
    _lastKnown = updated;
  }
}

