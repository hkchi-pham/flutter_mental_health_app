import 'package:flutter/material.dart';

import 'chat_bubble.dart' show kSageGreen;

/// Bottom input bar for the chat screen (CHAT-05).
///
/// Contains a multiline [TextField] (minLines 1, maxLines 4) and a send
/// button rendered as a PNG asset. Behaviour:
///   - Enter key inserts a newline ([TextInputAction.newline]); there is NO
///     send-on-enter — sending happens via the button only.
///   - The send button switches between btn_send_@3x.png (active) and
///     btn_send_disable_@3x.png (inactive); falls back to an Icon if the
///     asset fails to load.
///   - On send: [onSend] is called with the trimmed text and the field is
///     cleared. Leading/trailing whitespace is stripped before the call.
///
/// [enabled] should be set to `!ChatProvider.sending` so the bar is blocked
/// while Komo is composing a reply.
///
/// Sizing scales with the available band width via [LayoutBuilder] so the
/// field and button look right on narrow phones and wider tablets.
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale send button with available width, clamped to a sensible range.
        final bandWidth = constraints.maxWidth;
        final btnSize = (bandWidth * 0.11).clamp(38.0, 52.0);
        // Font / vertical padding scale slightly on wider bands.
        final fontSize = (bandWidth * 0.038).clamp(13.0, 17.0);
        final vPad = (bandWidth * 0.022).clamp(8.0, 14.0);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: vPad),
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
                      style: TextStyle(
                        fontSize: fontSize,
                        color: const Color(0xFF3D3522),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhắn tin với Komo...',
                        hintStyle: TextStyle(
                          fontSize: fontSize,
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
                // Send button — PNG asset, falls back to Material icon.
                GestureDetector(
                  onTap: canSend ? _handleSend : null,
                  child: SizedBox(
                    width: btnSize,
                    height: btnSize,
                    child: Image.asset(
                      canSend
                          ? 'assets/ui_icons/icons/btn_send_@3x.png'
                          : 'assets/ui_icons/icons/btn_send_disable_@3x.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, _) => Container(
                        width: btnSize,
                        height: btnSize,
                        decoration: BoxDecoration(
                          color: canSend
                              ? const Color(0xFF6B8E5A)
                              : const Color(0xFF6B8E5A).withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: btnSize * 0.48,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
