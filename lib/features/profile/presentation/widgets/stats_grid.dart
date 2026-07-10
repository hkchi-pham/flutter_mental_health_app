import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/profile_user.dart';

/// A 2-column grid of six cream-framed stat cards showing the user's counts.
///
/// The pinned card order is:
///   1. Trees planted   (treeGrown)
///   2. Journal entries (journalCount)
///   3. Conversations   (conversationCount)
///   4. Badges earned   (badgeCount)
///   5. Water           (waterUnits) — dewdrop asset icon
///   6. Seeds           (points)     — seed asset icon
///
/// [StatsGrid] takes a loaded [ProfileUser].
/// [StatsGrid.skeleton] renders the same grid with placeholder shimmer cards.
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.user}) : _skeleton = false;

  /// Skeleton loading variant — same 2-col grid, muted placeholder cards.
  const StatsGrid.skeleton({super.key})
      : user = null,
        _skeleton = true;

  final ProfileUser? user;
  final bool _skeleton;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: _skeleton ? _buildSkeletonCards() : _buildStatCards(),
    );
  }

  List<Widget> _buildStatCards() {
    final u = user!;
    return [
      _StatCard(
        icon: const Icon(Icons.park, size: 28, color: Color(0xFF2F3E2E)),
        value: u.treeGrown,
        label: 'Cây đã trồng',
      ),
      _StatCard(
        icon: const Icon(Icons.menu_book, size: 28, color: Color(0xFF2F3E2E)),
        value: u.journalCount,
        label: 'Nhật ký',
      ),
      _StatCard(
        icon: const Icon(
          Icons.chat_bubble_outline,
          size: 28,
          color: Color(0xFF2F3E2E),
        ),
        value: u.conversationCount,
        label: 'Trò chuyện',
      ),
      _StatCard(
        icon: const Icon(
          Icons.emoji_events,
          size: 28,
          color: Color(0xFF2F3E2E),
        ),
        value: u.badgeCount,
        label: 'Huy hiệu',
      ),
      _StatCard(
        icon: Image.asset(
          'assets/ui_icons/icons/dewdrop_icon_@2x.png',
          width: 28,
          height: 28,
          errorBuilder: (_, _, _) => const Icon(
            Icons.water_drop_outlined,
            size: 28,
            color: Color(0xFF2F3E2E),
          ),
        ),
        value: u.waterUnits,
        label: 'Nước',
      ),
      _StatCard(
        icon: Image.asset(
          'assets/ui_icons/icons/seed_icon_@2x.png',
          width: 28,
          height: 28,
          errorBuilder: (_, _, _) => const Icon(
            Icons.eco_outlined,
            size: 28,
            color: Color(0xFF2F3E2E),
          ),
        ),
        value: u.points,
        label: 'Hạt giống',
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

/// A cream-framed stat card showing an icon, a count, and a Vietnamese label.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final Widget icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEBDDB8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B6F47), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B6F47).withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 6),
          Text(
            '$value',
            style: GoogleFonts.quintessential(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2F3E2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.quintessential(
              fontSize: 11,
              color: const Color(0xFF8B6F47),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton card
// ---------------------------------------------------------------------------

/// A muted placeholder card shown while profile data loads.
///
/// Uses a gentle pulsing opacity animation to indicate loading state.
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF8B6F47).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
