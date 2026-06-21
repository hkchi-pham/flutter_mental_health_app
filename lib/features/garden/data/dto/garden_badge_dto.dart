import '../../../shared/models/garden_model.dart';

/// Snake_case DTO mirroring the Phase 9 backend `garden_badges` table.
///
/// Maps between the backend wire shape (snake_case, `stage` unranged int
/// defaulting 0) and the local [Badge] model (`treeLevel` 1–4).
///
/// PINNED DECISIONS:
/// - Badge `stage` is an unranged int on the backend (default 0, no enforced
///   range). Local `treeLevel` is 1–4. On READ: `treeLevel = stage.clamp(1, 4)`
///   (defensive — legacy/default rows may carry stage 0). On WRITE: `stage = treeLevel`.
/// - `trade_type` "water" → TradeReward.water; "seed"/"seeds" → TradeReward.seeds.
class GardenBadgeDto {
  GardenBadgeDto({
    required this.id,
    required this.userId,
    required this.treeType,
    required this.stage,
    required this.earnedAt,
    required this.traded,
    this.tradeType,
    required this.seen,
    required this.treeId,
  });

  final String id;
  final String userId;
  final String treeType;
  final int stage; // unranged int on backend; local treeLevel is 1–4
  final DateTime earnedAt;
  final bool traded;
  final String? tradeType; // "water", "seed", or "seeds" — null if untraded
  final bool seen;
  final String treeId;

  static bool _asBool(dynamic v, bool fallback) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v == 'true' || v == '1';
    return fallback;
  }

  static int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory GardenBadgeDto.fromJson(Map<String, dynamic> json) {
    return GardenBadgeDto(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      treeType: '${json['tree_type'] ?? 'sakura'}',
      stage: _asInt(json['stage'], 0),
      earnedAt: json['earned_at'] != null
          ? DateTime.tryParse('${json['earned_at']}') ?? DateTime.now()
          : DateTime.now(),
      traded: _asBool(json['traded'], false),
      tradeType: json['trade_type'] != null ? '${json['trade_type']}' : null,
      seen: _asBool(json['seen'], false),
      treeId: '${json['tree_id'] ?? ''}',
    );
  }

  /// Full create payload (client-supplied `id` for idempotent offline replay).
  Map<String, dynamic> toCreateJson() => {
        'id': id,
        'user_id': userId,
        'tree_type': treeType,
        'stage': stage,
        'earned_at': earnedAt.toIso8601String(),
        'traded': traded,
        'trade_type': tradeType,
        'seen': seen,
        'tree_id': treeId,
      };

  /// Backend badge → local [Badge].
  ///
  /// `stage.clamp(1, 4)` — defensive clamp for legacy/default rows (stage 0)
  /// into the valid local treeLevel range 1–4.
  Badge toLocal() => Badge(
        id: id,
        treeLevel: stage.clamp(1, 4),
        treeType: treeType,
        treeId: treeId,
        tradedFor: _parseTradeReward(tradeType),
        seen: seen,
        earnedAt: earnedAt,
      );

  /// Parses backend `trade_type` string → [TradeReward].
  static TradeReward? _parseTradeReward(String? raw) {
    if (raw == null) return null;
    final s = raw.toLowerCase();
    if (s == 'water') return TradeReward.water;
    if (s == 'seed' || s == 'seeds') return TradeReward.seeds;
    return null;
  }

  /// Local [Badge] → backend DTO.
  ///
  /// `stage = b.treeLevel` (no clamp on write — local treeLevel is already 1–4).
  /// `traded = b.tradedFor != null`.
  /// `trade_type = b.tradedFor?.name` (null if untraded).
  factory GardenBadgeDto.fromLocal(Badge b, {required String userId}) =>
      GardenBadgeDto(
        id: b.id,
        userId: userId,
        treeType: b.treeType,
        stage: b.treeLevel,
        earnedAt: b.earnedAt,
        traded: b.tradedFor != null,
        tradeType: b.tradedFor?.name,
        seen: b.seen,
        treeId: b.treeId,
      );
}
