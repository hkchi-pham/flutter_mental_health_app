import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/garden_model.dart';
import 'garden_repository.dart';

class MockGardenRepository implements GardenRepository {
  static const _key = 'garden_state';

  @override
  Future<GardenState> getGardenState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    // First-time install: seed with starter XP + water so the watering and
    // shop loops can be tested immediately.
    if (raw == null || raw.isEmpty) {
      return _seed();
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final state = GardenState.fromJson(json);
      // Re-seed if the persisted state is effectively empty (0 XP, 0 water,
      // no trees). Earlier runs may have written an empty default state
      // before this seed existed.
      if (state.points == 0 && state.water == 0 && state.trees.isEmpty) {
        return _seed();
      }
      return state;
    } catch (_) {
      return _seed();
    }
  }

  GardenState _seed() => GardenState(points: 1500, water: 10);

  @override
  Future<void> saveGardenState(GardenState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
