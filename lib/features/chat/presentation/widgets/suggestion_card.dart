import 'package:flutter/material.dart';

import '../../data/models/action_recommendation.dart';
import 'chat_bubble.dart' show kChatCream, kSageGreen;

/// A tap-to-expand framed card rendered under Komo's bot bubble whenever the
/// backend provides an [ActionRecommendation] alongside the AI reply.
///
/// Layout mirrors [MoodCheckCard]:
///   - [Positioned.fill] [Image.asset] frame PNG as background.
///   - [errorBuilder] fallback: cream [Container] with sage border (radius 16)
///     so the card renders correctly before the PNG asset exists.
///   - Foreground: type icon + activity name (bold) row, description line,
///     tap-to-expand [promptTemplate] steps via [AnimatedCrossFade].
///
/// Left-aligned with an avatar-width inset to sit under Komo's bubble.
/// Width is capped to 360 px (matching the bubble [maxWidth]) so the card
/// never stretches wider than the bubbles on wide screens.
class SuggestionCard extends StatefulWidget {
  const SuggestionCard({super.key, required this.recommendation});

  final ActionRecommendation recommendation;

  @override
  State<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<SuggestionCard> {
  bool _expanded = false;

  // ---------------------------------------------------------------------------
  // Type icon mapping
  // ---------------------------------------------------------------------------

  IconData _iconForType(String? type) {
    switch (type) {
      case 'tip':
        return Icons.lightbulb_outline;
      case 'exercise':
        return Icons.self_improvement;
      case 'question':
        return Icons.help_outline;
      default:
        return Icons.spa;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final hasPrompt =
        rec.promptTemplate != null && rec.promptTemplate!.trim().isNotEmpty;
    final hasDescription =
        rec.description != null && rec.description!.trim().isNotEmpty;

    return Padding(
      // Left inset: 12 (bubble h-pad) + 32 (avatar) + 6 (gap) = 50 px so
      // the card left-edge aligns with the bubble text area.
      padding: const EdgeInsets.only(left: 50, right: 12, top: 4, bottom: 4),
      child: GestureDetector(
        onTap: hasPrompt
            ? () => setState(() => _expanded = !_expanded)
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Stack(
            children: [
              // Frame background — framed cream/sage with errorBuilder fallback.
              Positioned.fill(
                child: Image.asset(
                  'assets/ui_icons/frames/suggestion_card_@3x.png',
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
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name row: type icon + activity name.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          _iconForType(rec.type),
                          size: 18,
                          color: const Color(0xFF6B8E5A),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rec.name ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3D3522),
                              height: 1.3,
                            ),
                          ),
                        ),
                        // Chevron affordance — only shown when promptTemplate exists.
                        if (hasPrompt)
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.expand_more,
                              size: 18,
                              color: Color(0xFF8B6F47),
                            ),
                          ),
                      ],
                    ),
                    // Description line.
                    if (hasDescription) ...[
                      const SizedBox(height: 6),
                      Text(
                        rec.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B6F47),
                          height: 1.4,
                        ),
                      ),
                    ],
                    // Expandable prompt_template steps.
                    if (hasPrompt)
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: _expanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(
                                color: kSageGreen.withValues(alpha: 0.4),
                                thickness: 1,
                                height: 1,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                rec.promptTemplate!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF3D3522),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
