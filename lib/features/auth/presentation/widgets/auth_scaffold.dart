import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/screen_background.dart';

/// Frameless auth scaffold — replaces the retired `AuthFrame`.
///
/// Layout (top to bottom inside a scrollable, keyboard-safe column):
///   1. Full-bleed background image (`auth_screen_background.png`) — errorBuilder
///      falls back to a solid green container.
///   2. "Soul Garden" wordmark logo.
///   3. A clean rounded card holding the [title] heading and the form [child].
///
/// No decorative PNG frame is used (intentionally removed). When [onBack] is
/// provided, a back button floats at the top-left (register → login).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
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
      body: ScreenBackground(
        asset: 'assets/screens/auth_screen_background.png',
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const _AuthHeader(),
                        const SizedBox(height: 24),
                        _Card(title: title, child: child),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoWidth = (constraints.maxWidth * 0.50).clamp(150.0, 220.0);
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

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: const Color(0xF2FCFBF5), // ~95% opaque cream
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.quintessential(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2F6B2E),
            ),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}
