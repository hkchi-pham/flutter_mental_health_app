import '../../../shared/network/api_client.dart';
import '../dto/conversation_dto.dart';
import '../dto/message_dto.dart';
import '../models/action_recommendation.dart';

/// Thin wrapper over the Phase 12 backend's `/conversations` and `/messages`
/// endpoints.
///
/// All paths are relative to `/api/v1` (ApiClient prepends this automatically).
///
/// BACKEND QUIRKS (documented here so callers never explore the backend):
///
/// 1. GET /conversations/ returns 404 when the user has zero conversations —
///    mapped to an empty list (not an error). Same pattern for messages.
///
/// 2. POST /conversations/ returns NO id in the body:
///    `{"message": "...", "success": true}`. To recover the new conversation id
///    we immediately call [listConversations] and take the newest entry by
///    [createdAt] DESC — it is the just-created one.
///
/// 3. POST /messages/chat response is at the JSON ROOT (not under `data`).
///    The AI reply text is in `ai_response`.
///
/// Mirrors [JournalRemoteDataSource] in structure.
class ChatRemoteDataSource {
  ChatRemoteDataSource(this._client);

  final ApiClient _client;

  /// GET /conversations/ — returns the user's conversation list.
  ///
  /// A 404 (zero conversations) is mapped to an empty list (HIST-01).
  Future<List<ConversationDto>> listConversations() async {
    try {
      final body = await _client.get('/conversations/');
      final data = (body is Map ? body['data'] : null) as List? ?? const [];
      return data
          .map((e) => ConversationDto.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// POST /conversations/ — creates a new conversation and returns its id.
  ///
  /// WHY: The backend POST response contains no id. We recover the new id by
  /// immediately calling [listConversations] and taking the newest conversation
  /// by [createdAt] DESC. This is the only safe approach given the current
  /// backend contract.
  ///
  /// Throws [ApiException(500, ...)] defensively if the list is empty after
  /// creation (should never happen in practice).
  Future<String> createConversation() async {
    // Backend overrides user_id with the auth user; persona must be non-empty.
    await _client.post('/conversations/', body: ConversationDto.createJson());

    // Recover the newly created conversation's id.
    final list = await listConversations();
    if (list.isEmpty) {
      throw ApiException(500, 'createConversation: list empty after create');
    }
    // The newest conversation (highest createdAt) is the one just created.
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.first.id;
  }

  /// GET /messages/conversation/{conversationId} — loads messages for a
  /// conversation in backend (chronological) order.
  ///
  /// A 404 (zero messages) is mapped to an empty list (HIST-04).
  Future<List<MessageDto>> loadMessages(String conversationId) async {
    try {
      final body =
          await _client.get('/messages/conversation/$conversationId');
      final data = (body is Map ? body['data'] : null) as List? ?? const [];
      return data
          .map((e) => MessageDto.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// POST /messages/chat — sends a user message and returns a [ChatSendResult].
  ///
  /// AI-01: The AI logic runs entirely on the backend. The frontend sends the
  /// user's message content and receives the bot's reply text in `ai_response`
  /// plus an optional `action_recommendation` object.
  ///
  /// IMPORTANT: The [AIChatResponse] is at the JSON ROOT — NOT under `data`.
  ///
  /// Lets [ApiException] propagate so the UI can surface an error/retry row
  /// (AI-03).
  Future<ChatSendResult> sendChat({
    required String conversationId,
    required String content,
  }) async {
    final body = await _client.post('/messages/chat', body: {
      'conversation_id': conversationId,
      'content': content,
      'message_type': 'text',
    });
    // Response is at the JSON root — NOT under body['data'].
    final reply = '${(body is Map ? body['ai_response'] : null) ?? ''}';
    final recommendation =
        ActionRecommendation.fromJsonOrNull(body is Map ? body['action_recommendation'] : null);
    return ChatSendResult(reply: reply, recommendation: recommendation);
  }

  /// DELETE /conversations/{id} — deletes a conversation.
  Future<void> deleteConversation(String id) =>
      _client.delete('/conversations/$id');
}
