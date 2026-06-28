import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed store for per-conversation first user message text.
///
/// WHY THIS EXISTS: the backend GET /conversations/ list call returns only
/// `{id, user_id, persona, created_at, ...}` — NO message content. Two
/// downstream features need the first user message text at list time:
///
///   - HIST-03: Conversation title derived from the first user message via
///     [Conversation.deriveTitle].
///   - MOOD-04: Mood recovery for an existing conversation (the mood
///     is embedded as a prepend sentence in the first user message content).
///
/// This store is written once per conversation at first send (see
/// [ChatRepository.saveFirstMessage]), and read at list time (see
/// [ChatRepository.listConversations]). It avoids an N+1 per-conversation
/// message fetch.
///
/// Mirrors [JournalCacheStore] style.
class ChatFirstMessageStore {
  static const String _key = 'chat_first_messages_v1';

  /// Returns the full map of `{conversationId: firstUserMessageText}`.
  ///
  /// Returns an empty map on cache miss or corrupt data.
  Future<Map<String, String>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.cast<String, String>();
      }
      return {};
    } catch (_) {
      // Corrupt data — treat as empty.
      return {};
    }
  }

  /// Records [firstMessage] for [conversationId] if not already stored.
  ///
  /// This method is a no-op when [conversationId] already has an entry — the
  /// first message must remain the first (idempotent, safe to call on every
  /// send attempt).
  Future<void> save(String conversationId, String firstMessage) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await readAll();
    if (current.containsKey(conversationId)) return; // already stored
    current[conversationId] = firstMessage;
    await prefs.setString(_key, jsonEncode(current));
  }

  /// Removes the stored first message for [conversationId].
  ///
  /// Called when a conversation is deleted so stale titles / mood entries
  /// do not linger.
  Future<void> remove(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await readAll();
    if (!current.containsKey(conversationId)) return;
    current.remove(conversationId);
    await prefs.setString(_key, jsonEncode(current));
  }

  /// Clears all stored first messages (e.g. on logout or hard reset).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
