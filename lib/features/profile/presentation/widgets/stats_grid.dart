import 'package:flutter/material.dart';

import '../../data/profile_user.dart';

/// Stats card background image path.
const String _cardBgPath = 'assets/profile/stats_card_bg_@3x.png';

/// A 3-column × 2-row grid of stat cards showing the user's counts.
///
/// Card order (design guide): Cây | Nhật ký | Badge | Water | Seeds | Chat.
///
/// [StatsGrid] takes a loaded [ProfileUser].
/// [StatsGrid.skeleton] renders the same grid with pulsing placeholder cards.
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
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: _skeleton ? _buildSkeletonCards() : _buildStatCards(),
    );
  }

  List<Widget> _buildStatCards() {
    final u = user!;
    return [
      _StatCard(emoji: '🌱', value: u.treeGrown, label: 'Cây'),
      _StatCard(emoji: '📝', value: u.journalCount, label: 'Nhật ký'),
      _StatCard(emoji: '🏅', value: u.badgeCount, label: 'Badge'),
      _StatCard(emoji: '💧', value: u.waterUnits, label: 'Water'),
      _StatCard(emoji: '🌰', value: u.points, label: 'Seeds'),
      _StatCard(emoji: '💬', value: u.conversationCount, label: 'Chat'),
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
/// showing a large emoji, a bold count, and a short Vietnamese label.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final int value;
  final String label;

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
                  Text(emoji, style: const TextStyle(fontSize: 28)),
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
