/// Mood model and helpers for the AI chat feature.
///
/// NEUTRAL FALLBACK DECISION (Claude's discretion, CONTEXT lines 39-42):
/// "Bình thường" (normal/neutral) has no image asset in
/// `assets/ui_icons/icons/`. [Mood.normal.iconAsset] returns `null`; the UI
/// renders a tinted `Icons.sentiment_neutral` Material icon instead of an
/// Image.asset. This keeps the UI honest about missing artwork rather than
/// silently reusing an unrelated icon.
///
/// FIRST-MESSAGE PERSISTENCE SOURCE:
/// [moodFromFirstMessage] is the SINGLE mood-recovery helper. Both
/// [ChatProvider.openConversation] and the title-derivation path consume the
/// SAME stored first-message string — no separate fetch needed (MOOD-04).

/// The seven moods a user can select before starting a chat.
///
/// Seven moods, six image assets — "Bình thường" (normal) has no asset and
/// renders a Material icon fallback in the UI.
enum Mood {
  /// Vui / happy — asset: mood_happy_icon_@3x.png
  happy,

  /// Bình tĩnh / calm — asset: mood_calm_icon_@3x.png
  calm,

  /// Bình thường / normal — NO image asset; UI uses Icons.sentiment_neutral.
  normal,

  /// Buồn / sad — asset: mood_sad_icon_@3x.png
  sad,

  /// Lo lắng / anxious — asset: mood_anxious_icon_@3x.png
  anxious,

  /// Giận / angry — asset: mood_angry_icon_@3x.png
  angry,

  /// Mệt / tired — asset: mood_tired_icon_@3x.png
  tired,
}

extension MoodExtension on Mood {
  /// Vietnamese display label shown in the mood-check card and pinned chip.
  String get label {
    switch (this) {
      case Mood.happy:
        return 'Vui';
      case Mood.calm:
        return 'Bình tĩnh';
      case Mood.normal:
        return 'Bình thường';
      case Mood.sad:
        return 'Buồn';
      case Mood.anxious:
        return 'Lo lắng';
      case Mood.angry:
        return 'Giận';
      case Mood.tired:
        return 'Mệt';
    }
  }

  /// Relative path to the mood icon asset, or `null` for [Mood.normal].
  ///
  /// When `null`, the UI should render `Icons.sentiment_neutral` tinted to the
  /// app's sage-green colour as a fallback (CONTEXT decision, no neutral asset).
  String? get iconAsset {
    switch (this) {
      case Mood.happy:
        return 'assets/ui_icons/icons/mood_happy_icon_@3x.png';
      case Mood.calm:
        return 'assets/ui_icons/icons/mood_calm_icon_@3x.png';
      case Mood.normal:
        return null; // No asset — UI uses Icons.sentiment_neutral
      case Mood.sad:
        return 'assets/ui_icons/icons/mood_sad_icon_@3x.png';
      case Mood.anxious:
        return 'assets/ui_icons/icons/mood_anxious_icon_@3x.png';
      case Mood.angry:
        return 'assets/ui_icons/icons/mood_angry_icon_@3x.png';
      case Mood.tired:
        return 'assets/ui_icons/icons/mood_tired_icon_@3x.png';
    }
  }

  /// Lowercase Vietnamese word used in the prepend sentence.
  ///
  /// Multi-word values (e.g. "bình tĩnh") are matched precisely in
  /// [moodFromFirstMessage] against the full [prependSentence] prefix to avoid
  /// mis-detection where a shorter word appears inside a longer one.
  String get moodWord {
    switch (this) {
      case Mood.happy:
        return 'vui';
      case Mood.calm:
        return 'bình tĩnh';
      case Mood.normal:
        return 'bình thường';
      case Mood.sad:
        return 'buồn';
      case Mood.anxious:
        return 'lo lắng';
      case Mood.angry:
        return 'giận';
      case Mood.tired:
        return 'mệt';
    }
  }

  /// The full sentence prepended to the user's first message when a mood is
  /// selected (MOOD-03).
  ///
  /// Format: `"Mình đang cảm thấy <moodWord>. "`
  /// The trailing space ensures the user's own text follows naturally.
  String get prependSentence => 'Mình đang cảm thấy $moodWord. ';
}

/// Inverse of [MoodExtension.prependSentence] — recovers a [Mood] from the
/// stored first user message string (MOOD-04).
///
/// This is the SINGLE mood-recovery source for existing conversations. Both
/// [ChatProvider.openConversation] and the fallback in-message parse call this
/// helper, drawing from the SAME first-message string that backs the
/// conversation title — no extra fetch required.
///
/// Algorithm:
///   1. Return `null` for null / empty / whitespace-only input.
///   2. Trim the input.
///   3. For each [Mood] (in enum declaration order), check whether the trimmed
///      text starts with that mood's [prependSentence]. Return the first match.
///   4. Return `null` when no mood prefix is found.
///
/// CORRECTNESS NOTE: We match the FULL prependSentence prefix (not a bare
/// substring of moodWord) so that multi-word values like "bình tĩnh" are not
/// shadowed by the shorter "bình thường" (or vice-versa). Because enum order
/// defines iteration order, callers should not depend on tie-breaking (there
/// are no overlapping prefixes with the chosen sentences).
Mood? moodFromFirstMessage(String? firstMessage) {
  if (firstMessage == null || firstMessage.trim().isEmpty) return null;
  final trimmed = firstMessage.trim();
  for (final mood in Mood.values) {
    // Match the full prepend sentence. We also accept the trimmed form of the
    // sentence so that a stored first message that was itself trimmed (e.g.
    // trailing space removed) is still correctly parsed.
    if (trimmed.startsWith(mood.prependSentence) ||
        trimmed.startsWith(mood.prependSentence.trimRight())) {
      return mood;
    }
  }
  return null;
}
