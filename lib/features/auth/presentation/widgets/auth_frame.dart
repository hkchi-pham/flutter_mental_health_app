import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/screen_background.dart';

/// Full-screen auth scaffold that wraps any form child in the branded
/// PNG-frame aesthetic used throughout Soul Garden (info popup, badge popup).
///
/// Layout (top to bottom inside a scrollable column):
///   1. Full-bleed background image (`auth_screen_background.png`) — errorBuilder
///      falls back to a solid green container.
///   2. SafeArea + SingleChildScrollView so the keyboard never covers the
///      submit button (CONTEXT requirement).
///   3. Branded header: "Soul Garden" wordmark logo (`app_icon_@3x.png`).
///   4. Framed form panel: PNG frame (`auth_frame_@3x.png`) with [child] inset
///      inside. [title] renders as a section heading above the fields.
///
/// When [onBack] is provided, a brown leaf-arrow back button (`back_icon_@3x.png`)
/// floats at the top-left — used by the register screen to return to login.
class AuthFrame extends StatelessWidget {
  const AuthFrame({
    super.key,
    required this.child,
    required this.title,
    this.onBack,
  });

  final Widget child;
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Full-bleed background — full-screen BoxFit.cover via the shared
      //    ScreenBackground pattern; falls back to solid green if asset missing.
      body: ScreenBackground(
        asset: 'assets/screens/auth_screen_background.png',
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 2. Scrollable content — keyboard-safe
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 3. Branded header
                    const _AuthHeader(),
                    const SizedBox(height: 20),

                    // 4. Framed form panel
                    _FramedPanel(title: title, child: child),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Optional back button (register → login)
            if (onBack != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, top: 4),
                    child: _BackButton(onTap: onBack!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    // "Soul Garden" wordmark logo — scales with available band width so it
    // looks correct on narrow phones (375 px) and the 500 px band on wide
    // screens.  LayoutBuilder reads the constrained width (not raw window).
    // 0.50 * 375 = 187 px; 0.50 * 500 = 250 px → clamped to 220 px max.
    // BoxFit.contain: correct per per-type rules for logos/icons.
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoWidth =
            (constraints.maxWidth * 0.50).clamp(150.0, 220.0);
        return SizedBox(
          width: logoWidth,
          child: Image.asset(
            'assets/ui_icons/icons/app_icon_@3x.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Text(
              'Soul Garden',
              style: GoogleFonts.quintessential(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2F6B2E),
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          'assets/ui_icons/icons/back_icon_@3x.png',
          width: 44,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF2F3E2E),
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _FramedPanel extends StatelessWidget {
  const _FramedPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // PNG frame — errorBuilder: cream rounded container with border.
        // BoxFit.contain: correct per per-type rules for frame/card assets
        // (preserves aspect ratio; auth_frame_@3x.png is classified as a
        // frame/card, not a full-screen background or button).
        Positioned.fill(
          child: Image.asset(
            'assets/ui_icons/frames/auth_frame_@3x.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFCFBF5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFAED06F),
                  width: 2,
                ),
              ),
            ),
          ),
        ),

        // Content inset inside the frame — extra top padding clears the
        // decorative leaf corners; horizontal padding clears the green border.
        Padding(
          padding: const EdgeInsets.only(
            left: 32,
            right: 32,
            top: 52,
            bottom: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.quintessential(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2F6B2E),
                ),
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ],
    );
  }
}
