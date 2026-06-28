import '../models/chat_message.dart';

/// Snake_case DTO mirroring the backend [MessageRead] schema.
///
/// Backend shape: `{id, sender_id?, conversation_id, content, message_type}`.
///
/// Role mapping contract (AI-01):
/// - `message_type == 'ai'` → [ChatRole.bot]
/// - `sender_id == 'ai_assistant'` → [ChatRole.bot]
/// - Everything else → [ChatRole.user]
///
/// NOTE: [MessageRead] has NO `created_at` field. Preserve backend list order.
class MessageDto {
  MessageDto({
    required this.id,
    required this.senderId,
    required this.conversationId,
    required this.content,
    required this.messageType,
  });

  final String id;
  final String senderId;
  final String conversationId;
  final String content;

  /// Backend message_type: 'ai' for bot messages, 'text' for user messages.
  final String messageType;

  factory MessageDto.fromJson(Map<String, dynamic> json) => MessageDto(
        id: '${json['id'] ?? ''}',
        senderId: '${json['sender_id'] ?? ''}',
        conversationId: '${json['conversation_id'] ?? ''}',
        content: '${json['content'] ?? ''}',
        messageType: '${json['message_type'] ?? ''}',
      );

  /// Maps this DTO to the [ChatMessage] domain model.
  ///
  /// A message is a [ChatRole.bot] message when [messageType] is 'ai' OR
  /// [senderId] is 'ai_assistant'; otherwise it is a [ChatRole.user] message.
  ChatMessage toLocal() => ChatMessage(
        id: id,
        role: (messageType == 'ai' || senderId == 'ai_assistant')
            ? ChatRole.bot
            : ChatRole.user,
        content: content,
      );
}
