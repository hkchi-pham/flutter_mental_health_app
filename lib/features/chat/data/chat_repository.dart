import 'models/chat_message.dart';
import 'models/conversation.dart';
import 'remote/chat_remote_data_source.dart';
import 'cache/chat_first_message_store.dart';

/// Repository for the Chat feature — maps DTOs to domain models and owns the
/// first-message persistence layer.
///
/// CONTRACT:
///   - All reads are live (no full offline cache this phase — that is Phase 14).
///   - The [ChatFirstMessageStore] is the ONLY local persistence in Phase 12.
///     It backs HIST-03 (conversation titles) and MOOD-04 (mood recovery) by
///     storing the first user message text per conversation at first send.
///   - A failed [sendChat] raises [ApiException], which the UI catches for the
///     AI-03 error/retry row.
///
/// Mirrors the structure of [JournalRepository].
class ChatRepository {
  ChatRepository(
    this._remote, [
    ChatFirstMessageStore? firstMessageStore,
  ]) : _firstMessageStore = firstMessageStore ?? ChatFirstMessageStore();

  final ChatRemoteDataSource _remote;
  final ChatFirstMessageStore _firstMessageStore;

  // ---------------------------------------------------------------------------
  // Conversation operations
  // ---------------------------------------------------------------------------

  /// Returns the user's conversation list with titles derived from the
  /// first-message store (HIST-03).
  ///
  /// The backend list call returns NO message content, so titles come from
  /// [ChatFirstMessageStore.readAll]. Conversations with no stored first message
  /// keep [Conversation.title] == null; the UI falls back to a default label.
  ///
  /// HIST-01: list all conversations.
  Future<List<Conversation>> listConversations() async {
    final dtos = await _remote.listConversations();
    final conversations = dtos.map((dto) => dto.toLocal()).toList();

    // Read the first-message map once (not N times) and derive titles.
    // HIST-03 + MOOD-04: both title and mood recovery use the same stored string.
    final firstMessages = await _firstMessageStore.readAll();
    return conversations.map((conv) {
      final stored = firstMessages[conv.id];
      if (stored == null || stored.isEmpty) return conv;
      return conv.copyWith(title: Conversation.deriveTitle(stored));
    }).toList();
  }

  /// Creates a new conversation and returns its server-assigned id.
  ///
  /// The backend POST /conversations/ response contains no id — we recover it
  /// via a follow-up list call (see [ChatRemoteDataSource.createConversation]).
  ///
  /// HIST-02: create conversation.
  Future<String> createConversation() => _remote.createConversation();

  /// Loads all messages for [conversationId] in chronological (backend) order.
  ///
  /// HIST-04: load conversation messages.
  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    final dtos = await _remote.loadMessages(conversationId);
    return dtos.map((dto) => dto.toLocal()).toList();
  }

  /// Sends [content] to the AI and returns the bot's reply text.
  ///
  /// AI-01: the AI runs entirely on the backend. The frontend sends the user's
  /// message and receives only the reply string — no AI logic in the client.
  ///
  /// AI-03: lets [ApiException] propagate so the UI can display an error/retry
  /// row without the repository swallowing the failure.
  Future<String> sendChat({
    required String conversationId,
    required String content,
  }) =>
      _remote.sendChat(conversationId: conversationId, content: content);

  /// Deletes [conversationId] remotely and removes its stored first message so
  /// stale titles / mood entries do not persist after deletion.
  ///
  /// HIST-05: delete conversation.
  Future<void> deleteConversation(String id) async {
    await _remote.deleteConversation(id);
    await _firstMessageStore.remove(id);
  }

  // ---------------------------------------------------------------------------
  // First-message persistence (HIST-03 / MOOD-04 contract)
  // ---------------------------------------------------------------------------

  /// Persists [firstMessage] for [conversationId] if not already stored.
  ///
  /// Called by the provider right after a new conversation's id is recovered on
  /// the first send. This is a no-op for repeat calls on the same id — the
  /// first message must remain the first.
  ///
  /// MOOD-03: the first message includes a mood-prepend sentence; storing it
  /// here enables MOOD-04 mood recovery without a per-conversation message fetch.
  Future<void> saveFirstMessage(
    String conversationId,
    String firstMessage,
  ) =>
      _firstMessageStore.save(conversationId, firstMessage);

  /// Returns the full `{conversationId: firstUserMessageText}` map.
  ///
  /// The provider uses this to recover BOTH the conversation title (HIST-03)
  /// AND the embedded mood string (MOOD-04) from the SAME stored text, without
  /// an extra message fetch per conversation.
  Future<Map<String, String>> firstMessages() =>
      _firstMessageStore.readAll();
}
