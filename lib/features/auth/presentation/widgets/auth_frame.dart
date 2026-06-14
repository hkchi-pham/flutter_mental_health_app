import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen auth scaffold that wraps any form child in the branded
/// PNG-frame aesthetic used throughout Soul Garden (info popup, badge popup).
///
/// Layout (top to bottom inside a scrollable column):
///   1. Full-bleed background image (auth_background_@2x.png) — errorBuilder
///      falls back to a solid green container.
///   2. SafeArea + SingleChildScrollView so the keyboard never covers the
///      submit button (CONTEXT requirement).
///   3. Branded header: app mark icon + "Soul Garden" in Quintessential.
///   4. Framed form panel: PNG frame (auth_form_frame_@2x.png) with [child]
///      inset inside. [title] renders as a section heading above the fields.
class AuthFrame extends StatelessWidget {
  const AuthFrame({
    super.key,
    required this.child,
    required this.title,
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-bleed background
          Image.asset(
            'assets/screens/auth_background_@2x.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: const Color(0xFF6B8E5A),
            ),
          ),

          // 2. Scrollable content — keyboard-safe
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 3. Branded header
                  const _AuthHeader(),
                  const SizedBox(height: 28),

                  // 4. Framed form panel
                  _FramedPanel(title: title, child: child),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
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
    return Column(
      children: [
        Image.asset(
          'assets/ui_icons/icons/app_mark_@2x.png',
          width: 64,
          height: 64,
          errorBuilder: (_, _, _) => Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF2F3E2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.eco,
              color: Color(0xFF6B8E5A),
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Soul Garden',
          style: GoogleFonts.quintessential(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2F3E2E),
            letterSpacing: 0.5,
          ),
        ),
      ],
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
        // PNG frame — errorBuilder: cream rounded container with border
        Positioned.fill(
          child: Image.asset(
            'assets/screens/auth_form_frame_@2x.png',
            fit: BoxFit.fill,
            errorBuilder: (_, _, _) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEBDDB8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6B8E5A),
                  width: 2,
                ),
              ),
            ),
          ),
        ),

        // Content inset inside the frame
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
                  color: const Color(0xFF2F3E2E),
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
