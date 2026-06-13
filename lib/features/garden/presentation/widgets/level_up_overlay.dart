import 'package:flutter/material.dart' hide Badge;
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/garden_model.dart';

/// Full-screen badge celebration overlay shown when a tree levels up.
///
/// Auto-animates in (2000ms) and calls [onDismiss] on completion.
/// Tapping anywhere also dismisses early.
class LevelUpOverlay extends StatefulWidget {
  final Badge badge;
  final String treeName;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.badge,
    required this.treeName,
    required this.onDismiss,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  // Background dark overlay fades in
  late Animation<double> _bgOpacity;
  // Badge icon scales up with elastic overshoot
  late Animation<double> _badgeScale;
  // Text fades in
  late Animation<double> _textOpacity;
  // Everything fades out at the end
  late Animation<double> _fadeOut;

  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _bgOpacity = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2),
      ),
    );

    _badgeScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.5, curve: Curves.elasticOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6),
      ),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_dismissed) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss();
  }

  Color _badgeColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFFCD7F32); // bronze
      case 2:
        return const Color(0xFFC0C0C0); // silver
      case 3:
        return const Color(0xFFFFD700); // gold
      default:
        return const Color(0xFF00BCD4); // diamond-blue for level 4+
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor(widget.badge.treeLevel);
    final treeType = TreeType.values.firstWhere(
      (t) => t.name == widget.badge.treeType,
      orElse: () => TreeType.sakura,
    );
    final treeName = widget.treeName.isEmpty
        ? widget.badge.treeType
        : widget.treeName[0].toUpperCase() + widget.treeName.substring(1);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final overallOpacity = _fadeOut.value;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismiss,
          child: Opacity(
            opacity: overallOpacity,
            child: Stack(
              children: [
                // Dark background
                Opacity(
                  opacity: _bgOpacity.value,
                  child: Container(
                    color: Colors.black,
                  ),
                ),

                // Centered content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge icon with scale animation
                      Transform.scale(
                        scale: _badgeScale.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: badgeColor.withAlpha(30),
                            border: Border.all(color: badgeColor, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withAlpha(100),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              badgeAssetPath(treeType, widget.badge.treeLevel),
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.emoji_events,
                                size: 64,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Level text
                      Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            Text(
                              'Level ${widget.badge.treeLevel} Reached!',
                              style: GoogleFonts.quintessential(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                    color: Colors.black.withAlpha(180),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              treeName,
                              style: GoogleFonts.quintessential(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: badgeColor,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 4,
                                    color: Colors.black.withAlpha(150),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to continue',
                              style: GoogleFonts.quintessential(
                                fontSize: 13,
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
