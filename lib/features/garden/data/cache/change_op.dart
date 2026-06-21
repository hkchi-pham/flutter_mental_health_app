import 'dart:convert';

/// The kind of mutation this op represents.
/// Every mutation that Plan 03's offline queue must replay is listed here.
enum ChangeKind {
  plantItem,
  moveItem,
  waterItem,
  deleteItem,
  placeDecoration,
  moveDecoration,
  removeDecoration,
  tradeBadge,
  setCurrency,
}

/// A replayable offline mutation.
///
/// [opId]     — unique id used for de-duplication and targeted removal from the queue.
/// [kind]     — the type of operation to replay.
/// [entityId] — the affected item/decoration/badge id; empty string for [ChangeKind.setCurrency].
/// [payload]  — the REST request body fields (enough to reconstruct the exact HTTP call).
/// [createdAt] — used for FIFO ordering within the queue.
class ChangeOp {
  final String opId;
  final ChangeKind kind;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const ChangeOp({
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
  factory ChangeOp.create({
    required ChangeKind kind,
    String entityId = '',
    Map<String, dynamic> payload = const {},
  }) {
    _counter = (_counter + 1) % 0xFFFFFF; // wrap to keep string short
    final opId = '${DateTime.now().microsecondsSinceEpoch}_$_counter';
    return ChangeOp(
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

  /// Parses a [ChangeOp] from JSON.
  ///
  /// Throws [FormatException] on an unknown [kind] value so the queue can
  /// catch and skip corrupt/future entries rather than crashing.
  factory ChangeOp.fromJson(Map<String, dynamic> json) {
    final kindStr = json['kind'] as String;
    final kind = ChangeKind.values.cast<ChangeKind?>().firstWhere(
          (k) => k?.name == kindStr,
          orElse: () => null,
        );
    if (kind == null) {
      throw FormatException('Unknown ChangeKind: $kindStr');
    }
    final rawPayload = json['payload'];
    final Map<String, dynamic> payload;
    if (rawPayload is Map<String, dynamic>) {
      payload = rawPayload;
    } else if (rawPayload is String) {
      // Defensive: tolerate payload accidentally stringified
      payload = jsonDecode(rawPayload) as Map<String, dynamic>;
    } else {
      payload = const {};
    }
    return ChangeOp(
      opId: json['opId'] as String,
      kind: kind,
      entityId: json['entityId'] as String? ?? '',
      payload: payload,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() =>
      'ChangeOp(opId: $opId, kind: ${kind.name}, entityId: $entityId)';
}
