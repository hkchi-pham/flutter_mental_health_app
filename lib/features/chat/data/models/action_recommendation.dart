/// A curated activity recommended by the backend alongside a chat reply.
///
/// The backend's `/messages/chat` response includes an optional
/// `action_recommendation` object at the JSON root.  When present, it describes
/// a mindfulness activity (tip / exercise / question) that Komo suggests.
///
/// All fields are nullable to guard against partial backend payloads.
/// [name] is the only field that must be non-empty for the card to render
/// meaningfully, but we leave nullable-handling to the UI.
class ActionRecommendation {
  const ActionRecommendation({
    this.slug,
    this.name,
    this.description,
    this.type,
    this.promptTemplate,
  });

  /// Backend slug identifier for the action (e.g. `"lo_lang_bai_ho_hap"`).
  final String? slug;

  /// Human-readable activity name shown as the card title.
  final String? name;

  /// Short description shown beneath the name.
  final String? description;

  /// Activity category: `'tip'`, `'exercise'`, or `'question'`.
  final String? type;

  /// Step-by-step how-to text revealed when the card is expanded.
  final String? promptTemplate;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  /// Builds an [ActionRecommendation] from a JSON map using snake_case keys.
  ///
  /// Tolerates missing keys — any absent key is stored as `null`.
  factory ActionRecommendation.fromJson(Map<String, dynamic> json) {
    return ActionRecommendation(
      slug: json['slug'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      promptTemplate: json['prompt_template'] as String?,
    );
  }

  /// Returns `null` when [raw] is null, not a [Map], or is empty — so callers
  /// can do `ActionRecommendation.fromJsonOrNull(body['action_recommendation'])`
  /// and get back `null` instead of throwing.
  static ActionRecommendation? fromJsonOrNull(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    if (map.isEmpty) return null;
    return ActionRecommendation.fromJson(map);
  }

  @override
  String toString() =>
      'ActionRecommendation(slug: $slug, name: $name, type: $type)';
}

/// The structured result returned by [sendChat].
///
/// Pairs the AI reply text with an optional [ActionRecommendation] so the
/// provider can attach both to the bot [ChatMessage] in a single call.
class ChatSendResult {
  const ChatSendResult({
    required this.reply,
    this.recommendation,
  });

  /// The AI reply text (maps to `ai_response` in the backend response).
  final String reply;

  /// Optional activity recommendation (maps to `action_recommendation`).
  /// Null when the backend omitted or nulled the field.
  final ActionRecommendation? recommendation;
}
