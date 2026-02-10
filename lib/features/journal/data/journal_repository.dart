import 'dart:convert';
import 'package:http/http.dart' as http;
import 'journal_model.dart';

class JournalRepository {
  static const String _baseUrl = 'http://100.118.172.29:8081/api/v1/journals';
  static const String _token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzdHJpbmciLCJ1c2VyX2lkIjoiYmU3YzQxODctMTIxZC00Zjk2LWJiYzMtNDQzMDI3YmVjMTUzIiwiZXhwIjoxNzcwNzI1MjE5fQ.y_ZNkLDIBvgBC581E204tATQm0JQR-KagtL7GsgaRWQ";

  Map<String, String> get _headers => {
    'accept': 'application/json',
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  Future<List<Journal>> getJournals() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search-all-journals?page=1&page_size=10'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic> && data['data'] is List) {
          list = data['data'];
        }

        return list
            .map((e) => Journal.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load journals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching journals: $e');
    }
  }

  Future<Journal> addJournal(Journal journal) async {
    try {
      final body = {
        "user_id": "string",
        "title": journal.title,
        "emoji": journal.emoji,
        "page": {},
        "content": "",
        "visibility": "private",
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic jsonResponse = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('data')) {
          return Journal.fromJson(jsonResponse['data']);
        }
        return Journal.fromJson(jsonResponse);
      } else {
        throw Exception(
          'Failed to create journal: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error creating journal: $e');
    }
  }

  // Legacy methods
  Future<void> saveJournals(List<Journal> journals) async {}

  Future<void> updateJournal(Journal journal) async {}

  Future<void> deleteJournal(String journalId) async {}

  Future<void> addEntryToJournal(String journalId, JournalEntry entry) async {
    try {
      final body = {"content": entry.content};

      final response = await http.post(
        Uri.parse('$_baseUrl/$journalId/page/entry'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to add entry: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error adding entry: $e');
    }
  }
}
