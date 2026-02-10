import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  late SharedPreferences _prefs;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Save JSON data
  Future<bool> saveJson(String key, Map<String, dynamic> data) async {
    return await _prefs.setString(key, jsonEncode(data));
  }

  // Save JSON list
  Future<bool> saveJsonList(String key, List<Map<String, dynamic>> data) async {
    return await _prefs.setString(key, jsonEncode(data));
  }

  // Load JSON data
  Map<String, dynamic>? loadJson(String key) {
    final String? data = _prefs.getString(key);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // Load JSON list
  List<Map<String, dynamic>> loadJsonList(String key) {
    final String? data = _prefs.getString(key);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  // Save int
  Future<bool> saveInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  // Load int
  int? loadInt(String key) {
    return _prefs.getInt(key);
  }

  // Remove
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // Save String
  Future<bool> saveString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  // Load String
  String? getString(String key) {
    return _prefs.getString(key);
  }
}
