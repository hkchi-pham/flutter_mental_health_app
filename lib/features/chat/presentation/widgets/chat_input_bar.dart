import 'package:flutter/material.dart';

import 'chat_bubble.dart' show kSageGreen;

/// Bottom input bar for the chat screen (CHAT-05).
///
/// Contains a multiline [TextField] (minLines 1, maxLines 4) and a send
/// [IconButton]. Behaviour:
///   - Enter key inserts a newline ([TextInputAction.newline]); there is NO
///     send-on-enter — sending happens via the button only.
///   - The send button is visually dimmed and disabled when [!enabled] OR
///     when the trimmed text is empty (one-question-one-answer rule).
///   - On send: [onSend] is called with the trimmed text and the field is
///     cleared. Leading/trailing whitespace is stripped before the call.
///
/// [enabled] should be set to `!ChatProvider.sending` so the bar is blocked
/// while Komo is composing a reply.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.enabled,
    required this.onSend,
  });

  /// Whether the input and send button are interactive.
  ///
  /// Pass `!ChatProvider.sending` here to enforce the one-question-one-answer
  /// flow (CHAT-05).
  final bool enabled;

  /// Called with the trimmed message text when the user taps the send button.
  final ValueChanged<String> onSend;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.enabled && _hasText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(
            color: kSageGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: kSageGreen.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  // Enter inserts a newline — NOT a send action (CHAT-05).
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF3D3522),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhắn tin với Komo...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFF3D3522).withValues(alpha: 0.45),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Send button
            AnimatedOpacity(
              opacity: canSend ? 1.0 : 0.35,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: canSend ? _handleSend : null,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: canSend
                        ? const Color(0xFF6B8E5A)
                        : const Color(0xFF6B8E5A).withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
