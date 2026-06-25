import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'journal_change_op.dart';

/// Persistent FIFO change queue for journal mutations, backed by
/// SharedPreferences.
///
/// Ops are stored as a JSON array under [_key] and survive app restarts.
///
/// ## Coalesce rules (conservative)
///
/// Applied on [enqueue] before appending:
/// - **Create-then-delete**: if [JournalChangeKind.deleteNotebook] is enqueued
///   and a pending [JournalChangeKind.createNotebook] for the same
///   [JournalChangeOp.entityId] exists, remove that create AND skip the delete
///   (the notebook never reached the server).
/// - **Redundant metadata update**: if [JournalChangeKind.updateNotebook] is
///   enqueued and the LAST pending op for the same entity is also an
///   updateNotebook, replace it in place (latest metadata wins).
/// - **No coalesce** for [JournalChangeKind.addEntry] or
///   [JournalChangeKind.replacePage] — these are content mutations that are not
///   idempotent-merge-safe at the queue level.
class JournalChangeQueue {
  static const String _key = 'journal_change_queue_v1';

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns all persisted ops in FIFO (insertion) order. Corrupt or
  /// unknown-kind entries are silently dropped.
  Future<List<JournalChangeOp>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final ops = <JournalChangeOp>[];
      for (final item in list) {
        try {
          ops.add(JournalChangeOp.fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Drop corrupt / unknown-kind entries.
        }
      }
      return ops;
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Write helpers
  // ---------------------------------------------------------------------------

  Future<void> _persist(
      List<JournalChangeOp> ops, SharedPreferences prefs) async {
    if (ops.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(
          _key, jsonEncode(ops.map((o) => o.toJson()).toList()));
    }
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Appends [op] to the queue after applying coalesce rules, then persists.
  Future<void> enqueue(JournalChangeOp op) async {
    final prefs = await SharedPreferences.getInstance();
    var ops = await all();

    // --- Coalesce: create-then-delete ---
    if (op.kind == JournalChangeKind.deleteNotebook) {
      final hasPendingCreate = ops.any((o) =>
          o.kind == JournalChangeKind.createNotebook &&
          o.entityId == op.entityId);
      if (hasPendingCreate) {
        ops = ops
            .where((o) => !(o.kind == JournalChangeKind.createNotebook &&
                o.entityId == op.entityId))
            .toList();
        await _persist(ops, prefs);
        return; // skip the delete — notebook never hit the server
      }
    }

    // --- Coalesce: consecutive metadata updates (latest wins) ---
    if (op.kind == JournalChangeKind.updateNotebook && ops.isNotEmpty) {
      final last = ops.last;
      if (last.kind == JournalChangeKind.updateNotebook &&
          last.entityId == op.entityId) {
        ops[ops.length - 1] = op; // replace in place, keep FIFO slot
        await _persist(ops, prefs);
        return;
      }
    }

    // Default: append.
    ops.add(op);
    await _persist(ops, prefs);
  }

  /// Removes the op with [opId] and persists.
  Future<void> removeById(String opId) async {
    final prefs = await SharedPreferences.getInstance();
    final ops = await all();
    final filtered = ops.where((o) => o.opId != opId).toList();
    await _persist(filtered, prefs);
  }

  /// Overwrites the entire queue with [ops] and persists.
  Future<void> replaceAll(List<JournalChangeOp> ops) async {
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
