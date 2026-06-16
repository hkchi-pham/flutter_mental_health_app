import 'package:flutter/material.dart';

/// Primary auth action button rendered from the branded PNG pill
/// (`btn_login_register_@3x.png`) with a pressed-state swap
/// (`btn_login_register_pressed_@3x.png`).
///
/// The PNG ships with no baked-in text, so [label] is overlaid centred. While
/// [submitting] is true (or [onTap] is null) the button is disabled, dimmed,
/// and — when submitting — shows a spinner in place of the label.
class AuthButton extends StatefulWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onTap,
    this.submitting = false,
  });

  final String label;

  /// Tap handler. When null the button renders disabled (dimmed, inert).
  final VoidCallback? onTap;

  /// When true the button shows a spinner and ignores taps.
  final bool submitting;

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null && !widget.submitting;

  void _setPressed(bool value) {
    if (!_enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final asset = _pressed
        ? 'assets/ui_icons/icons/btn_login_register_pressed_@3x.png'
        : 'assets/ui_icons/icons/btn_login_register_@3x.png';

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _enabled ? widget.onTap : null,
      child: Opacity(
        opacity: _enabled ? 1.0 : 0.55,
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Branded pill — errorBuilder falls back to a styled green button.
              Positioned.fill(
                child: Image.asset(
                  asset,
                  fit: BoxFit.fill,
                  errorBuilder: (_, _, _) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B8E5A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              if (widget.submitting)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
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
