import '../../../shared/models/garden_model.dart';

/// Snake_case DTO mirroring the Phase 9 backend `garden_items` table.
///
/// Maps between the backend wire shape (snake_case, `growth_stage` 1–5,
/// explicit `row`/`col`/`panel_index`) and the local [Tree] model
/// (`level` 0–4, `row`/`col` only — this client is single-panel).
///
/// PINNED DECISIONS:
/// - `panel_index` is ALWAYS emitted as `0` on write (single-panel client).
/// - `toLocal()` IGNORES the server's `panel_index`; placement uses `row`/`col`.
/// - `level 0–4` ↔ `growth_stage 1–5` (same pattern as legacy TreeDto).
class GardenItemDto {
  GardenItemDto({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.growthStage,
    required this.growthPoints,
    required this.health,
    required this.row,
    required this.col,
    required this.panelIndex,
    this.lastWaterAt,
  });

  final String id;
  final String userId;
  final String itemType;
  final int growthStage; // backend range: 1–5
  final int growthPoints;
  final int health; // 0–100
  final int row;
  final int col;
  final int panelIndex; // always 0 for this client
  final DateTime? lastWaterAt;

  /// Defensive parse: accepts int, num, or String — mirrors TreeDto._asInt.
  static int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory GardenItemDto.fromJson(Map<String, dynamic> json) => GardenItemDto(
        id: '${json['id'] ?? ''}',
        userId: '${json['user_id'] ?? ''}',
        itemType: '${json['item_type'] ?? 'sakura'}',
        growthStage: _asInt(json['growth_stage'], 1),
        growthPoints: _asInt(json['growth_points'], 0),
        health: _asInt(json['health'], 100),
        row: _asInt(json['row'], 0),
        col: _asInt(json['col'], 0),
        panelIndex: _asInt(json['panel_index'], 0),
        lastWaterAt: json['last_water_at'] != null
            ? DateTime.tryParse('${json['last_water_at']}')
            : null,
      );

  /// Full create payload (client-supplied `id` for idempotent offline replay).
  Map<String, dynamic> toCreateJson() => {
        'id': id,
        'user_id': userId,
        'item_type': itemType,
        'growth_stage': growthStage,
        'growth_points': growthPoints,
        'health': health,
        'row': row,
        'col': col,
        'panel_index': 0, // single-panel client — always 0
        'last_water_at': lastWaterAt?.toIso8601String(),
      };

  /// Partial update payload for PUT (position + growth fields only).
  Map<String, dynamic> toUpdateJson() => {
        'row': row,
        'col': col,
        'panel_index': 0, // single-panel client — always 0
        'growth_stage': growthStage,
        'growth_points': growthPoints,
        'health': health,
        'last_water_at': lastWaterAt?.toIso8601String(),
      };

  /// Backend item → local [Tree].
  ///
  /// Uses server `row`/`col` directly (backend owns layout per CONTEXT).
  /// Ignores `panel_index` — local placement is single-panel, row/col only.
  /// `growth_stage` 1–5 → local `level` 0–4.
  Tree toLocal() => Tree(
        id: id,
        type: TreeType.values.firstWhere(
          (e) => e.name == itemType,
          orElse: () => TreeType.sakura,
        ),
        row: row,
        col: col,
        growth: growthPoints,
        level: (growthStage - 1).clamp(0, 4),
        health: health.clamp(0, 100),
        plantedDate: lastWaterAt ?? DateTime.now(),
        lastWatered: lastWaterAt,
      );

  /// Local [Tree] → backend DTO.
  ///
  /// Maps local `level` 0–4 → `growth_stage` 1–5.
  /// Always emits `panel_index: 0` (single-panel — see PINNED DECISIONS).
  factory GardenItemDto.fromLocal(Tree t, {required String userId}) =>
      GardenItemDto(
        id: t.id,
        userId: userId,
        itemType: t.type.name,
        growthStage: (t.level + 1).clamp(1, 5),
        growthPoints: t.growth,
        health: t.health,
        row: t.row,
        col: t.col,
        panelIndex: 0, // single-panel client — always 0
        lastWaterAt: t.lastWatered,
      );
}
