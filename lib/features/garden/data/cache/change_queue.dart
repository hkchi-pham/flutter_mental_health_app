import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'change_op.dart';

/// Persistent FIFO change queue backed by SharedPreferences.
///
/// Ops are stored as a JSON array under [_key]. The queue survives app restarts:
/// a freshly-constructed [ChangeQueue] re-reads from SharedPreferences.
///
/// ## Coalesce rules (conservative)
///
/// Applied on [enqueue] before appending:
/// - **Redundant moves**: if the last pending op for the same [ChangeOp.entityId]
///   is a move of the same kind ([ChangeKind.moveItem] or
///   [ChangeKind.moveDecoration]), replace it with the incoming op (latest
///   position wins). Only the *last* op of the same kind on the same entity is
///   replaced — earlier moves are left intact.
/// - **Create-then-delete**: if [ChangeKind.deleteItem] or
///   [ChangeKind.removeDecoration] is enqueued and there is a pending
///   [ChangeKind.plantItem] / [ChangeKind.placeDecoration] for the same
///   [ChangeOp.entityId], remove that create op AND skip the delete (the item
///   never reached the server, so no server-side delete is needed).
/// - **No coalesce** for [ChangeKind.waterItem], [ChangeKind.tradeBadge], or
///   [ChangeKind.setCurrency] — these are not idempotent-merge-safe at the
///   queue level.
class ChangeQueue {
  static const String _key = 'garden_change_queue_v1';

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns all persisted ops in FIFO (insertion) order.
  ///
  /// Corrupt or unknown-kind entries are silently dropped so a future app
  /// version that adds a new [ChangeKind] does not break older clients when
  /// reading an older queue.
  Future<List<ChangeOp>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final ops = <ChangeOp>[];
      for (final item in list) {
        try {
          ops.add(ChangeOp.fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Drop corrupt / unknown-kind entries.
        }
      }
      return ops;
    } catch (_) {
      // Top-level JSON is corrupt — treat as empty queue.
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Write helpers
  // ---------------------------------------------------------------------------

  Future<void> _persist(List<ChangeOp> ops, SharedPreferences prefs) async {
    if (ops.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, jsonEncode(ops.map((o) => o.toJson()).toList()));
    }
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Appends [op] to the queue after applying coalesce rules, then persists.
  Future<void> enqueue(ChangeOp op) async {
    final prefs = await SharedPreferences.getInstance();
    var ops = await all();

    // --- Coalesce: create-then-delete ---
    // If we're about to delete an entity that has a pending *create* still in
    // the queue (i.e. never flushed to the server), cancel both.
    if (op.kind == ChangeKind.deleteItem || op.kind == ChangeKind.removeDecoration) {
      final createKind = op.kind == ChangeKind.deleteItem
          ? ChangeKind.plantItem
          : ChangeKind.placeDecoration;
      final hasPendingCreate =
          ops.any((o) => o.kind == createKind && o.entityId == op.entityId);
      if (hasPendingCreate) {
        // Remove the pending create and skip this delete — item never hit server.
        ops = ops
            .where((o) => !(o.kind == createKind && o.entityId == op.entityId))
            .toList();
        await _persist(ops, prefs);
        return; // skip the delete
      }
    }

    // --- Coalesce: redundant moves ---
    // Replace the last pending move op of the same kind+entity with the new one.
    if (op.kind == ChangeKind.moveItem || op.kind == ChangeKind.moveDecoration) {
      // Find the last index with matching kind+entity.
      int lastMoveIdx = -1;
      for (int i = ops.length - 1; i >= 0; i--) {
        if (ops[i].kind == op.kind && ops[i].entityId == op.entityId) {
          lastMoveIdx = i;
          break;
        }
      }
      if (lastMoveIdx >= 0) {
        ops[lastMoveIdx] = op; // replace in-place (keeps FIFO slot)
        await _persist(ops, prefs);
        return;
      }
    }

    // Default: just append.
    ops.add(op);
    await _persist(ops, prefs);
  }

  /// Removes the op with [opId] from the queue and persists.
  Future<void> removeById(String opId) async {
    final prefs = await SharedPreferences.getInstance();
    final ops = await all();
    final filtered = ops.where((o) => o.opId != opId).toList();
    await _persist(filtered, prefs);
  }

  /// Overwrites the entire queue with [ops] and persists.
  ///
  /// Used after a successful server flush (replace with remaining ops) or a
  /// batch coalesce pass.
  Future<void> replaceAll(List<ChangeOp> ops) async {
    final prefs = await SharedPreferences.getInstance();
    await _persist(List.of(ops), prefs);
  }

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// Returns `true` if the queue has no pending ops.
  Future<bool> isEmpty() async => (await all()).isEmpty;

  /// Returns the number of pending ops.
  Future<int> length() async => (await all()).length;
}
