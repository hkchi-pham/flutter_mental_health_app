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

/// The target width of a single stat card in logical pixels.
/// Derived from phone layout: (360px screen − 32px padding − 24px gaps) / 3 ≈ 101px.
/// We use ~148px to match the card size seen on a typical phone (≈360–400dp wide).
const double _targetCardWidth = 148.0;

/// Gap between cards (matches the profile section's 12 px gaps).
const double _cardGap = 12.0;

/// Total number of stat cards — clamps the max column count.
const int _totalCards = 6;

/// A responsive grid of stat cards showing the user's counts.
///
/// Card order (design guide): Cây | Nhật ký | Badge | Water | Seeds | Chat.
///
/// Reflow behaviour:
///   - Each card is kept at [_targetCardWidth] (≈148 dp) — it does NOT enlarge.
///   - The column count is derived from the available width so extra space is
///     filled by showing MORE columns at the same card size, mirroring the
///     Journal tab's responsive approach:
///       `columns = max(3, floor((width + gap) / (targetCardWidth + gap)))`
///     clamped to at most [_totalCards] (6) so the grid is never wider than
///     one full row. Phone → 3 col / 2 rows; tablet/iPad → 4–5 col; wide
///     desktop → 6 col / 1 row.
///   - childAspectRatio is computed from [_targetCardWidth] so the card height
///     stays consistent regardless of column count (cards are square-ish).
///
/// [StatsGrid] takes a loaded [ProfileUser].
/// [StatsGrid.skeleton] renders the same grid with pulsing placeholder cards.
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.user}) : _skeleton = false;

  /// Skeleton loading variant — same responsive grid, muted placeholder cards.
  const StatsGrid.skeleton({super.key})
      : user = null,
        _skeleton = true;

  final ProfileUser? user;
  final bool _skeleton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;

        // Compute how many columns of [_targetCardWidth] cards fit in the
        // available width, starting from a minimum of 3 (phone default).
        // Formula: (width + gap) / (cardWidth + gap) — the +gap on the
        // numerator accounts for the fact that the last card has no trailing
        // gap. Clamp between 3 and totalCards.
        final int columns = ((availableWidth + _cardGap) /
                (_targetCardWidth + _cardGap))
            .floor()
            .clamp(3, _totalCards);

        // Cards are ALWAYS fixed at [_targetCardWidth]. Extra horizontal space
        // is distributed as spacing between/around cards (spaceEvenly), so
        // nothing is enlarged or cropped.
        const double cardWidth = _targetCardWidth;
        // Cards are roughly square-ish with a little extra height for content.
        const double cardHeight = _targetCardWidth * 1.1;

        // Icon size: ~33% of card width, clamped to 30–40 logical px.
        const double iconSize = cardWidth * 0.33;
        const double clampedIconSize =
            iconSize < 30.0 ? 30.0 : (iconSize > 40.0 ? 40.0 : iconSize);

        final List<Widget> cards = _skeleton
            ? _buildSkeletonCards()
            : _buildStatCards(clampedIconSize);

        // Split cards into rows of [columns] items.
        final List<Widget> rows = [];
        for (int i = 0; i < cards.length; i += columns) {
          final rowCards = cards.sublist(
            i,
            (i + columns).clamp(0, cards.length),
          );
          rows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: rowCards
                  .map(
                    (card) => SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: card,
                    ),
                  )
                  .toList(),
            ),
          );
          if (i + columns < cards.length) {
            rows.add(const SizedBox(height: _cardGap));
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }

  List<Widget> _buildStatCards(double iconSize) {
    final u = user!;
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
    return List.generate(_totalCards, (_) => const _SkeletonCard());
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
            // Background — image first, fallback to off-white container.
            // BoxFit.fill shows the ENTIRE frame image (no side cropping);
            // the card is fixed-size so the slight stretch is imperceptible.
            Image.asset(
              _cardBgPath,
              fit: BoxFit.fill,
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
