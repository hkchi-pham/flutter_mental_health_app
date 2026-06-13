import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Floating toast that announces tree wilt events near the top of the screen.
///
/// Mirrors the timing and motion of [XpToastOverlay] (1500ms slide up 40px +
/// fade out) but uses a muted earthy palette and a free-form [message] string
/// so it can carry batched copy like "3 trees wilted away".
///
/// Intentionally a sibling widget rather than a generalization of
/// XpToastOverlay — see RESEARCH §7 — so that future style tweaks to either
/// toast cannot regress the other.
class TreeDeathToastOverlay extends StatefulWidget {
  final String message;
  final Offset position;
  final VoidCallback onComplete;

  const TreeDeathToastOverlay({
    super.key,
    required this.message,
    required this.position,
    required this.onComplete,
  });

  @override
  State<TreeDeathToastOverlay> createState() => _TreeDeathToastOverlayState();
}

class _TreeDeathToastOverlayState extends State<TreeDeathToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -40),
    ).animate(
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

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });

    _controller.forward();
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
          builder: (context, _) {
            return Transform.translate(
              offset: _slide.value,
              child: Opacity(
                opacity: _fade.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.message,
                    style: GoogleFonts.quintessential(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      // Muted earthy green — distinguishable from the gold
                      // "+N XP" toast so the two notifications read as
                      // different events.
                      color: const Color(0xFFB5C9A8),
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
