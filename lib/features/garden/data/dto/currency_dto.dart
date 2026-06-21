/// DTO for the currency fields extracted from the slim `/users/me` MeRead
/// response.
///
/// PINNED DECISIONS (do not deviate):
/// - `local water` ↔ `backend water_units`
/// - `local points` ↔ `backend points`
/// - All other MeRead fields are OUT OF SCOPE this phase — ignore them.
class CurrencyDto {
  CurrencyDto({required this.points, required this.water});

  final int points;
  final int water; // maps to backend `water_units`

  /// Defensive int parse — accepts int, num, or String.
  static int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  /// Parses the slim MeRead response body.
  ///
  /// Reads only `points` and `water_units`; all other MeRead fields ignored.
  factory CurrencyDto.fromJson(Map<String, dynamic> json) => CurrencyDto(
        points: _asInt(json['points'], 0),
        water: _asInt(json['water_units'], 0),
      );
}
