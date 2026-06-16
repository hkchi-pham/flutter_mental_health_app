import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Branded loading screen shown during the cold-launch token restore.
///
/// Displays the dedicated splash background, the "Soul Garden" wordmark logo
/// (`app_icon_@3x.png`), and a subtle [CircularProgressIndicator] so the user
/// knows the app is starting up. Shown for as long as [AuthRepository.restore]
/// takes (typically < 300 ms).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed splash background — falls back to a sky blue if the
          // asset is unavailable (errorBuilder pattern used across the app).
          Image.asset(
            'assets/screens/splash_screen_background.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Color(0xFF8FC0E8),
            ),
          ),

          // Centred branding column
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Soul Garden" wordmark logo — title is baked into the asset.
                Image.asset(
                  'assets/ui_icons/icons/app_icon_@3x.png',
                  width: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Text(
                    'Soul Garden',
                    style: GoogleFonts.quintessential(
                      fontSize: 34,
                      color: const Color(0xFF2F6B2E),
                      shadows: const [
                        Shadow(
                          color: Color(0x55000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Subtle spinner — communicates activity without alarming.
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3E7D3A)),
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
