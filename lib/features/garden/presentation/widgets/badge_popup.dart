import 'package:flutter/material.dart' hide Badge;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/garden_model.dart';
import '../../logic/garden_provider.dart';

/// Framed popup showing the player's badge collection, organised into
/// 4 tree-stage tabs (sprout / small / medium / large).
///
/// Each tab displays earned badges in a 3-per-row grid, newest-first.
/// Badges can be traded for water or XP seeds via the per-cell trade buttons.
///
/// Entrance: 200ms easeOut scale (0.9→1.0) + content fade (0→1) + backdrop
/// alpha (0→0.5) — mirrors the Phase 6 _InfoPopup pattern exactly.
/// Cancel-only dismissal: backdrop is a tap-absorber; only [onClose] dismisses.
class BadgePopup extends StatefulWidget {
  final VoidCallback onClose;

  const BadgePopup({super.key, required this.onClose});

  @override
  State<BadgePopup> createState() => _BadgePopupState();
}

class _BadgePopupState extends State<BadgePopup>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _backdrop;
  late final TabController _tabController;

  // Guards against spamming markBadgesSeen on rapid rebuilds
  int _lastSeenLevel = 0;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final curved = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(curved);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _backdrop = Tween<double>(begin: 0.0, end: 0.5).animate(curved);

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Mark the initial tab (sprout = level 1) as seen after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markCurrentTabSeen();
    });

    _entrance.forward();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // indexIsChanging fires twice; only act on the final settled index
    if (_tabController.indexIsChanging) return;
    if (mounted) setState(() {});
    _markCurrentTabSeen();
  }

  void _markCurrentTabSeen() {
    final level = _tabController.index + 1; // tab 0 → sprout level 1
    if (_lastSeenLevel == level) return;
    _lastSeenLevel = level;
    // Fire-and-forget — no await intentional
    context.read<GardenProvider>().markBadgesSeen(level);
  }

  // ---------------------------------------------------------------------------
  // Badge color helper (for Image.asset errorBuilder fallback only)
  // ---------------------------------------------------------------------------
  Color _badgeColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFFCD7F32); // bronze
      case 2:
        return const Color(0xFFC0C0C0); // silver
      case 3:
        return const Color(0xFFFFD700); // gold
      default:
        return const Color(0xFF00BCD4); // diamond-blue
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) {
        return Stack(
          children: [
            // 1. Dark backdrop — taps are absorbed but do NOT dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // intentionally a no-op
                child: Container(
                  color: Colors.black.withValues(alpha: _backdrop.value),
                ),
              ),
            ),
            // 2. Centered framed popup
            Center(
              child: Transform.scale(
                scale: _scale.value,
                child: Opacity(
                  opacity: _fade.value,
                  child: _buildFrame(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFrame(BuildContext context) {
    final mq = MediaQuery.of(context);
    final popupWidth = (mq.size.width * 0.8).clamp(280.0, 420.0);
    final popupHeight = (mq.size.height * 0.7).clamp(400.0, 600.0);

    // Cream fill bezel — TIGHT to the frame's visible cavity so the parchment
    // covers everything between the wooden border on all four sides.
    const double creamLeftFrac = 0.06;
    const double creamRightFrac = 0.06;
    const double creamTopFrac = 0.10;
    const double creamBottomFrac = 0.05;

    // Content padding — LOOSER than the cream so tabs/card don't kiss the
    // decorative bezel. Top padding tucks the tab row just below the carved
    // wooden roof banner. Bottom padding bumped up to 0.09 so the card stays
    // ABOVE the cream's bottom edge (cream ends at 0.05; content needs more
    // margin than cream to avoid bleeding into the wooden bottom bezel).
    const double padLeftFrac = 0.07;
    const double padRightFrac = 0.07;
    const double padTopFrac = 0.12;
    const double padBottomFrac = 0.09;

    // Wider gutter so the cancel button sits clearly OUTSIDE the popup frame
    // (was overlapping the right wood edge at gutter=32).
    const double cancelGutter = 56.0;

    return SizedBox(
      // Symmetric extra width so the popup stays centered on screen; the
      // cancel button occupies the right gutter, the left gutter is empty.
      width: popupWidth + cancelGutter * 2,
      height: popupHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The actual popup frame — centered inside the wider hit-region box.
          Positioned(
            left: cancelGutter,
            top: 0,
            width: popupWidth,
            height: popupHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Cream interior fill — covers the whole cavity.
                Positioned(
                  top: popupHeight * creamTopFrac,
                  bottom: popupHeight * creamBottomFrac,
                  left: popupWidth * creamLeftFrac,
                  right: popupWidth * creamRightFrac,
                  child: Container(color: const Color(0xFFEBDDB8)),
                ),
                // Frame background image — wooden border + carved banner sit
                // on top of the cream so the decoration remains visible.
                Positioned.fill(
                  child: Image.asset(
                    'assets/ui_icons/frames/frame_badge_page_@2x.png',
                    fit: BoxFit.fill,
                    errorBuilder: (_, _, _) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBDDB8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF8B6F47), width: 2),
                      ),
                    ),
                  ),
                ),
                // Interior content
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      popupWidth * padLeftFrac,
                      popupHeight * padTopFrac,
                      popupWidth * padRightFrac,
                      popupHeight * padBottomFrac,
                    ),
                    child: _buildInterior(context),
                  ),
                ),
              ],
            ),
          ),
          // Cancel button — sits in the right gutter outside the popup frame,
          // not touching the wood edge. right: 8 keeps it clearly separated
          // from the frame while still inside the outer SizedBox hit-area.
          Positioned(
            top: popupHeight * 0.10,
            right: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: Image.asset(
                'assets/ui_icons/icons/badge_page_cancel_@2x.png',
                width: 40,
                height: 40,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.cancel, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterior(BuildContext context) {
    // Title removed per UAT round 3 — the carved "Badges" sign on the wooden
    // roof banner already labels the popup. Tabs sit at the very top of the
    // cream interior; the card fills the rest of the frame.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab row (4 PNG-asset tab buttons, no Material TabBar) — height
        // bumped to 72 so the horizontal-pill PNG renders taller (its visible
        // height is roughly cell-width / pill-aspect, so a taller cell yields
        // a taller pill that comfortably fits the tree icon).
        SizedBox(height: 72, child: _buildTabBar(context)),
        const SizedBox(height: 4),
        // Badge grids (Consumer scoped here, NOT at OverlayEntry root)
        Expanded(
          child: Consumer<GardenProvider>(
            builder: (_, provider, _) => TabBarView(
              controller: _tabController,
              children: [
                for (final level in [1, 2, 3, 4])
                  _buildBadgesForLevel(provider.state.badges, level),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab bar
  // ---------------------------------------------------------------------------

  Widget _buildTabBar(BuildContext context) {
    // Each tab gets an equal share of available width via Expanded so the row
    // never overflows (was hitting RIGHT OVERFLOWED BY 0.4 PIXELS at 4×80).
    return Row(
      children: [
        for (int i = 0; i < 4; i++) Expanded(child: _buildTab(i)),
      ],
    );
  }

  Widget _buildTab(int i) {
    final isChosen = _tabController.index == i;
    const stages = ['sprout', 'small', 'medium', 'large'];
    final stage = stages[i];
    return GestureDetector(
      onTap: () => _tabController.animateTo(i),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Tab pill — fills the Expanded slot square.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Image.asset(
                  isChosen
                      ? 'assets/ui_icons/icons/tab_btn_chosen_@2x.png'
                      : 'assets/ui_icons/icons/tab_btn_not_chosen_@2x.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChosen
                          ? const Color(0xFF8B6F47)
                          : const Color(0xFFD4C5A9),
                    ),
                  ),
                ),
              ),
            ),
            // Tree icon — heightFactor shrunk so the icon's bounding box
            // stays SHORTER than the pill's visible height (the pill PNG is a
            // horizontal capsule, ~3:1 aspect, so its rendered height in a
            // square cell is only ~1/3 of the cell width).
            FractionallySizedBox(
              widthFactor: 0.32,
              heightFactor: 0.22,
              child: Image.asset(
                'assets/ui_icons/icons/tree_icon_${stage}_@2x.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.forest, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Badge grids
  // ---------------------------------------------------------------------------

  Widget _buildBadgesForLevel(List<Badge> allBadges, int level) {
    final filtered = allBadges.where((b) => b.treeLevel == level).toList()
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));

    // Both empty and non-empty cases use a single full-size outer card that
    // fills the area beneath the tabs (BoxFit.fill stretches the PNG to the
    // available rectangle).
    final framePath = filtered.isEmpty
        ? 'assets/ui_icons/frames/card_badge_empty_@2x.png'
        : 'assets/ui_icons/frames/card_badge_@2x.png';

    return Stack(
      children: [
        // 1. Outer card frame — fills the entire area beneath the tabs.
        Positioned.fill(
          child: Image.asset(
            framePath,
            fit: BoxFit.fill,
            errorBuilder: (_, _, _) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEBDDB8),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFF8B6F47), width: 1),
              ),
            ),
          ),
        ),
        // 2. Content sits INSIDE the card. Empty case shows nothing extra (the
        // card_badge_empty PNG's "?" is the visual). Non-empty case shows a
        // scrollable 3-per-row grid of badge cells, each with sprite + trade
        // buttons stacked vertically.
        if (filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 10,
                // Shorter, wider cells so 3 rows of badges fit inside the
                // card and the trade buttons sit right under the sprite.
                childAspectRatio: 0.78,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _buildBadgeGridCell(filtered[i]),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Single badge grid cell — sprite on top, trade buttons (water | xp) below.
  // No per-badge frame; the outer card_badge frame is the only visual border.
  // ---------------------------------------------------------------------------

  Widget _buildBadgeGridCell(Badge badge) {
    final type = TreeType.values.firstWhere(
      (t) => t.name == badge.treeType,
      orElse: () => TreeType.sakura,
    );
    final waterVal = badgeWaterValue(badge.treeLevel);
    final xpVal = badgeXpValue(badge.treeLevel);
    final isTraded = badge.tradedFor != null;

    // Tight Column: badge sprite hugs the trade buttons (no large gap), and
    // the buttons are visually anchored to "their" badge. The whole cell sits
    // inside the 3-col grid; FittedBox on the buttons row guarantees we don't
    // overflow the cell width regardless of the cell's pixel size.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Image.asset(
            badgeAssetPath(type, badge.treeLevel),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.emoji_events,
              size: 40,
              color: _badgeColor(badge.treeLevel),
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTradeBtn(
                'assets/ui_icons/icons/trade_water_btn_@2x.png',
                enabled: !isTraded,
                label: '$waterVal',
                onTap: () => context
                    .read<GardenProvider>()
                    .tradeBadge(badge.id, forWater: true),
              ),
              const SizedBox(width: 2),
              _buildTradeBtn(
                'assets/ui_icons/icons/trade_tree_btn_@2x.png',
                enabled: !isTraded,
                label: '$xpVal',
                onTap: () => context
                    .read<GardenProvider>()
                    .tradeBadge(badge.id, forWater: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTradeBtn(
    String assetPath, {
    required bool enabled,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            enabled
                ? assetPath
                : 'assets/ui_icons/icons/disabled_btn_@2x.png',
            width: 44,
            height: 44,
            errorBuilder: (_, _, _) => Container(
              width: 44,
              height: 44,
              color: enabled ? Colors.green : Colors.grey,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.quintessential(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: enabled ? Colors.white : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
