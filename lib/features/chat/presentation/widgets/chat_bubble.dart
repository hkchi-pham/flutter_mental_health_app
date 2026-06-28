import 'package:flutter/material.dart';

import '../../data/models/chat_message.dart';

/// Sage-green colour for user chat bubbles and UI accents.
const Color kSageGreen = Color(0xFFA5D6A7);

/// Cream colour for bot chat bubbles — matches [kPaperCream] in ruled_paper_painter.
const Color kChatCream = Color(0xFFFFF8E7);

/// A single chat message bubble.
///
/// User messages (role == [ChatRole.user]) appear right-aligned with a
/// sage-green (#A5D6A7) bubble.
///
/// Bot messages (role == [ChatRole.bot]) appear left-aligned with a cream
/// (#FFF8E7) bubble + sage-green border and a small circular Komo avatar to
/// the left.
///
/// All styling is code-built (Container + BoxDecoration — no image bubble
/// bodies) per CHAT-03.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: message.role == ChatRole.user
          ? _UserBubble(content: message.content)
          : _BotBubble(content: message.content),
    );
  }
}

// ---------------------------------------------------------------------------
// User bubble
// ---------------------------------------------------------------------------

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.75,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: kSageGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    // Tighter bottom-right gives a chat-tail feel.
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Color(0xFF2E5232),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bot bubble
// ---------------------------------------------------------------------------

class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Small circular Komo avatar
            _KomoAvatar(size: 32),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.75,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kChatCream,
                  border: Border.all(
                    color: kSageGreen,
                    width: 1.5,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    // Tighter bottom-left gives a chat-tail feel.
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Color(0xFF3D3522),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Komo avatar widget (used here and in TypingIndicator)
// ---------------------------------------------------------------------------

/// Small circular Komo avatar — used by bot bubbles and the typing indicator.
class _KomoAvatar extends StatelessWidget {
  const _KomoAvatar({this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/ui_icons/icons/komo_avatar_@3x.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, _) => CircleAvatar(
          radius: size / 2,
          backgroundColor: kSageGreen,
          child: Icon(
            Icons.smart_toy,
            size: size * 0.55,
            color: const Color(0xFF2E5232),
          ),
        ),
      ),
    );
  }
}

// Export _KomoAvatar for use by TypingIndicator.
// (Exported via a named typedef so typing_indicator.dart can import it without
// reaching into private internals — defined below as a top-level.)

/// Public alias that allows [typing_indicator.dart] to embed the Komo avatar
/// without duplicating the asset path or fallback logic.
class KomoAvatar extends StatelessWidget {
  const KomoAvatar({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => _KomoAvatar(size: size);
}
