import 'package:flutter/material.dart';

import '../../garden/presentation/garden_screen.dart';
import '../../journal/presentation/journal_list_screen.dart';

/// The persistent post-login surface (CONTEXT decision 1, locked).
///
/// Hosts a 4-tab bottom navigation:
///   0. garden  — default, enabled
///   1. journal — enabled
///   2. chat    — disabled placeholder (deferred per CONTEXT)
///   3. profile — disabled placeholder (deferred per CONTEXT)
///
/// The two enabled tabs are rendered through an [IndexedStack] so each tab body
/// keeps its state when switching. Critically, [GardenScreen] is never rebuilt
/// on a tab change — IndexedStack preserves the live instance, satisfying the
/// Phase 10 zero-UI-change constraint (no edits to GardenScreen, no state loss
/// when the user visits the journal tab and returns).
///
/// AppShell holds NO journal business logic — it only routes between tab bodies
/// and renders the bottom nav.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Currently visible tab. 0 = garden = default.
  int _index = 0;

  // ── Painterly palette (matches the cream/brown aesthetic) ────────────────
  static const Color _barBg = Color(0xFFF6EFE0);
  static const Color _barBorder = Color(0xFFD9C9A8);
  static const Color _activeTint = Color(0xFFCDE0B4);
  static const Color _disabledOpacity = Color(0x66000000); // ~40% via opacity

  /// Selects an enabled tab. Chat/profile call [_comingSoon] instead.
  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  void _comingSoon() {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Coming soon'),
          duration: Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves both tab bodies' state; GardenScreen instance is
      // built once and kept alive across tab switches.
      body: IndexedStack(
        index: _index,
        children: const [
          GardenScreen(),
          JournalListScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _barBg,
        border: Border(top: BorderSide(color: _barBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        // Bound the bar height. Without a fixed height the bottomNavigationBar
        // slot hands its child a loose full-screen constraint, and the per-item
        // `Center` (an Align) expands to that max height — inflating the bar to
        // fill the whole screen and squeezing the body to nothing.
        child: SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              _navItem(
                index: 0,
                asset: 'assets/ui_icons/icons/garden_btn_@3x.png',
                fallback: Icons.park,
                enabled: true,
              ),
              _navItem(
                index: 1,
                asset: 'assets/ui_icons/icons/journal_btn_@3x.png',
                fallback: Icons.menu_book,
                enabled: true,
              ),
              _navItem(
                index: 2,
                asset: 'assets/ui_icons/icons/chat_btn_@3x.png',
                fallback: Icons.chat_bubble_outline,
                enabled: false,
              ),
              _navItem(
                index: 3,
                asset: null, // no profile asset — material icon only
                fallback: Icons.person_outline,
                enabled: false,
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required String? asset,
    required IconData fallback,
    required bool enabled,
  }) {
    final bool selected = enabled && _index == index;

    Widget icon = asset != null
        ? Image.asset(
            asset,
            width: 30,
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) =>
                Icon(fallback, size: 28, color: const Color(0xFF5A4A3A)),
          )
        : Icon(fallback, size: 28, color: const Color(0xFF5A4A3A));

    // Disabled tabs render dimmed.
    if (!enabled) {
      icon = Opacity(
        opacity: 0.4,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            _disabledOpacity,
            BlendMode.srcATop,
          ),
          child: icon,
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => _select(index) : _comingSoon,
        child: AnimatedScale(
          scale: selected ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? _activeTint : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}
