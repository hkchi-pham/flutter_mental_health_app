import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'garden_model.dart';

class GardenRepository {
  static const String _gardenKey = 'garden_state';

  Future<GardenState> getGardenState() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_gardenKey);
    if (data != null) {
      return GardenState.fromJson(jsonDecode(data) as Map<String, dynamic>);
    }
    return GardenState();
  }

  Future<void> saveGardenState(GardenState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gardenKey, jsonEncode(state.toJson()));
  }
}
