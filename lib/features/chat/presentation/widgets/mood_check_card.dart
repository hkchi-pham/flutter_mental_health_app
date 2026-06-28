import 'package:flutter/material.dart';

import '../../logic/mood.dart';
import 'chat_bubble.dart' show kChatCream, kSageGreen;

// ---------------------------------------------------------------------------
// MoodCheckCard
// ---------------------------------------------------------------------------

/// The mood-selection card shown as the first item in the chat scroll list
/// when a new conversation is started (MOOD-01).
///
/// Renders the mood_check_card_@3x.png frame as a background with the prompt
/// "Hôm nay bạn cảm thấy thế nào?" and a [Wrap] of 7 tappable mood options
/// (all 7 always visible — no internal scroll, MOOD-02).
///
/// Tapping a mood calls [onSelect] which the parent should route to
/// [ChatProvider.selectMood].
class MoodCheckCard extends StatelessWidget {
  const MoodCheckCard({super.key, required this.onSelect});

  /// Called when the user selects a mood.
  final ValueChanged<Mood> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Stack(
        children: [
          // Card frame background
          Positioned.fill(
            child: Image.asset(
              'assets/ui_icons/frames/mood_check_card_@3x.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, _) => Container(
                decoration: BoxDecoration(
                  color: kChatCream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kSageGreen, width: 1.5),
                ),
              ),
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hôm nay bạn cảm thấy thế nào?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D3522),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: Mood.values.map((mood) {
                    return _MoodOption(mood: mood, onTap: () => onSelect(mood));
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MoodChip
// ---------------------------------------------------------------------------

/// The collapsed mood chip shown after the user selects a mood (MOOD-04).
///
/// Displays a small pill with the mood icon + label. Tapping reopens the full
/// mood-check card via [onTap] (routes to [ChatProvider.reopenMoodCard]).
class MoodChip extends StatelessWidget {
  const MoodChip({super.key, required this.mood, required this.onTap});

  final Mood mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kSageGreen.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kSageGreen, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MoodIcon(mood: mood, size: 20),
              const SizedBox(width: 6),
              Text(
                mood.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2E5232),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// One tappable mood option in the [MoodCheckCard] — icon above label.
class _MoodOption extends StatelessWidget {
  const _MoodOption({required this.mood, required this.onTap});

  final Mood mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MoodIcon(mood: mood, size: 40),
            const SizedBox(height: 4),
            Text(
              mood.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF3D3522),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mood icon — uses the image asset when available, falls back to a tinted
/// [Icons.sentiment_neutral] Material icon for [Mood.normal] (no asset).
class _MoodIcon extends StatelessWidget {
  const _MoodIcon({required this.mood, required this.size});

  final Mood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = mood.iconAsset;
    if (asset == null) {
      // Mood.normal has no image asset — render a neutral Material icon (CONTEXT decision).
      return Icon(
        Icons.sentiment_neutral,
        size: size,
        color: const Color(0xFF6B8E5A),
      );
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, _) => Icon(
        Icons.sentiment_neutral,
        size: size,
        color: const Color(0xFF6B8E5A),
      ),
    );
  }
}
