import 'package:flutter/material.dart';

/// Full-screen background image, rendered edge-to-edge with [BoxFit.cover] and
/// [child] content layered on top.
///
/// This is the single, shared pattern for every full-bleed screen background
/// (splash, auth, and the upcoming journal / chat screens). The image ALWAYS
/// fills the screen and is NEVER given a fixed width/height — `BoxFit.cover`
/// crops the (square) source art to whatever aspect ratio the device window
/// happens to be:
///   • Phone 9:16   → crops left/right, full height shown
///   • iPad 3:4     → light top/bottom crop
///   • Laptop 16:9  → more top/bottom crop, content stays centred
///
/// The garden screen is intentionally NOT built on this widget — its background
/// is a horizontally-scrolling panorama with bespoke grid math.
///
/// [fallbackColor] is shown if the asset fails to load (errorBuilder), matching
/// the graceful-degradation pattern used across the app.
class ScreenBackground extends StatelessWidget {
  const ScreenBackground({
    super.key,
    required this.asset,
    required this.child,
    this.fallbackColor = const Color(0xFF6B8E5A),
  });

  /// Asset path of the full-screen background image.
  final String asset;

  /// Content layered on top of the background.
  final Widget child;

  /// Solid colour shown if [asset] cannot be loaded.
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(color: fallbackColor),
        ),
        child,
      ],
    );
  }
}
