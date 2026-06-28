/// Immutable domain model for a chat conversation.
///
/// The [title] is derived client-side from the first user message stored in
/// [ChatFirstMessageStore] — it is NOT returned by the backend list endpoint.
/// A null [title] means no first message has been recorded yet (the UI should
/// fall back to a default label such as 'Cuộc trò chuyện').
///
/// HIST-03: [deriveTitle] is the single truncation contract used by
/// [ChatRepository.listConversations] and by the provider when a new first
/// message is sent.
class Conversation {
  const Conversation({
    required this.id,
    required this.persona,
    required this.createdAt,
    this.title,
  });

  /// Server-assigned conversation id (UUID string).
  final String id;

  /// Bot persona for this conversation (e.g. 'komo').
  final String persona;

  /// When this conversation was created on the server.
  final DateTime createdAt;

  /// Display title derived from the first user message.
  ///
  /// Null until [ChatFirstMessageStore] has recorded a first message for this
  /// conversation.
  final String? title;

  /// Returns a copy with the supplied fields replaced.
  Conversation copyWith({
    String? id,
    String? persona,
    DateTime? createdAt,
    String? title,
  }) =>
      Conversation(
        id: id ?? this.id,
        persona: persona ?? this.persona,
        createdAt: createdAt ?? this.createdAt,
        title: title ?? this.title,
      );

  /// Derives a display title from [firstUserMessage].
  ///
  /// Trims whitespace, then truncates to at most 30 characters, appending '…'
  /// when the original (trimmed) text is longer.
  ///
  /// Contract shared by AI-01 / HIST-03 / MOOD-04 — do not inline or duplicate.
  static String deriveTitle(String firstUserMessage) {
    final trimmed = firstUserMessage.trim();
    if (trimmed.length <= 30) return trimmed;
    return '${trimmed.substring(0, 30)}…';
  }

  @override
  String toString() =>
      'Conversation(id: $id, persona: $persona, title: $title)';
}
