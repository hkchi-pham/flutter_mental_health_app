import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Branded loading screen shown during the cold-launch token restore.
///
/// Displays the garden background, the Soul Garden wordmark, and a subtle
/// [CircularProgressIndicator] so the user knows the app is starting up.
/// Shown for as long as [AuthRepository.restore] takes (typically < 300 ms).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed garden background — falls back to the brand green if the
          // asset is unavailable (errorBuilder pattern established across the app).
          Image.asset(
            'assets/screens/garden_background_@2x.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Color(0xFF6B8E5A),
            ),
          ),

          // Centred branding column
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App mark — a simple leaf / sprout icon that matches the
                // garden theme without requiring an external asset.
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),

                const SizedBox(height: 20),

                // "Soul Garden" wordmark
                Text(
                  'Soul Garden',
                  style: GoogleFonts.quintessential(
                    fontSize: 34,
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        color: Color(0x55000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Subtle spinner — small enough not to look alarming, visible
                // enough to communicate activity.
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
