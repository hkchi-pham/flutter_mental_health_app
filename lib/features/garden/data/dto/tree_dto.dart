import '../../../shared/models/garden_model.dart';

/// Snake_case DTO mirroring the backend's TreeModel / TreeResponse.
///
/// Kept SEPARATE from the local [Tree] model on purpose — the backend uses
/// different field names, a 1–5 `level` range (the app uses 0–4), and has no
/// grid position. All translation lives here so the rest of the app keeps using
/// the local model unchanged.
class TreeDto {
  TreeDto({
    required this.id,
    required this.userId,
    required this.treeType,
    required this.level,
    required this.growthPoints,
    required this.health,
    this.lastWaterAt,
  });

  final String id;
  final String userId;
  final String treeType;
  final int level; // backend range: 1–5
  final int growthPoints;
  final int health; // 0–100
  final DateTime? lastWaterAt;

  /// Defensive parse: `TreeResponse` types `level`/`health` as String while
  /// `TreeModel` stores them as int — accept either (see INTEGRATION_FIXES.md).
  static int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory TreeDto.fromJson(Map<String, dynamic> json) => TreeDto(
        id: '${json['id'] ?? ''}',
        userId: '${json['user_id'] ?? ''}',
        treeType: '${json['tree_type'] ?? 'sakura'}',
        level: _asInt(json['level'], 1),
        growthPoints: _asInt(json['growth_points'], 0),
        health: _asInt(json['health'], 100),
        lastWaterAt: json['last_water_at'] != null
            ? DateTime.tryParse('${json['last_water_at']}')
            : null,
      );

  Map<String, dynamic> toCreateJson() => {
        'user_id': userId,
        'tree_type': treeType,
        'level': level,
        'growth_points': growthPoints,
        'health': health,
        'last_water_at': lastWaterAt?.toIso8601String(),
      };

  /// Backend tree → local [Tree]. Level 1–5 → 0–4. The backend stores no grid
  /// position, so [row]/[col] are supplied by the caller (the client owns layout).
  Tree toLocal({required int row, required int col}) => Tree(
        id: id,
        type: TreeType.values.firstWhere(
          (e) => e.name == treeType,
          orElse: () => TreeType.sakura,
        ),
        row: row,
        col: col,
        growth: growthPoints,
        level: (level - 1).clamp(0, 4),
        health: health.clamp(0, 100),
        plantedDate: lastWaterAt ?? DateTime.now(),
        lastWatered: lastWaterAt,
      );

  /// Local [Tree] → backend DTO. Level 0–4 → 1–5.
  factory TreeDto.fromLocal(Tree t, {required String userId}) => TreeDto(
        id: t.id,
        userId: userId,
        treeType: t.type.name,
        level: (t.level + 1).clamp(1, 5),
        growthPoints: t.growth,
        health: t.health,
        lastWaterAt: t.lastWatered,
      );
}
