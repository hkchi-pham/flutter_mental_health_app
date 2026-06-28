import '../models/conversation.dart';

/// Snake_case DTO mirroring the backend [ConversationResponse] schema.
///
/// Backend shape (GET /conversations/):
/// `{id, user_id, persona, created_at, updated_at?, ended_at?}`
///
/// NOTE: The backend does NOT return message content at list time, so [title]
/// is always left null here. It is derived later by [ChatRepository] from
/// [ChatFirstMessageStore] (see HIST-03).
///
/// NOTE: POST /conversations/ returns NO id in the body. Use [createJson]
/// to build the create payload; the caller must recover the id via a
/// follow-up list call (see [ChatRemoteDataSource.createConversation]).
class ConversationDto {
  ConversationDto({
    required this.id,
    required this.userId,
    required this.persona,
    required this.createdAt,
    this.updatedAt,
    this.endedAt,
  });

  final String id;
  final String userId;
  final String persona;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? endedAt;

  factory ConversationDto.fromJson(Map<String, dynamic> json) =>
      ConversationDto(
        id: '${json['id'] ?? ''}',
        userId: '${json['user_id'] ?? ''}',
        persona: '${json['persona'] ?? ''}',
        createdAt:
            DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse('${json['updated_at']}')
            : null,
        endedAt: json['ended_at'] != null
            ? DateTime.tryParse('${json['ended_at']}')
            : null,
      );

  /// Maps this DTO to the [Conversation] domain model.
  ///
  /// [title] is intentionally left null — it is set by [ChatRepository] from
  /// the first-message store (HIST-03).
  Conversation toLocal() => Conversation(
        id: id,
        persona: persona,
        createdAt: createdAt,
        title: null,
      );

  /// Returns the POST /conversations/ create payload.
  ///
  /// The router overrides `user_id` with the authenticated user, so we send an
  /// empty string. `persona` must be non-empty — we always use 'komo'.
  static Map<String, dynamic> createJson() => {
        'user_id': '',
        'persona': 'komo',
      };
}
