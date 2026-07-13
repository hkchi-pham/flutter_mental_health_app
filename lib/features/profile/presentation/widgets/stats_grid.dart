import 'package:flutter/material.dart';

import '../../data/profile_user.dart';

/// Stats card background image path.
const String _cardBgPath = 'assets/profile/stats_card_bg_@3x.png';

// ── Icon asset paths ──────────────────────────────────────────────────────────
const String _iconTree = 'assets/ui_icons/icons/tree_icon_sprout_@3x.png';
const String _iconJournal = 'assets/ui_icons/icons/journal_btn_@3x.png';
const String _iconBadge = 'assets/ui_icons/icons/badge_page_btn_@3x.png';
const String _iconWater = 'assets/ui_icons/icons/dewdrop_icon_@3x.png';
const String _iconSeed = 'assets/ui_icons/icons/seed_icon_@3x.png';
const String _iconChat = 'assets/ui_icons/icons/chat_icon_@3x.png';

/// A 3-column × 2-row grid of stat cards showing the user's counts.
///
/// Card order (design guide): Cây | Nhật ký | Badge | Water | Seeds | Chat.
///
/// [StatsGrid] takes a loaded [ProfileUser].
/// [StatsGrid.skeleton] renders the same grid with pulsing placeholder cards.
///
/// Fix 3: Wrapped in [LayoutBuilder] so card sizing is driven by available
/// width, making the grid scale proportionally across phone→tablet widths.
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.user}) : _skeleton = false;

  /// Skeleton loading variant — same 3-col grid, muted placeholder cards.
  const StatsGrid.skeleton({super.key})
      : user = null,
        _skeleton = true;

  final ProfileUser? user;
  final bool _skeleton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive card sizing: fill available width with 3 cols + gaps.
        const int crossAxisCount = 3;
        const double horizontalPadding = 0; // grid padding within this widget
        const double crossAxisSpacing = 12.0;
        const double mainAxisSpacing = 12.0;

        final double totalSpacing =
            crossAxisSpacing * (crossAxisCount - 1) + horizontalPadding * 2;
        final double cardWidth =
            (constraints.maxWidth - totalSpacing) / crossAxisCount;

        // Cards are roughly square with a slight taller ratio for content room.
        final double cardHeight = cardWidth * 1.1;
        final double childAspectRatio = cardWidth / cardHeight;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
          children:
              _skeleton ? _buildSkeletonCards() : _buildStatCards(cardWidth),
        );
      },
    );
  }

  List<Widget> _buildStatCards(double cardWidth) {
    final u = user!;
    // Icon size: ~33% of card width, clamped to 30–40 logical px.
    final double iconSize = (cardWidth * 0.33).clamp(30.0, 40.0);
    return [
      _StatCard(
        iconPath: _iconTree,
        fallbackIcon: Icons.eco,
        fallbackEmoji: '🌱',
        value: u.treeGrown,
        label: 'Cây',
        iconSize: iconSize,
      ),
      _StatCard(
        iconPath: _iconJournal,
        fallbackIcon: Icons.menu_book,
        fallbackEmoji: '📝',
        value: u.journalCount,
        label: 'Nhật ký',
        iconSize: iconSize,
      ),
      _StatCard(
        iconPath: _iconBadge,
        fallbackIcon: Icons.workspace_premium,
        fallbackEmoji: '🏅',
        value: u.badgeCount,
        label: 'Badge',
        iconSize: iconSize,
      ),
      _StatCard(
        iconPath: _iconWater,
        fallbackIcon: Icons.water_drop,
        fallbackEmoji: '💧',
        value: u.waterUnits,
        label: 'Water',
        iconSize: iconSize,
      ),
      _StatCard(
        iconPath: _iconSeed,
        fallbackIcon: Icons.grass,
        fallbackEmoji: '🌰',
        value: u.points,
        label: 'Seeds',
        iconSize: iconSize,
      ),
      _StatCard(
        iconPath: _iconChat,
        fallbackIcon: Icons.chat_bubble_outline,
        fallbackEmoji: '💬',
        value: u.conversationCount,
        label: 'Chat',
        iconSize: iconSize,
      ),
    ];
  }

  List<Widget> _buildSkeletonCards() {
    return List.generate(6, (_) => const _SkeletonCard());
  }
}

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------

/// A single stat card with an optional [stats_card_bg_@3x.png] background,
/// showing a real icon asset (with emoji/icon fallback), a bold count, and a
/// short Vietnamese label.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.iconPath,
    required this.fallbackIcon,
    required this.fallbackEmoji,
    required this.value,
    required this.label,
    required this.iconSize,
  });

  final String iconPath;
  final IconData fallbackIcon;
  final String fallbackEmoji;
  final int value;
  final String label;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background — image first, fallback to off-white container
            Image.asset(
              _cardBgPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFFFFFDF5),
              ),
            ),
            // Content overlay
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Real image asset with fallback chain
                  Image.asset(
                    iconPath,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      fallbackIcon,
                      size: iconSize,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D6E63),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton card
// ---------------------------------------------------------------------------

/// Pulsing placeholder card shown while profile data loads.
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD9CBAA),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
