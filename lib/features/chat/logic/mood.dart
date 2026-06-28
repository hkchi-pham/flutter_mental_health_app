/// Mood model and helpers for the AI chat feature.
///
/// ASSET AVAILABILITY (updated):
/// All six moods now have image assets in `assets/ui_icons/icons/`. The
/// `mood_normal_icon_@3x.png` asset was added in the gap-closure pass (12-05),
/// so [Mood.normal.iconAsset] now returns a real path. The UI's errorBuilder
/// keeps `Icons.sentiment_neutral` as a graceful fallback.
///
/// BACKEND ALIGNMENT (gap-closure 12-05):
/// The backend EMOTION_ANALYSIS_PROMPT uses exactly these six Vietnamese
/// category tokens: `vui`, `buồn`, `lo_lắng`, `tức_giận`, `mệt_mỏi`,
/// `bình_thường`. [moodWord] values now match (with spaces instead of
/// underscores, matching the prependSentence format the backend parses).
/// `Mood.calm` was removed — the backend has no "calm" category.
///
/// FIRST-MESSAGE PERSISTENCE SOURCE:
/// [moodFromFirstMessage] is the SINGLE mood-recovery helper. Both
/// [ChatProvider.openConversation] and the title-derivation path consume the
/// SAME stored first-message string — no separate fetch needed (MOOD-04).
library;

/// The six moods a user can select before starting a chat.
///
/// Aligned to the backend's six emotion categories. "Bình tĩnh" (calm) was
/// removed because the backend has no matching category — conversations where
/// calm was previously selected will simply show no mood chip on re-open.
enum Mood {
  /// Vui / happy — asset: mood_happy_icon_@3x.png
  happy,

  /// Bình thường / normal — asset: mood_normal_icon_@3x.png
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

  /// Relative path to the mood icon asset.
  ///
  /// All six moods now have assets. The [errorBuilder] in the UI still falls
  /// back to `Icons.sentiment_neutral` in case the file is missing at runtime.
  String get iconAsset {
    switch (this) {
      case Mood.happy:
        return 'assets/ui_icons/icons/mood_happy_icon_@3x.png';
      case Mood.normal:
        return 'assets/ui_icons/icons/mood_normal_icon_@3x.png';
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
  /// Values are aligned to the backend EMOTION_ANALYSIS_PROMPT categories
  /// (spaces replace underscores used in the backend token names):
  ///   vui, bình thường, buồn, lo lắng, tức giận, mệt mỏi
  ///
  /// Multi-word values are matched precisely in [moodFromFirstMessage] against
  /// the full [prependSentence] prefix to avoid mis-detection.
  String get moodWord {
    switch (this) {
      case Mood.happy:
        return 'vui';
      case Mood.normal:
        return 'bình thường';
      case Mood.sad:
        return 'buồn';
      case Mood.anxious:
        return 'lo lắng';
      case Mood.angry:
        return 'tức giận'; // backend: tức_giận
      case Mood.tired:
        return 'mệt mỏi'; // backend: mệt_mỏi
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
/// substring of moodWord) so that multi-word values like "bình thường" are not
/// shadowed by shorter words. Because enum order defines iteration order,
/// callers should not depend on tie-breaking (there are no overlapping
/// prefixes with the chosen sentences).
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
