import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/garden_model.dart';

/// SharedPreferences-backed local cache for the full [GardenState].
///
/// Uses key [_key] — deliberately distinct from [MockGardenRepository]'s
/// legacy key (`'garden_state'`) so both coexist without collision during the
/// transition period when [ApiGardenRepository] is being wired up.
///
/// Contract:
/// - [read] returns `null` on cold start (no data, empty, or corrupt).
///   Callers (Plan 03) use `null` to distinguish "no cache" from an empty
///   garden — do NOT seed here.
/// - [write] persists the full garden snapshot synchronously (awaited).
class GardenCacheStore {
  static const String _key = 'garden_cache_v1';

  /// Returns the cached [GardenState], or `null` if no valid cache exists.
  Future<GardenState?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return GardenState.fromJson(json);
    } catch (_) {
      // Corrupt data — treat as cache miss so Plan 03 falls back to server.
      return null;
    }
  }

  /// Persists [state] to SharedPreferences under [_key].
  Future<void> write(GardenState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  /// Clears the cached state (e.g. on logout or hard reset).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
