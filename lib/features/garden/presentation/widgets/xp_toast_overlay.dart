import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Floating "+N XP" toast that appears near the top bar when XP is earned.
///
/// Slides up and fades out over 1500ms, then calls [onComplete].
class XpToastOverlay extends StatefulWidget {
  final int amount;
  final Offset position;
  final VoidCallback onComplete;

  const XpToastOverlay({
    super.key,
    required this.amount,
    required this.position,
    required this.onComplete,
  });

  @override
  State<XpToastOverlay> createState() => _XpToastOverlayState();
}

class _XpToastOverlayState extends State<XpToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideY;  // slide up in pixels
  late Animation<double> _fade;    // opacity fade out

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideY = Tween<double>(begin: 0.0, end: -40.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideY.value),
              child: Opacity(
                opacity: _fade.value,
                child: child,
              ),
            );
          },
          child: Text(
            '+${widget.amount} XP',
            style: GoogleFonts.quintessential(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFD700),
              shadows: const [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 4,
                  color: Colors.black54,
                ),
                Shadow(
                  offset: Offset(-1, -1),
                  blurRadius: 2,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
