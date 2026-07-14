import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/screen_background.dart';

// ---------------------------------------------------------------------------
// Page spec — plain data class (no Flutter deps) so the list stays readable.
// ---------------------------------------------------------------------------

class _PageSpec {
  const _PageSpec({
    required this.background,
    required this.icon,
    required this.headline,
    required this.blurb,
  });

  final String background;
  final String icon;
  final String headline;
  final String blurb;
}

const List<_PageSpec> _pages = [
  // 1 — Welcome
  _PageSpec(
    background: 'assets/screens/splash_screen_background.png',
    icon: 'assets/profile/komo_avatar_default_@3x.png',
    headline: 'Xin chào! Mình là Komo 🌿',
    blurb:
        'Chào mừng bạn đến với Soul Garden — khu vườn nhỏ xinh dành riêng cho tâm hồn của bạn. '
        'Mình sẽ đồng hành cùng bạn mỗi ngày nhé!',
  ),
  // 2 — Garden
  _PageSpec(
    background: 'assets/screens/garden_background_screen.png',
    icon: 'assets/ui_icons/icons/garden_btn_@3x.png',
    headline: 'Khu vườn của bạn',
    blurb:
        'Trồng và chăm sóc những cây xanh — mỗi ngày tưới nước, cây sẽ lớn dần và ghi lại '
        'hành trình bạn đã vun đắp.',
  ),
  // 3 — Journal
  _PageSpec(
    background: 'assets/screens/journal_screen_background.png',
    icon: 'assets/ui_icons/icons/journal_btn_@3x.png',
    headline: 'Nhật ký cảm xúc',
    blurb:
        'Ghi lại những suy nghĩ và cảm xúc mỗi ngày. Viết nhiều hơn, khu vườn của bạn sẽ ngày '
        'càng xanh tươi hơn!',
  ),
  // 4 — Chat (Komo IS chat)
  _PageSpec(
    background: 'assets/screens/chat_screen_background.png',
    icon: 'assets/profile/komo_avatar_default_@3x.png',
    headline: 'Trò chuyện cùng Komo',
    blurb:
        'Bất cứ lúc nào bạn muốn chia sẻ, mình luôn ở đây để lắng nghe và đồng hành cùng bạn.',
  ),
  // 5 — Profile
  _PageSpec(
    background: 'assets/screens/profile_header_background.png',
    icon: 'assets/profile/komo_avatar_default_@3x.png',
    headline: 'Hồ sơ của bạn',
    blurb:
        'Xem thành tựu, huy hiệu đã đạt được và theo dõi hành trình phát triển của bản thân '
        'theo từng ngày.',
  ),
];

// ---------------------------------------------------------------------------
// OnboardingScreen
// ---------------------------------------------------------------------------

/// A 5-page onboarding carousel shown once on first login.
///
/// CALLBACK-ONLY: this widget does NOT read or write [OnboardingStore], does
/// NOT call [Navigator], and does NOT know about [AuthGate]. It simply calls
/// [onDone] when the user finishes or skips. The parent (Plan 02, AuthGate)
/// owns flag persistence and routing.
///
/// Usage:
/// ```dart
/// OnboardingScreen(
///   onDone: () {
///     await _store.markComplete();
///     // route to AppShell
///   },
/// )
/// ```
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// Called when the user either skips (any page) or taps "Bắt đầu" on the
  /// final page.  The parent is responsible for persisting the flag and
  /// routing to [AppShell].
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _index = 0;

  static const int _lastIndex = 4; // _pages.length - 1; const List.length not usable in const expr

  // ── Palette (matches SplashScreen / AppShell painterly cream/brown) ──────
  static const Color _cream = Color(0xFFFDF6E3);
  static const Color _brown = Color(0xFF5D3A1A);
  static const Color _brownLight = Color(0xFF8B5E3C);
  static const Color _accentGreen = Color(0xFF3E7D3A);
  static const Color _scrimColor = Color(0xCC2B1A0A); // dark brown 80%

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brown,
      body: Stack(
        children: [
          // ── PageView ────────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) => _PageView(page: _pages[index]),
          ),

          // ── Skip button — top right, persistent ─────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: TextButton(
                  onPressed: widget.onDone,
                  style: TextButton.styleFrom(
                    foregroundColor: _cream,
                    backgroundColor: _scrimColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Bỏ qua',
                    style: GoogleFonts.quintessential(
                      fontSize: 14,
                      color: _cream,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom bar: dots + primary button ───────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: _scrimColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Page indicator dots
                    _DotsIndicator(
                      count: _pages.length,
                      current: _index,
                      activeColor: _cream,
                      inactiveColor: _brownLight,
                    ),

                    // Primary button
                    _PrimaryButton(
                      label: _index == _lastIndex ? 'Bắt đầu' : 'Tiếp',
                      onPressed:
                          _index == _lastIndex ? widget.onDone : _nextPage,
                      accentGreen: _accentGreen,
                      cream: _cream,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual page — extracted widget to keep the State class readable.
// ---------------------------------------------------------------------------

class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final _PageSpec page;

  static const Color _cream = Color(0xFFFDF6E3);
  static const Color _scrimColor = Color(0xB32B1A0A); // dark brown 70%

  @override
  Widget build(BuildContext context) {
    return ScreenBackground(
      asset: page.background,
      fallbackColor: const Color(0xFF6B8E5A),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 100), // clear the skip button area

              // Feature icon — responsive sizing via LayoutBuilder
              LayoutBuilder(
                builder: (context, constraints) {
                  final iconSize =
                      (constraints.maxWidth * 0.45).clamp(100.0, 200.0);
                  return SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: Image.asset(
                      page.icon,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.eco_outlined,
                        size: iconSize * 0.6,
                        color: _cream,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Scrim panel behind text for legibility over photo backgrounds
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: _scrimColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Headline
                    Text(
                      page.headline,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dancingScript(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _cream,
                        shadows: const [
                          Shadow(
                            color: Color(0x88000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Blurb
                    Text(
                      page.blurb,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quintessential(
                        fontSize: 15,
                        color: _cream.withValues(alpha: 0.9),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),

              // Spacer so the bottom bar doesn't cover content on short screens
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dots indicator
// ---------------------------------------------------------------------------

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.current,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int count;
  final int current;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Primary action button
// ---------------------------------------------------------------------------

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.accentGreen,
    required this.cream,
  });

  final String label;
  final VoidCallback onPressed;
  final Color accentGreen;
  final Color cream;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        key: ValueKey<String>(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: cream,
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 3,
        ),
        child: Text(
          label,
          style: GoogleFonts.quintessential(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cream,
          ),
        ),
      ),
    );
  }
}
