import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chat_bubble.dart' show kChatCream, kSageGreen, KomoAvatar;

/// Animated 3-dot typing indicator shown while Komo is composing a reply (AI-02).
///
/// Rendered inside a bot-style cream bubble with the Komo avatar to the left —
/// visually occupying exactly the position where the bot reply will appear.
///
/// Animation: three dots stagger their opacity and slight vertical scale on a
/// repeating 1.2-second [AnimationController]. The controller is disposed in
/// [dispose] to prevent leaks.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Three staggered opacity animations, each occupying a 0.6-wide interval
  /// within [0, 1] with a 0.2 offset between dots so they cascade.
  late final List<Animation<double>> _opacities;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _opacities = List.generate(3, (i) {
      final start = i * 0.2;
      final end = math.min(start + 0.6, 1.0);
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.3, end: 1.0),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.3),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const KomoAvatar(size: 32),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kChatCream,
              border: Border.all(color: kSageGreen, width: 1.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _opacities[i],
                  builder: (context, child) {
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      child: Opacity(
                        opacity: _opacities[i].value,
                        child: child,
                      ),
                    );
                  },
                  child: const _Dot(),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF6B8E5A),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
