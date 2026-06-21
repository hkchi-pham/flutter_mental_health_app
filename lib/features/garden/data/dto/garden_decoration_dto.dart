import '../../../shared/models/garden_model.dart';

/// Snake_case DTO mirroring the Phase 9 backend `garden_decorations` table.
///
/// Maps between the backend wire shape (snake_case, `deco_type`, `row`/`col`/
/// `panel_index`) and the local [GardenDecoration] model (`row`/`col` only).
///
/// PINNED DECISIONS:
/// - `panel_index` is ALWAYS emitted as `0` on write (single-panel client).
/// - `toLocal()` IGNORES the server's `panel_index`; placement uses `row`/`col`.
class GardenDecorationDto {
  GardenDecorationDto({
    required this.id,
    required this.userId,
    required this.decoType,
    required this.row,
    required this.col,
    required this.panelIndex,
  });

  final String id;
  final String userId;
  final String decoType;
  final int row;
  final int col;
  final int panelIndex; // always 0 for this client

  /// Defensive int parse — mirrors GardenItemDto._asInt.
  static int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory GardenDecorationDto.fromJson(Map<String, dynamic> json) =>
      GardenDecorationDto(
        id: '${json['id'] ?? ''}',
        userId: '${json['user_id'] ?? ''}',
        decoType: '${json['deco_type'] ?? 'chair'}',
        row: _asInt(json['row'], 0),
        col: _asInt(json['col'], 0),
        panelIndex: _asInt(json['panel_index'], 0),
      );

  /// Full create payload (client-supplied `id` for idempotent offline replay).
  Map<String, dynamic> toCreateJson() => {
        'id': id,
        'user_id': userId,
        'deco_type': decoType,
        'row': row,
        'col': col,
        'panel_index': 0, // single-panel client — always 0
      };

  /// Partial update payload for PUT (position fields only).
  Map<String, dynamic> toUpdateJson() => {
        'row': row,
        'col': col,
        'panel_index': 0, // single-panel client — always 0
      };

  /// Backend decoration → local [GardenDecoration].
  ///
  /// Uses server `row`/`col` directly. Ignores `panel_index` — local placement
  /// is single-panel, row/col only.
  GardenDecoration toLocal() => GardenDecoration(
        id: id,
        type: DecorationType.values.firstWhere(
          (e) => e.name == decoType,
          orElse: () => DecorationType.chair,
        ),
        row: row,
        col: col,
      );

  /// Local [GardenDecoration] → backend DTO.
  ///
  /// Always emits `panel_index: 0` (single-panel — see PINNED DECISIONS).
  factory GardenDecorationDto.fromLocal(
    GardenDecoration d, {
    required String userId,
  }) =>
      GardenDecorationDto(
        id: d.id,
        userId: userId,
        decoType: d.type.name,
        row: d.row,
        col: d.col,
        panelIndex: 0, // single-panel client — always 0
      );
}
