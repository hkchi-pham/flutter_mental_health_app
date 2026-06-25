import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/notebook.dart';

/// SharedPreferences-backed local cache for the user's notebook list.
///
/// Mirrors [GardenCacheStore]: the cache is the UI's source of truth and the
/// backend is the sync target.
///
/// Contract:
/// - [read] returns `null` on cold start (no data, empty, or corrupt) so
///   callers can distinguish "no cache" from "cached empty list".
/// - [write] persists the full notebook snapshot (awaited).
class JournalCacheStore {
  static const String _key = 'journal_cache_v1';

  /// Returns the cached notebooks, or `null` if no valid cache exists.
  Future<List<Notebook>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Notebook.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      // Corrupt data — treat as cache miss.
      return null;
    }
  }

  /// Persists [notebooks] to SharedPreferences under [_key].
  Future<void> write(List<Notebook> notebooks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(notebooks.map((n) => n.toJson()).toList()),
    );
  }

  /// Clears the cached notebooks (e.g. on logout or hard reset).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
