import 'package:flutter/material.dart';

/// A curated set of common emojis for the in-app picker.
///
/// Intentionally a small, hand-picked list (~48) covering faces, hearts,
/// nature, weather, and activities — enough variety for journal notebooks
/// without depending on the OS emoji keyboard or an external package (which
/// is unreliable on Flutter web, the risk CONTEXT flags). An
/// `emoji_picker_flutter` package could replace this later, but this curated
/// grid is the autonomous, web-safe default.
const List<String> kJournalEmojis = [
  // Faces & feelings
  '😀', '😊', '😍', '🥰', '😎', '🤔', '😢', '😭',
  '😴', '🤗', '😌', '🥳',
  // Hearts
  '❤️', '🧡', '💛', '💚', '💙', '💜', '🤍', '💖',
  // Nature & plants
  '🌱', '🌿', '🍀', '🌳', '🌸', '🌻', '🌼', '🌹',
  '🍄', '🐝',
  // Sky & weather
  '☀️', '🌙', '⭐', '🌈', '☁️', '❄️', '🔥', '💧',
  // Activities & objects
  '📓', '✏️', '📖', '☕', '🎵', '🎨', '✨', '🎉',
  '🏆', '💡',
];

/// A self-contained, in-app emoji grid.
///
/// Renders [kJournalEmojis] as a scrollable grid of tappable cells. The
/// currently [selected] emoji (if any) is highlighted. Calling [onSelected]
/// reports the tapped emoji. Emoji glyphs use the default text style (NOT a
/// GoogleFont) so the platform's color emoji font renders them correctly.
class EmojiPickerGrid extends StatelessWidget {
  const EmojiPickerGrid({
    super.key,
    required this.onSelected,
    this.selected,
    this.crossAxisCount = 7,
  });

  /// Invoked with the tapped emoji.
  final ValueChanged<String> onSelected;

  /// The currently-selected emoji, highlighted in the grid.
  final String? selected;

  /// How many emojis per row.
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: kJournalEmojis.length,
      itemBuilder: (context, index) {
        final emoji = kJournalEmojis[index];
        final isSelected = emoji == selected;
        return GestureDetector(
          onTap: () => onSelected(emoji),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFD8C9A3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: const Color(0xFF8D6E63), width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              // Default style on purpose — keeps the platform emoji glyphs.
              style: const TextStyle(fontSize: 22),
            ),
          ),
        );
      },
    );
  }
}
