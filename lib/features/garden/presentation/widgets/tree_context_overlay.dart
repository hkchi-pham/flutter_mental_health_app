import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/garden_model.dart';
import '../../logic/garden_provider.dart';

/// Contextual overlay shown when a planted tree is tapped.
///
/// This widget is the content of an OverlayEntry — it does NOT manage
/// the OverlayEntry lifecycle (that is garden_screen's responsibility).
///
/// Shows:
///   - A segmented 4-level progress bar above the tree
///   - An info button (tapping shows a popup with tree details)
///   - A water button (grayed out when waterCount == 0)
///   - A full-screen dismiss layer
///   - Watering animation: droplets → sparkle/glow → growth bar fill → tree bounce
class TreeContextOverlay extends StatefulWidget {
  final Tree tree;
  final int waterCount;
  final VoidCallback onWater;
  final VoidCallback onDismiss;
  final Offset treeScreenPos;
  final double treeDisplayHeight;

  const TreeContextOverlay({
    super.key,
    required this.tree,
    required this.waterCount,
    required this.onWater,
    required this.onDismiss,
    required this.treeScreenPos,
    required this.treeDisplayHeight,
  });

  @override
  State<TreeContextOverlay> createState() => _TreeContextOverlayState();
}

class _TreeContextOverlayState extends State<TreeContextOverlay>
    with TickerProviderStateMixin {
  bool _showInfo = false;

  // ── Watering animation ─────────────────────────────────────────────
  late AnimationController _wateringController;
  late Animation<double> _dropletAnim;  // 0.0-0.3: droplets fall down
  late Animation<double> _sparkleAnim; // 0.3-0.6: sparkle/glow appears
  late Animation<double> _barAnim;     // 0.3-0.7: growth bar increments
  late Animation<double> _bounceAnim;  // 0.6-1.0: tree bounces
  bool _isWatering = false;

  @override
  void initState() {
    super.initState();
    _wateringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _dropletAnim = Tween<double>(begin: -20.0, end: 30.0).animate(
      CurvedAnimation(
        parent: _wateringController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _sparkleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _wateringController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _barAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _wateringController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    _bounceAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _wateringController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _wateringController.dispose();
    super.dispose();
  }

  void _onWaterTapped() {
    if (widget.waterCount <= 0) return;
    // Fire the water action immediately. Each tap is independent — the overlay
    // stays open so the user can water multiple times without re-tapping the tree.
    widget.onWater();
    // Restart the dewdrop animation from the beginning on every tap, regardless
    // of whether a previous animation is still playing (restart-existing-controller
    // pattern). This means overlapping taps restart rather than queue.
    setState(() => _isWatering = true);
    _wateringController.forward(from: 0.0);
    // Use a one-shot listener that removes itself after firing to avoid
    // accumulating listeners across multiple rapid taps.
    void onComplete(AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _isWatering = false);
        _wateringController.removeStatusListener(onComplete);
      }
    }
    // Remove any previously registered listener before adding a fresh one so
    // rapid taps don't stack multiple callbacks for the same controller.
    _wateringController.removeStatusListener(_lastWaterListener ?? (_) {});
    _lastWaterListener = onComplete;
    _wateringController.addStatusListener(onComplete);
  }

  // Tracks the most-recently-registered animation completion listener so we
  // can remove it before registering a new one on the next tap.
  void Function(AnimationStatus)? _lastWaterListener;

  @override
  Widget build(BuildContext context) {
    final tree = widget.tree;
    final pos = widget.treeScreenPos;
    final displayH = widget.treeDisplayHeight;

    // Anchor the bar to the VISIBLE top of the tree (where trunkBaseY says
    // the sprite begins above the cell center) plus 24px breathing room.
    // The earlier formula (displayH * 1.3) overshot massively at higher
    // levels because it didn't account for the trunkBaseY offset.
    final treeTopY = pos.dy - trunkBaseY(tree.type, tree.level) * displayH;
    final barTop = treeTopY - 24;
    const barWidth = 120.0;
    final barLeft = pos.dx - barWidth / 2;

    // Buttons below trunk base
    final buttonsTop = pos.dy + 8;
    const buttonsRowWidth = 80.0; // 36 + 8 gap + 36
    final buttonsLeft = pos.dx - buttonsRowWidth / 2;

    // Droplet horizontal offsets
    const dropletOffsets = [-12.0, 0.0, 12.0];

    return Stack(
      children: [
        // ── 1. Full-screen dismiss layer ──────────────────────────
        // When the framed info popup is open (_showInfo == true), this layer is
        // inert — only the popup's own cancel button dismisses the popup, and
        // dismissing the popup returns the user to the contextual overlay (where
        // backdrop tap then dismisses the whole overlay as before).
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showInfo ? null : widget.onDismiss,
            child: const SizedBox.expand(),
          ),
        ),

        // ── 2. Level badge + single growth bar (resets per level) ─────
        Positioned(
          left: barLeft,
          top: barTop,
          child: _LargeGrowthBar(
            tree: tree,
            controller: _wateringController,
            barAnim: _barAnim,
            sparkleAnim: _sparkleAnim,
            isWatering: _isWatering,
            scale: 1.0,
            barWidth: barWidth,
          ),
        ),

        // ── 3. Watering animation visuals ─────────────────────────
        if (_isWatering)
          AnimatedBuilder(
            animation: _wateringController,
            builder: (context, child) {
              return Stack(
                children: [
                  // 3a. Water droplets (interval 0.0-0.3) — dewdrop asset
                  ...dropletOffsets.map((xOffset) {
                    return Positioned(
                      left: pos.dx + xOffset - 7,
                      top: pos.dy - displayH * 0.6 + _dropletAnim.value,
                      child: Opacity(
                        opacity: (1.0 -
                                _wateringController.value / 0.3)
                            .clamp(0.0, 1.0),
                        child: Image.asset(
                          'assets/ui_icons/icons/dewdrop_icon_@2x.png',
                          width: 14,
                          height: 14,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.water_drop,
                            color: Colors.blue,
                            size: 14,
                          ),
                        ),
                      ),
                    );
                  }),

                  // 3c. Tree bounce (interval 0.6-1.0) — scale overlay on tree area
                  Positioned(
                    left: pos.dx - 40,
                    top: pos.dy - displayH - 10,
                    child: Transform.scale(
                      scale: _bounceAnim.value,
                      child: SizedBox(
                        width: 80,
                        height: displayH + 10,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

        // ── 5. Info + Water buttons row ───────────────────────────
        Positioned(
          left: buttonsLeft,
          top: buttonsTop,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info button
              GestureDetector(
                onTap: () => setState(() => _showInfo = !_showInfo),
                child: Image.asset(
                  'assets/ui_icons/icons/info_page_btn_@2x.png',
                  width: 36,
                  height: 36,
                  errorBuilder: (_, _, _) => Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xAA3E2723),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Water button — empty/has variant based on stock.
              // NOT gated on _isWatering: each tap fires immediately and restarts
              // the animation, so the user can water multiple times in a row without
              // waiting for the dewdrop animation to finish.
              GestureDetector(
                onTap: widget.waterCount > 0
                    ? _onWaterTapped
                    : null,
                child: Image.asset(
                  widget.waterCount > 0
                      ? 'assets/ui_icons/icons/water_has_btn_@2x.png'
                      : 'assets/ui_icons/icons/water_empty_btn_@2x.png',
                  width: 36,
                  height: 36,
                  errorBuilder: (_, _, _) => Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.waterCount > 0
                          ? const Color(0xAA1B5E20)
                          : const Color(0xAA757575),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.water_drop,
                      size: 18,
                      color: widget.waterCount > 0
                          ? Colors.white
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // "No water!" label when water count is 0
        if (widget.waterCount == 0)
          Positioned(
            left: pos.dx - 28,
            top: buttonsTop + 40,
            child: Text(
              'No water!',
              style: GoogleFonts.quintessential(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),

        // ── 4. Framed info popup (Phase 6). Rendered LAST so it sits above all
        // other overlay children (dismiss layer, growth bar, watering visuals,
        // info/water buttons). The popup's own backdrop darkens everything below.
        if (_showInfo)
          Positioned.fill(
            child: _InfoPopup(
              treeId: tree.id,
              fallbackTree: tree,
              onClose: () => setState(() => _showInfo = false),
              wateringController: _wateringController,
              barAnim: _barAnim,
              sparkleAnim: _sparkleAnim,
              isWatering: _isWatering,
            ),
          ),
      ],
    );
  }

}

// ── Reusable private widgets ──────────────────────────────────────────────────

/// Level badge + single growth bar.
///
/// [scale] drives all pixel sizes proportionally:
///   - 1.0 = in-garden overlay (badge 22pt, bar 8pt height)
///   - 1.5 = larger popup variant (used by Plan 06-02)
/// [barWidth] is the total outer SizedBox width (badge + gap + Expanded bar).
class _LargeGrowthBar extends StatelessWidget {
  final Tree tree;
  final AnimationController controller;
  final Animation<double> barAnim;
  final Animation<double> sparkleAnim;
  final bool isWatering;
  final double scale;       // 1.0 = in-garden, 1.5 = popup
  final double barWidth;    // total outer width (badge + gap + bar Expanded)

  const _LargeGrowthBar({
    required this.tree,
    required this.controller,
    required this.barAnim,
    required this.sparkleAnim,
    required this.isWatering,
    this.scale = 1.0,
    required this.barWidth,
  });

  String _displayLevel(int level) {
    if (level <= 0) return '1';
    if (level == 1) return '2';
    if (level <= 3) return '3';
    return '4';
  }

  @override
  Widget build(BuildContext context) {
    final badgeSize = 22.0 * scale;
    final levelFont = 12.0 * scale;
    final gap = 6.0 * scale;
    final barH = 8.0 * scale;
    final barRadius = 4.0 * scale;

    // Real progress from live provider state — TweenAnimationBuilder smoothly
    // animates to whatever this value is. No additive increment needed, so
    // there is no overshoot/snap-back when provider updates arrive mid-animation.
    final double targetProgress;
    if (tree.level >= 4) {
      targetProgress = 1.0;
    } else {
      targetProgress = ((tree.growth - 80.0 * tree.level) / 80.0).clamp(0.0, 1.0);
    }

    // Sparkle glow still uses the watering controller (for low-health visual).
    return AnimatedBuilder(
      animation: sparkleAnim,
      builder: (context, _) {
        final isLowHealth = tree.health < 30;
        final sparkleGlow = isLowHealth && isWatering ? sparkleAnim.value : 0.0;

        return SizedBox(
          width: barWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: badgeSize,
                height: badgeSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/ui_icons/icons/badge_level_@2x.png',
                      width: badgeSize,
                      height: badgeSize,
                      errorBuilder: (_, _, _) => Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B8E5A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Text(
                      _displayLevel(tree.level),
                      style: GoogleFonts.quintessential(
                        fontSize: levelFont,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(barRadius),
                  child: Stack(
                    children: [
                      Container(
                        height: barH,
                        decoration: BoxDecoration(
                          color: sparkleGlow > 0
                              ? Colors.green.withValues(alpha: 0.3 * sparkleGlow)
                              : Colors.white.withAlpha(80),
                        ),
                      ),
                      // TweenAnimationBuilder drives fill directly to the real
                      // provider value — no additive offset, zero overshoot risk.
                      // 150ms + easeOutCubic: front-loads motion so the bar feels
                      // instant on tap while still visually smooth (Round 7 fix).
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: targetProgress),
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedProgress, _) {
                          return FractionallySizedBox(
                            widthFactor: animatedProgress,
                            child: Container(
                              height: barH,
                              color: sparkleGlow > 0
                                  ? Color.lerp(
                                      const Color(0xFF6B8E5A),
                                      Colors.green,
                                      sparkleGlow * 0.6,
                                    )
                                  : const Color(0xFF6B8E5A),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Five-heart health row.
///
/// Renders 5 hearts filled/empty based on tree health buckets.
/// Default values match the existing in-garden info popup exactly:
///   - 12 pt icons, pink filled (0xFFEF5C7E), white24 empty, 2 pt right padding.
/// Plan 06-02 uses iconSize: 24, emptyColor: 0xFF6B7C6A, rightPadding: 4
/// for the larger framed popup.
class _HeartsRow extends StatelessWidget {
  final Tree tree;
  final double iconSize;
  final Color filledColor;
  final Color emptyColor;
  final double rightPadding;

  const _HeartsRow({
    required this.tree,
    this.iconSize = 12,
    this.filledColor = const Color(0xFFEF5C7E),
    this.emptyColor = Colors.white24,
    this.rightPadding = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < (((tree.health - 1) ~/ 20) + 1).clamp(1, 5);
        // Skip right padding on the last heart so the row is visually centered.
        final isLast = i == 4;
        return Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : rightPadding),
          child: Icon(
            filled ? Icons.favorite : Icons.favorite_border,
            size: iconSize,
            color: filled ? filledColor : emptyColor,
          ),
        );
      }),
    );
  }
}

/// Centered framed popup showing tree info: name, hero sprite, growth bar, hearts.
/// Entrance: 200ms easeOut scale (0.9→1.0) + content fade (0→1) + backdrop alpha (0→0.5).
/// Cancel-only dismissal: tapping the backdrop is a no-op; only the cancel button
/// (or the tree disappearing from GardenProvider.state.trees) calls onClose.
class _InfoPopup extends StatefulWidget {
  final String treeId;
  final Tree fallbackTree; // used only during the single frame between provider removal and onClose
  final VoidCallback onClose;
  // Pass the watering controller and animations through so the popup growth bar
  // can react to ongoing watering (the popup may stay open while user closes it
  // and re-opens after watering — keeping the bar live is the right call).
  final AnimationController wateringController;
  final Animation<double> barAnim;
  final Animation<double> sparkleAnim;
  final bool isWatering;

  const _InfoPopup({
    required this.treeId,
    required this.fallbackTree,
    required this.onClose,
    required this.wateringController,
    required this.barAnim,
    required this.sparkleAnim,
    required this.isWatering,
  });

  @override
  State<_InfoPopup> createState() => _InfoPopupState();
}

class _InfoPopupState extends State<_InfoPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _backdrop;

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
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    // 80% width clamped — Pitfall 3
    final popupW = (mq.width * 0.8).clamp(280.0, 420.0);
    // Frame is roughly portrait (3:4-ish). Tune on device in Plan 06-03 if needed.
    final popupH = popupW * 1.15;
    final heroH = popupH * 0.35; // ~35% of popup height (INFO-03)

    return Consumer<GardenProvider>(
      builder: (context, provider, _) {
        // Auto-dismiss check using LIVE provider state (Pitfall 4)
        final liveTree = provider.state.trees
            .where((t) => t.id == widget.treeId)
            .cast<Tree?>()
            .firstWhere((_) => true, orElse: () => null);

        if (liveTree == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onClose();
          });
        }
        final tree = liveTree ?? widget.fallbackTree;

        return AnimatedBuilder(
          animation: _entrance,
          builder: (context, _) {
            return Stack(
              children: [
                // 1. Dark backdrop — taps are absorbed but DO NOT dismiss (Pitfall 5)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: false,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {}, // absorb taps — DO NOT call widget.onClose
                      child: Container(
                        color: Colors.black.withValues(alpha: _backdrop.value),
                      ),
                    ),
                  ),
                ),
                // 2. Centered popup
                Center(
                  child: Opacity(
                    opacity: _fade.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: SizedBox(
                        width: popupW,
                        height: popupH,
                        child: Stack(
                          clipBehavior: Clip.none, // Pitfall 2 — let cancel button overlap
                          children: [
                            // 2a-fill. Cream interior fill — inset to the frame's visible
                            // interior so it does NOT bleed above/behind the decorative bezel.
                            // Bezel fractions measured from frame_info_page_@2x.png (800x1174px):
                            //   top:    109/1174 = 9.28%  ← tunable if frame asset changes
                            //   bottom:  91/1174 = 7.75%  ← tunable
                            //   left:    75/800  = 9.38%  ← tunable
                            //   right:   75/800  = 9.38%  ← tunable (symmetric L/R)
                            Positioned(
                              top: popupH * 0.0928,
                              bottom: popupH * 0.0775,
                              left: popupW * 0.0938,
                              right: popupW * 0.0938,
                              child: Container(
                                color: const Color(0xFFEBDDB8), // antique parchment ← tunable
                              ),
                            ),
                            // 2a. Frame PNG (transparent interior, colored bezel) — on top
                            // of the cream fill so the decorative border remains visible.
                            Positioned.fill(
                              child: Image.asset(
                                'assets/ui_icons/frames/frame_info_page_@2x.png',
                                fit: BoxFit.fill,
                                errorBuilder: (_, _, _) => Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xEE3E2723),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                            // 2b. Content column inset from frame border.
                            // Padding uses the same bezel fractions as the cream fill
                            // (measured from frame_info_page_@2x.png) plus ~8px breathing
                            // room, so content is visually centered within the frame interior.
                            // L/R: popupW*0.094 + 8 ≈ 34-47px, Top: popupH*0.093 + 8 ≈ 38-47px,
                            // Bottom: popupH*0.078 + 8 ≈ 31-41px  ← tunable per bezel fractions.
                            //
                            // ASYMMETRY COMPENSATION: The frame PNG's visible interior is
                            // shifted slightly right within its bounding box. Adding extra px to
                            // the left inset pushes content rightward to optically center it
                            // within the cream area. Tunable — increase if content still reads
                            // left-of-center, decrease if it reads right-of-center.
                            // Total extra offset = +20px (8 breathing + 8 asymmetry round-4 + 4 round-6).
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                popupW * 0.094 + 8 + 8 + 4, // left  = bezel + breathing + asymmetry (+8 round-4, +4 round-6) ← tunable
                                popupH * 0.093 + 8,          // top   = bezel + breathing room
                                popupW * 0.094 + 8,          // right = bezel + breathing room (symmetric)
                                popupH * 0.078 + 8,          // bottom = bezel + breathing room
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Title
                                  Text(
                                    _capitalizeName(tree.type.name),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.quintessential(
                                      fontSize: 22,
                                      color: const Color(0xFF2F3E2E),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Hero sprite — height-constrained only (Pitfall 6)
                                  SizedBox(
                                    height: heroH,
                                    child: Image.asset(
                                      treeAssetPath(tree.type, tree.level, tree.health),
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => Container(
                                        width: heroH * 0.8,
                                        height: heroH,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8FB48A),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.park,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  // Growth bar — reuse _LargeGrowthBar at scale 1.5.
                                  // Popup-local left padding pushes the level badge away
                                  // from the left frame bezel (badge = 22*1.5 = 33px wide).
                                  // 12px extra inset gives breathing room without shifting the
                                  // bar too far right. ← tunable; does NOT affect the in-garden
                                  // _LargeGrowthBar instance (different Positioned parent).
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: _LargeGrowthBar(
                                      tree: tree,
                                      controller: widget.wateringController,
                                      barAnim: widget.barAnim,
                                      sparkleAnim: widget.sparkleAnim,
                                      isWatering: widget.isWatering,
                                      scale: 1.5,
                                      barWidth: popupW * 0.65,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  // Health label + hearts row centered together
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Health',
                                        style: GoogleFonts.quintessential(
                                          fontSize: 16,
                                          color: const Color(0xFF2F3E2E),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _HeartsRow(
                                        tree: tree,
                                        iconSize: 24,
                                        filledColor: const Color(0xFFEF5C7E),
                                        emptyColor: const Color(0xFF6B7C6A),
                                        rightPadding: 4,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // 2c. Cancel button overlapping top-right
                            Positioned(
                              top: -12,
                              right: -12,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: widget.onClose,
                                child: Image.asset(
                                  'assets/ui_icons/icons/info_page_cancel_btn_@2x.png',
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF8B5A3C),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _capitalizeName(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
