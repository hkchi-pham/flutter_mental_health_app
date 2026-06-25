import 'dart:convert';

/// The kind of journal mutation this op represents.
/// Every mutation that the offline queue must replay is listed here.
enum JournalChangeKind {
  createNotebook,
  updateNotebook,
  deleteNotebook,
  addEntry,
  replacePage,
}

/// A replayable offline journal mutation.
///
/// [opId]      — unique id for de-duplication and targeted removal.
/// [kind]      — the type of operation to replay.
/// [entityId]  — the affected notebook id (empty for some create flows where the
///               client-supplied id IS the entityId).
/// [payload]   — the REST request body fields (enough to reconstruct the call).
/// [createdAt] — FIFO ordering within the queue.
class JournalChangeOp {
  final String opId;
  final JournalChangeKind kind;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const JournalChangeOp({
    required this.opId,
    required this.kind,
    required this.entityId,
    required this.payload,
    required this.createdAt,
  });

  /// Convenience factory that generates [opId] and [createdAt] automatically.
  ///
  /// Uses microsecondsSinceEpoch + a monotonic counter suffix to avoid
  /// collisions within the same microsecond (no external package required).
  static int _counter = 0;
  factory JournalChangeOp.create({
    required JournalChangeKind kind,
    String entityId = '',
    Map<String, dynamic> payload = const {},
  }) {
    _counter = (_counter + 1) % 0xFFFFFF; // wrap to keep string short
    final opId = '${DateTime.now().microsecondsSinceEpoch}_$_counter';
    return JournalChangeOp(
      opId: opId,
      kind: kind,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'opId': opId,
        'kind': kind.name,
        'entityId': entityId,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Parses a [JournalChangeOp] from JSON.
  ///
  /// Throws [FormatException] on an unknown [kind] so the queue can catch and
  /// skip corrupt/future entries rather than crashing.
  factory JournalChangeOp.fromJson(Map<String, dynamic> json) {
    final kindStr = json['kind'] as String;
    final kind = JournalChangeKind.values.cast<JournalChangeKind?>().firstWhere(
          (k) => k?.name == kindStr,
          orElse: () => null,
        );
    if (kind == null) {
      throw FormatException('Unknown JournalChangeKind: $kindStr');
    }
    final rawPayload = json['payload'];
    final Map<String, dynamic> payload;
    if (rawPayload is Map<String, dynamic>) {
      payload = rawPayload;
    } else if (rawPayload is String) {
      payload = jsonDecode(rawPayload) as Map<String, dynamic>;
    } else {
      payload = const {};
    }
    return JournalChangeOp(
      opId: json['opId'] as String,
      kind: kind,
      entityId: json['entityId'] as String? ?? '',
      payload: payload,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() =>
      'JournalChangeOp(opId: $opId, kind: ${kind.name}, entityId: $entityId)';
}
