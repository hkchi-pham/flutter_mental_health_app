import '../../shared/models/garden_model.dart';
import 'cache/change_op.dart';

/// Pure diff: computes the ordered [List<ChangeOp>] describing exactly what
/// changed between [prev] and [next] GardenState snapshots.
///
/// This function is the heart of the offline-first write path: every
/// [saveGardenState] call passes (lastKnown, next) here to derive the
/// per-resource ops that map to /garden/* + /users/me REST calls.
///
/// ## Rules
///
/// **Trees** (keyed by id):
///   - id in next, not in prev  → plantItem  (full create payload)
///   - id in both, row/col changed → moveItem  (row/col + panel_index:0)
///   - id in both, growth increased OR lastWatered advanced → waterItem
///       (CLIENT-AUTHORITATIVE: payload carries the four post-water fields
///        {growth_stage, growth_points, health, water_units}; the server persists
///        them verbatim and debits user.water_units inside that call)
///   - A tree that BOTH moved AND was watered → emit moveItem THEN waterItem.
///   - id in prev, not in next → deleteItem
///
/// **Decorations** (keyed by id):
///   - id in next, not in prev → placeDecoration  (full create payload)
///   - id in both, row/col changed → moveDecoration (row/col + panel_index:0)
///   - id in prev, not in next → removeDecoration
///
/// **Badges** (keyed by id):
///   - tradedFor was null in prev and non-null in next → tradeBadge
///       (payload: {trade_type: next.tradedFor.name})
///   - `seen` changes are local-only — no op emitted.
///   - Newly-appeared untraded badges are server-created (water flow) — no op.
///
/// **Currency** (setCurrency):
///   SUPPRESSION RULE (deterministic, no double-write):
///   The water endpoint already writes user.water_units INSIDE the water call.
///   To avoid two order-sensitive writes to water_units in the same transition:
///   - If a waterItem op was emitted this diff:
///       only emit setCurrency when points changed (shop/badge-trade/award).
///       The water spend is already handled by the waterItem call.
///       When BOTH a points change AND a waterItem coexist, setCurrency still
///       carries the absolute water_units (idempotent with the water call's
///       identical value); it is ordered AFTER waterItem so the final
///       water_units is consistent.
///   - If NO waterItem op was emitted:
///       emit setCurrency on ANY points OR water change (e.g. shop water purchase).
///
/// ## Ordering
/// Currency op is appended LAST (after trees and decorations). This is
/// deterministic and safe: setCurrency is an absolute set (idempotent with the
/// same value), so ordering relative to plant/move/delete/deco ops does not
/// matter for correctness.
///
/// ## Purity
/// No I/O. No side effects. Fully deterministic for the same (prev, next) pair.
List<ChangeOp> diffGarden(GardenState prev, GardenState next) {
  final ops = <ChangeOp>[];
  bool waterItemEmitted = false;

  // ─── Build id-maps ───────────────────────────────────────────────────────
  final prevTrees = {for (final t in prev.trees) t.id: t};
  final nextTrees = {for (final t in next.trees) t.id: t};

  final prevDecos = {for (final d in prev.decorations) d.id: d};
  final nextDecos = {for (final d in next.decorations) d.id: d};

  final prevBadges = {for (final b in prev.badges) b.id: b};
  final nextBadges = {for (final b in next.badges) b.id: b};

  // ─── Trees ───────────────────────────────────────────────────────────────
  // Planted (in next, not in prev)
  for (final entry in nextTrees.entries) {
    if (!prevTrees.containsKey(entry.key)) {
      final t = entry.value;
      ops.add(ChangeOp.create(
        kind: ChangeKind.plantItem,
        entityId: t.id,
        payload: {
          'id': t.id,
          'item_type': t.type.name,
          'growth_stage': (t.level + 1).clamp(1, 5),
          'growth_points': t.growth,
          'health': t.health,
          'row': t.row,
          'col': t.col,
          'panel_index': 0, // single-panel client — always 0
          'last_water_at': t.lastWatered?.toIso8601String(),
        },
      ));
    }
  }

  // Deleted (in prev, not in next)
  for (final entry in prevTrees.entries) {
    if (!nextTrees.containsKey(entry.key)) {
      ops.add(ChangeOp.create(
        kind: ChangeKind.deleteItem,
        entityId: entry.key,
      ));
    }
  }

  // Modified (in both)
  for (final entry in nextTrees.entries) {
    final id = entry.key;
    final n = entry.value;
    final p = prevTrees[id];
    if (p == null) continue; // handled above as plantItem

    // Move: row or col changed
    final moved = (p.row != n.row || p.col != n.col);
    // Watered: growth increased OR lastWatered advanced
    final watered = (n.growth > p.growth) ||
        (n.lastWatered != null &&
            (p.lastWatered == null ||
                n.lastWatered!.isAfter(p.lastWatered!)));

    if (moved) {
      ops.add(ChangeOp.create(
        kind: ChangeKind.moveItem,
        entityId: id,
        payload: {
          'row': n.row,
          'col': n.col,
          'panel_index': 0, // single-panel client — always 0
        },
      ));
    }

    if (watered) {
      // CLIENT-AUTHORITATIVE water state. The server persists these four
      // fields verbatim and writes user.water_units = water_units inside the
      // water call. The client is the computation authority.
      ops.add(ChangeOp.create(
        kind: ChangeKind.waterItem,
        entityId: id,
        payload: {
          'growth_stage': (n.level + 1).clamp(1, 5), // backend range 1–5
          'growth_points': n.growth,
          'health': n.health,
          'water_units': next.water, // absolute balance post-water
        },
      ));
      waterItemEmitted = true;
    }
  }

  // ─── Decorations ─────────────────────────────────────────────────────────
  // Placed (in next, not in prev)
  for (final entry in nextDecos.entries) {
    if (!prevDecos.containsKey(entry.key)) {
      final d = entry.value;
      ops.add(ChangeOp.create(
        kind: ChangeKind.placeDecoration,
        entityId: d.id,
        payload: {
          'id': d.id,
          'deco_type': d.type.name,
          'row': d.row,
          'col': d.col,
          'panel_index': 0, // single-panel client — always 0
        },
      ));
    }
  }

  // Removed (in prev, not in next)
  for (final entry in prevDecos.entries) {
    if (!nextDecos.containsKey(entry.key)) {
      ops.add(ChangeOp.create(
        kind: ChangeKind.removeDecoration,
        entityId: entry.key,
      ));
    }
  }

  // Moved (in both, row/col changed)
  for (final entry in nextDecos.entries) {
    final id = entry.key;
    final n = entry.value;
    final p = prevDecos[id];
    if (p == null) continue;

    if (p.row != n.row || p.col != n.col) {
      ops.add(ChangeOp.create(
        kind: ChangeKind.moveDecoration,
        entityId: id,
        payload: {
          'row': n.row,
          'col': n.col,
          'panel_index': 0, // single-panel client — always 0
        },
      ));
    }
  }

  // ─── Badges ──────────────────────────────────────────────────────────────
  // tradedFor: null → non-null (badge traded)
  // Ignore: seen changes (local-only), newly-appeared untraded badges (server-created)
  for (final entry in nextBadges.entries) {
    final id = entry.key;
    final n = entry.value;
    final p = prevBadges[id];
    if (p == null) continue; // new badge — server-created via water flow, no op

    if (p.tradedFor == null && n.tradedFor != null) {
      ops.add(ChangeOp.create(
        kind: ChangeKind.tradeBadge,
        entityId: id,
        payload: {
          'trade_type': n.tradedFor!.name,
        },
      ));
    }
  }

  // ─── Currency ─────────────────────────────────────────────────────────────
  // SUPPRESSION RULE: if a waterItem was emitted, the water endpoint already
  // writes water_units, so only emit setCurrency when points changed.
  // If no waterItem, emit setCurrency on any points OR water change.
  final pointsChanged = prev.points != next.points;
  final waterChanged = prev.water != next.water;

  final shouldEmitCurrency = waterItemEmitted
      ? pointsChanged // water endpoint owns water_units for this transition
      : (pointsChanged || waterChanged); // no waterItem → track all currency changes

  if (shouldEmitCurrency) {
    // Ordered LAST; carries absolute values (idempotent absolute-set).
    ops.add(ChangeOp.create(
      kind: ChangeKind.setCurrency,
      payload: {
        'points': next.points,
        'water_units': next.water,
      },
    ));
  }

  return ops;
}
