import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../logic/garden_provider.dart';
import '../../shared/models/garden_model.dart';
import 'widgets/tree_widget.dart';
import 'widgets/tree_context_overlay.dart';
import 'widgets/level_up_overlay.dart';
import 'widgets/xp_toast_overlay.dart';
import 'widgets/tree_death_toast_overlay.dart';
import 'widgets/badge_popup.dart';
// TEMP(Phase 10): restore with the settings menu when its tab is built.
// import '../../auth/presentation/widgets/settings_menu_popup.dart';

/// Garden color constants
class _C {
  static const Color green = Color(0xFF6B8E5A);
  static const Color textPrimary = Color(0xFF2F3E2E);
  static const Color textSecondary = Color(0xFF6B7C6A);
  static const Color textDisabled = Color(0xFFA0AEA0);
}

// ==========================================================================
// GRID LAYOUT CONSTANTS
// ==========================================================================
// Background image (3072x2048): fence at ~45%, grass from ~52% to ~95%.
// All grid slots MUST be below the fence line.
// 7 staggered rows: even rows have 7 cols, odd rows have 6 cols offset by half.
//
// Diamond grid geometry: uniform cell size for perfect edge alignment.
// diamondW = column spacing, diamondH = 2 * row spacing.
// Row Y positions and column X positions are derived from the grid bounds.

/// Grid vertical bounds (fraction of bgHeight)
const double _gridTopY = 0.68;
const double _gridBottomY = 0.93;

/// Horizontal padding from each edge (fraction of bgWidth)
const double _gridPadLeft = 0.04;
const double _gridPadRight = 0.04;

/// Perspective scale per row (for tree/decoration sizing, NOT grid cell size)
List<double> get _rowScale {
  final scales = <double>[];
  for (int r = 0; r < gardenRows; r++) {
    scales.add(0.60 + 0.40 * r / (gardenRows - 1));
  }
  return scales;
}

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  final ScrollController _scrollController = ScrollController();

  // Tree context overlay
  OverlayEntry? _treeOverlay;

  // Badge popup overlay
  OverlayEntry? _badgePopupOverlay;

  // Settings menu overlay
  OverlayEntry? _settingsOverlay;

  // Level-up and XP toast overlays
  OverlayEntry? _levelUpOverlay;
  OverlayEntry? _xpToastOverlay;
  OverlayEntry? _deathToastOverlay;
  final Map<String, int> _previousLevels = {};
  int _lastKnownXP = 0;

  // Placement mode
  TreeType? _placingTree;
  DecorationType? _placingDeco;

  // Preview state: selected cell before confirm
  int? _previewRow;
  int? _previewCol;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<GardenProvider>();
      provider.loadGardenState();
      // Initialize _lastKnownXP so the first build doesn't trigger a false toast
      _lastKnownXP = provider.state.points;
      // Listen for batched tree-wilt events so we can show a single death toast
      // per checkHealth() sweep (mirrors the per-sweep batching in the provider).
      provider.onTreesWilted = _handleTreesWilted;
    });
    _scrollController.addListener(() {
      if (_treeOverlay != null) {
        _treeOverlay?.remove();
        _treeOverlay = null;
      }
    });
  }

  @override
  void dispose() {
    // Unhook the provider callback FIRST so a late checkHealth() completion
    // can't fire into a disposed State.
    try {
      context.read<GardenProvider>().onTreesWilted = null;
    } catch (_) {
      // context may be unmounted in tests; ignore.
    }
    _badgePopupOverlay?.remove();
    _badgePopupOverlay = null;
    _settingsOverlay?.remove();
    _settingsOverlay = null;
    _treeOverlay?.remove();
    _treeOverlay = null;
    _levelUpOverlay?.remove();
    _levelUpOverlay = null;
    _xpToastOverlay?.remove();
    _xpToastOverlay = null;
    _deathToastOverlay?.remove();
    _deathToastOverlay = null;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GardenProvider>(
        builder: (context, provider, child) {
          final state = provider.state;

          // ── Level-up detection ──────────────────────────────────
          for (final tree in state.trees) {
            final prev = _previousLevels[tree.id] ?? tree.level;
            if (tree.level > prev) {
              final badge = state.badges.lastWhere(
                (b) => b.treeType == tree.type.name && b.treeLevel == tree.level,
                orElse: () => Badge(
                  id: 'synthetic-${tree.id}-${tree.level}',
                  treeLevel: tree.level,
                  treeType: tree.type.name,
                  treeId: tree.id,
                  earnedAt: DateTime.now(),
                ),
              );
              final treeName = tree.type.name;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showLevelUpOverlay(badge, treeName);
              });
            }
            _previousLevels[tree.id] = tree.level;
          }

          // ── XP toast detection ──────────────────────────────────
          if (state.points > _lastKnownXP && _lastKnownXP > 0) {
            final gained = state.points - _lastKnownXP;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showXpToast(gained);
            });
          }
          _lastKnownXP = state.points;

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // === SCROLLABLE GARDEN ===
              _buildScrollableGarden(state, provider),

              // === FIXED UI OVERLAY ===
              _buildTopBar(state),

              // === SHOP BUTTON (bottom-right) ===
              Positioned(
                right: 12,
                bottom: 16,
                child: _buildShopButton(context, state, provider),
              ),

              // === PLACEMENT BAR ===
              if (_placingTree != null || _placingDeco != null)
                _buildPlacementBar(provider),
            ],
          );
        },
      ),
    );
  }

  // ================================================================
  // SCROLLABLE GARDEN: background + grid items + grid overlay
  // ================================================================
  Widget _buildScrollableGarden(GardenState state, GardenProvider provider) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final bgWidth = screenW * 2.0;
    final isPlacing = _placingTree != null || _placingDeco != null;

    return SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: bgWidth,
          height: screenH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background
              Positioned.fill(
                child: Image.asset(
                  'assets/screens/garden_background_screen.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFBED2BA), Color(0xFF8DAF9B)],
                      ),
                    ),
                  ),
                ),
              ),

              // All placed items merged and sorted by row (back-to-front)
              ..._buildPlacedItems(state, bgWidth, screenH, provider),

              // Grid overlay ON TOP of trees so taps aren't blocked by transparent areas
              if (isPlacing)
                ..._buildGridOverlay(state, bgWidth, screenH, provider),

              // Preview item (staged after valid-cell release, before confirm)
              if (_previewRow != null && _previewCol != null)
                _buildPreviewItem(_previewRow!, _previewCol!, bgWidth, screenH),
            ],
          ),
        ),
    );
  }

  /// Renders the staged preview item inside the scrollable Stack.
  Widget _buildPreviewItem(int row, int col, double bgW, double bgH) {
    final screenH = MediaQuery.of(context).size.height;
    final scale = _rowScale[row.clamp(0, gardenRows - 1)];
    final double itemH;
    final double itemW;
    if (_placingTree != null) {
      itemH = treeDisplayHeight(_placingTree!, 0, screenH) * scale;
      itemW = treeDisplayWidth(_placingTree!, 0, itemH);
    } else if (_placingDeco != null) {
      itemH = decoDisplayHeight(_placingDeco!, screenH) * scale;
      itemW = decoDisplayWidth(_placingDeco!, itemH);
    } else {
      return const SizedBox.shrink();
    }

    final cx = _colCenterX(col, bgW, row: row);
    final cy = _rowCenterYpx(row, bgH);

    // Anchor base at cell center
    final double anchorY;
    if (_placingTree != null) {
      anchorY = trunkBaseY(_placingTree!, 0);
    } else if (_placingDeco != null) {
      anchorY = decoBaseY(_placingDeco!);
    } else {
      anchorY = 0.5;
    }

    return Positioned(
      left: cx - itemW / 2,
      top: cy - anchorY * itemH,
      child: Opacity(
        opacity: 0.75,
        child: Image.asset(
          _placingAssetPath(),
          width: itemW,
          height: itemH,
          fit: BoxFit.fill,
          errorBuilder: (_, __, ___) => SizedBox(width: itemW, height: itemH),
        ),
      ),
    );
  }

  // ================================================================
  // PLACEMENT STATE TRANSITION METHODS
  // ================================================================

  void _cancelPreview() {
    setState(() {
      _previewRow = null;
      _previewCol = null;
    });
  }

  void _confirmPlacement(GardenProvider provider) async {
    if (_previewRow == null || _previewCol == null) return;
    if (_placingTree != null) {
      await provider.plantTree(_placingTree!, _previewRow!, _previewCol!);
    } else if (_placingDeco != null) {
      await provider.placeDecoration(_placingDeco!, _previewRow!, _previewCol!);
    }
    _exitPlacementMode();
  }

  void _exitPlacementMode() {
    setState(() {
      _placingTree = null;
      _placingDeco = null;
      _previewRow = null;
      _previewCol = null;
    });
  }

  // ================================================================
  // GRID HELPERS: convert row,col → pixel position
  // ================================================================

  /// Diamond width (horizontal diagonal) in pixels.
  double _diamondW(double bgW) =>
      bgW * (1 - _gridPadLeft - _gridPadRight) / (gardenCols - 1);

  /// Diamond height (vertical diagonal) in pixels.
  double _diamondH(double bgH) =>
      2 * bgH * (_gridBottomY - _gridTopY) / (gardenRows - 1);

  /// Returns the center X position for a column in the grid.
  /// Odd rows are staggered by half a diamond width.
  double _colCenterX(int col, double bgW, {int row = 0}) {
    final w = _diamondW(bgW);
    final startX = bgW * _gridPadLeft;
    final stagger = row.isOdd ? w / 2 : 0.0;
    return startX + stagger + col * w;
  }

  /// Returns the center Y position for a row (uniform spacing).
  double _rowCenterYpx(int row, double bgH) {
    final r = row.clamp(0, gardenRows - 1);
    return bgH * (_gridTopY + r * (_gridBottomY - _gridTopY) / (gardenRows - 1));
  }

  /// Returns the display height for a tree using the per-type config
  double _treeSizeForLevelAndRow(TreeType type, int level, int row, double screenH) {
    final baseH = treeDisplayHeight(type, level, screenH);
    final scale = _rowScale[row.clamp(0, gardenRows - 1)];
    return baseH * scale;
  }

  /// Returns the display height for a decoration using the per-type config
  double _decoSizeForRow(DecorationType type, int row, double screenH) {
    final baseH = decoDisplayHeight(type, screenH);
    final scale = _rowScale[row.clamp(0, gardenRows - 1)];
    return baseH * scale;
  }

  /// Returns the asset path for the item being placed.
  String _placingAssetPath() {
    if (_placingTree != null) return treeAssetPath(_placingTree!, 0, 100);
    if (_placingDeco != null) return decorationAssetPath(_placingDeco!);
    return '';
  }

  // ================================================================
  // GRID OVERLAY: diamond-shaped tappable cells during placement
  // ================================================================

  /// Returns (halfW, halfH) — uniform diamond half-diagonals for perfect tiling.
  (double, double) _diamondHalfSize(double bgW, double bgH) {
    return (_diamondW(bgW) / 2, _diamondH(bgH) / 2);
  }

  List<Widget> _buildGridOverlay(GardenState state, double bgW, double bgH, GardenProvider provider) {
    final widgets = <Widget>[];

    // Uniform diamond size for perfect tiling
    final (halfW, halfH) = _diamondHalfSize(bgW, bgH);
    final diamondW = halfW * 2;
    final diamondH = halfH * 2;

    // Visual diamond indicators (no individual GestureDetectors)
    for (int r = 0; r < gardenRows; r++) {

      final cols = colsForRow(r);
      for (int c = 0; c < cols; c++) {
        final occupied = state.isCellOccupied(r, c);
        final cx = _colCenterX(c, bgW, row: r);
        final cy = _rowCenterYpx(r, bgH);

        final fillColor = occupied
            ? Colors.red.withAlpha(40)
            : Colors.white.withAlpha(50);
        final borderColor = occupied
            ? Colors.red.withAlpha(80)
            : Colors.white.withAlpha(100);

        widgets.add(
          Positioned(
            left: cx - halfW,
            top: cy - halfH,
            child: IgnorePointer(
              child: CustomPaint(
                size: Size(diamondW, diamondH),
                painter: _DiamondCellPainter(
                  fillColor: fillColor,
                  borderColor: borderColor,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Single tap detector covering entire grid area for diamond hit-testing
    widgets.add(
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final tapPos = details.localPosition;
            final hit = _hitTestDiamondGrid(tapPos, bgW, bgH);
            if (hit != null && !state.isCellOccupied(hit.$1, hit.$2)) {
              _onGridCellTap(hit.$1, hit.$2, provider);
            }
          },
        ),
      ),
    );

    return widgets;
  }

  /// Hit-tests the tap position against all diamond cells.
  /// Returns (row, col) of the tapped cell, or null if outside all cells.
  /// Checks front rows first (higher row index) so closer cells take priority.
  (int, int)? _hitTestDiamondGrid(Offset localPos, double bgW, double bgH) {
    final (halfW, halfH) = _diamondHalfSize(bgW, bgH);
    for (int r = gardenRows - 1; r >= 0; r--) {
      final cols = colsForRow(r);
      for (int c = cols - 1; c >= 0; c--) {
        final cx = _colCenterX(c, bgW, row: r);
        final cy = _rowCenterYpx(r, bgH);
        final dx = (localPos.dx - cx).abs();
        final dy = (localPos.dy - cy).abs();
        if (dx / halfW + dy / halfH <= 1.0) {
          return (r, c);
        }
      }
    }
    return null;
  }

  void _onGridCellTap(int row, int col, GardenProvider provider) {
    setState(() {
      _previewRow = row;
      _previewCol = col;
    });
  }

  // ================================================================
  // PLACED ITEMS: trees + decorations merged and sorted by row (back-to-front)
  // ================================================================
  List<Widget> _buildPlacedItems(GardenState state, double bgW, double bgH, GardenProvider provider) {
    final screenH = MediaQuery.of(context).size.height;
    final (halfW, halfH) = _diamondHalfSize(bgW, bgH);

    // Build a unified list of (row, widget) pairs
    final items = <(int, Widget)>[];

    // Trees
    for (final tree in state.trees) {
      final h = _treeSizeForLevelAndRow(tree.type, tree.level, tree.row, screenH);
      final w = treeDisplayWidth(tree.type, tree.level, h);
      final cx = _colCenterX(tree.col, bgW, row: tree.row);
      final cy = _rowCenterYpx(tree.row, bgH);
      final anchorY = trunkBaseY(tree.type, tree.level);

      items.add((tree.row, Positioned(
        left: cx - w / 2,
        top: cy - anchorY * h,
        child: TreeWidget(
          tree: tree,
          displayHeight: h,
          displayWidth: w,
          onTap: () {
            // cx/cy are in scrollable-content coordinates; adjust for scroll
            final scrollOffset = _scrollController.hasClients
                ? _scrollController.offset
                : 0.0;
            final screenPos = Offset(cx - scrollOffset, cy);
            _showTreeContextOverlay(tree, screenPos, h);
          },
          tapTargetWidth: halfW * 2,
          tapTargetHeight: halfH * 2,
          trunkBaseYFrac: anchorY,
        ),
      )));
    }

    // Decorations
    for (final deco in state.decorations) {
      final h = _decoSizeForRow(deco.type, deco.row, screenH);
      final w = decoDisplayWidth(deco.type, h);
      final cx = _colCenterX(deco.col, bgW, row: deco.row);
      final cy = _rowCenterYpx(deco.row, bgH);
      final baseY = decoBaseY(deco.type);

      items.add((deco.row, Positioned(
        left: cx - w / 2,
        top: cy - baseY * h,
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.asset(
                    decorationAssetPath(deco.type),
                    width: w,
                    height: h,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => SizedBox(
                      width: w,
                      height: h,
                      child: const Center(child: Text('🎍', style: TextStyle(fontSize: 28))),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (w - halfW * 2) / 2,
                top: baseY * h - halfH,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () => _confirmRemoveDecoration(context, deco, provider),
                  child: SizedBox(width: halfW * 2, height: halfH * 2),
                ),
              ),
            ],
          ),
        ),
      )));
    }

    // Sort by row: back rows (lower index) first, front rows last (on top)
    items.sort((a, b) => a.$1.compareTo(b.$1));

    return items.map((e) => e.$2).toList();
  }

  // ================================================================
  // TOP BAR
  // ================================================================
  Widget _buildTopBar(GardenState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildResourceChip(
                'assets/ui_icons/icons/dewdrop_icon_@2x.png',
                '${state.water}',
                '💧',
              ),
              const SizedBox(width: 12),
              _buildResourceChip(
                'assets/ui_icons/icons/seed_icon_@2x.png',
                '${state.points}',
                '🌱',
              ),
              const Spacer(),
              _buildBadgePageButton(context, state),
              // TEMP(Phase 10): settings/menu icon hidden — moving to a
              // dedicated tab not yet built. Restore the SizedBox + button
              // below (and the commented methods/import) when that tab exists.
              // const SizedBox(width: 8),
              // _buildSettingsButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceChip(String assetPath, String value, String fallbackEmoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            assetPath,
            width: 22,
            height: 22,
            errorBuilder: (_, __, ___) => Text(fallbackEmoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: GoogleFonts.quintessential(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BADGE POPUP
  // ================================================================
  Widget _buildBadgePageButton(BuildContext context, GardenState state) {
    final hasUnseen = state.badges.any((b) => !b.seen);
    return GestureDetector(
      onTap: () => _showBadgePopup(context),
      child: Image.asset(
        hasUnseen
            ? 'assets/ui_icons/icons/badge_page_notification_btn_@2x.png'
            : 'assets/ui_icons/icons/badge_page_btn_@2x.png',
        width: 40,
        height: 40,
        errorBuilder: (_, _, _) => const Icon(
          Icons.collections_bookmark,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showBadgePopup(BuildContext context) {
    _badgePopupOverlay?.remove();
    _badgePopupOverlay = null;
    _badgePopupOverlay = OverlayEntry(
      builder: (_) => BadgePopup(
        onClose: () {
          _badgePopupOverlay?.remove();
          _badgePopupOverlay = null;
        },
      ),
    );
    Overlay.of(context).insert(_badgePopupOverlay!);
  }

  // ================================================================
  // SETTINGS MENU
  // ================================================================
  // TEMP(Phase 10): settings menu hidden until its dedicated tab is built.
  // Restore these two methods (and the import + toolbar call site) together.
  // Widget _buildSettingsButton(BuildContext context) {
  //   return GestureDetector(
  //     onTap: () => _showSettingsMenu(context),
  //     child: Image.asset(
  //       'assets/ui_icons/icons/menu_icon_@3x.png',
  //       width: 40,
  //       height: 40,
  //       errorBuilder: (_, _, _) => const Icon(
  //         Icons.settings,
  //         size: 28,
  //         color: Colors.white,
  //       ),
  //     ),
  //   );
  // }

  // void _showSettingsMenu(BuildContext context) {
  //   _settingsOverlay?.remove();
  //   _settingsOverlay = null;
  //   _settingsOverlay = OverlayEntry(
  //     builder: (_) => SettingsMenuPopup(
  //       onClose: () {
  //         _settingsOverlay?.remove();
  //         _settingsOverlay = null;
  //       },
  //     ),
  //   );
  //   Overlay.of(context).insert(_settingsOverlay!);
  // }

  // ================================================================
  // SHOP BUTTON
  // ================================================================
  Widget _buildShopButton(BuildContext context, GardenState state, GardenProvider provider) {
    return GestureDetector(
      onTap: () => _showShopSheet(context, state, provider),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _C.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _C.green.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(
          'assets/ui_icons/icons/shop_icon_@2x.png',
          width: 6,
          height: 6,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.store, color: Colors.white, size: 10),
        ),
      ),
    );
  }

  // ================================================================
  // PLACEMENT BAR
  // ================================================================
  Widget _buildPlacementBar(GardenProvider provider) {
    final hasPreview = _previewRow != null && _previewCol != null;

    return Positioned(
      bottom: 16,
      left: 40,
      right: 40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _C.green,
          borderRadius: BorderRadius.circular(24),
        ),
        child: hasPreview
            ? _buildPlacementBarStateB(provider)
            : _buildPlacementBarStateA(),
      ),
    );
  }

  /// State A: no preview staged — show item icon + "Drag to place" + [X] exit
  Widget _buildPlacementBarStateA() {
    return Row(
      children: [
        Image.asset(
          _placingAssetPath(),
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.eco, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Tap a cell to place',
            style: GoogleFonts.quintessential(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GestureDetector(
          onTap: _exitPlacementMode,
          child: Image.asset(
            'assets/ui_icons/icons/cancel_btn_@2x.png',
            width: 28,
            height: 28,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  /// State B: preview staged — show "Confirm placement?" + Cancel + Confirm
  Widget _buildPlacementBarStateB(GardenProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Confirm placement?',
            style: GoogleFonts.quintessential(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GestureDetector(
          onTap: _cancelPreview,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.quintessential(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _confirmPlacement(provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.quintessential(
                color: _C.green,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // SHOP BOTTOM SHEET
  // ================================================================
  void _showShopSheet(BuildContext context, GardenState state, GardenProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShopSheet(
        state: state,
        provider: provider,
        onTreeSelected: (type) {
          Navigator.pop(context);
          setState(() {
            _placingTree = type;
            _placingDeco = null;
          });
        },
        onDecoSelected: (type) {
          Navigator.pop(context);
          setState(() {
            _placingDeco = type;
            _placingTree = null;
          });
        },
        onBuyWater: (amount) async {
          final ok = await provider.buyWater(amount);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not enough XP!')),
            );
          }
        },
      ),
    );
  }

  // ================================================================
  // TREE CONTEXT OVERLAY
  // ================================================================

  /// Shows a contextual overlay (progress bar + info + water buttons) positioned
  /// directly on the tapped tree. Replaces the old AlertDialog _showTreeInfo.
  void _showTreeContextOverlay(Tree tree, Offset treeScreenPos, double displayH) {
    // Dismiss any existing overlay first
    _treeOverlay?.remove();
    _treeOverlay = null;

    final capturedTreeId = tree.id;
    _treeOverlay = OverlayEntry(
      builder: (ctx) => Consumer<GardenProvider>(
        builder: (ctx, provider, _) {
          // Use live tree state so the growth bar, hearts, and water count
          // update reactively after each waterTree() call. Fall back to the
          // original snapshot if the tree has been removed (wilt auto-dismiss
          // is handled inside _InfoPopup's own Consumer).
          final liveTree = provider.state.trees
              .cast<Tree?>()
              .firstWhere((t) => t?.id == capturedTreeId, orElse: () => null)
              ?? tree;
          return TreeContextOverlay(
            tree: liveTree,
            waterCount: provider.state.water,
            // onWater fires a single watering action but does NOT dismiss the
            // overlay. The user can tap water multiple times; the overlay stays
            // open until they tap elsewhere (onDismiss via Section 1 dismiss layer).
            onWater: () {
              context.read<GardenProvider>().waterTree(capturedTreeId);
            },
            onDismiss: () {
              _treeOverlay?.remove();
              _treeOverlay = null;
            },
            treeScreenPos: treeScreenPos,
            treeDisplayHeight: displayH,
          );
        },
      ),
    );

    Overlay.of(context).insert(_treeOverlay!);
  }

  // ================================================================
  // LEVEL-UP OVERLAY
  // ================================================================

  void _showLevelUpOverlay(Badge badge, String treeName) {
    _levelUpOverlay?.remove();
    _levelUpOverlay = null;

    _levelUpOverlay = OverlayEntry(
      builder: (_) => LevelUpOverlay(
        badge: badge,
        treeName: treeName,
        onDismiss: () {
          _levelUpOverlay?.remove();
          _levelUpOverlay = null;
        },
      ),
    );

    Overlay.of(context).insert(_levelUpOverlay!);
  }

  // ================================================================
  // XP TOAST OVERLAY
  // ================================================================

  void _showXpToast(int amount) {
    _xpToastOverlay?.remove();
    _xpToastOverlay = null;

    final screenW = MediaQuery.of(context).size.width;
    // Position near the XP chip in the top bar (second chip, roughly centred)
    final pos = Offset(screenW * 0.35, 60.0);

    _xpToastOverlay = OverlayEntry(
      builder: (_) => XpToastOverlay(
        amount: amount,
        position: pos,
        onComplete: () {
          _xpToastOverlay?.remove();
          _xpToastOverlay = null;
        },
      ),
    );

    Overlay.of(context).insert(_xpToastOverlay!);
  }

  // ================================================================
  // TREE DEATH TOAST OVERLAY
  // ================================================================

  /// Wired to [GardenProvider.onTreesWilted] in initState — fires once per
  /// checkHealth() sweep with the list of trees that just hit health 0. We
  /// compose a batched message and show a single death toast (mirrors how
  /// _showXpToast handles the rare double-tap case: REPLACE the existing
  /// overlay rather than stacking).
  void _handleTreesWilted(List<Tree> wilted) {
    if (!mounted || wilted.isEmpty) return;
    final message = _composeDeathMessage(wilted);
    _showDeathToast(message);
  }

  String _composeDeathMessage(List<Tree> wilted) {
    if (wilted.length == 1) {
      return 'Your ${_treeDisplayName(wilted.first.type)} wilted away';
    }
    if (wilted.length == 2) {
      return 'Two trees wilted away';
    }
    return '${wilted.length} trees wilted away';
  }

  String _treeDisplayName(TreeType type) {
    switch (type) {
      case TreeType.sakura:
        return 'sakura';
      case TreeType.lotus:
        return 'lotus';
      case TreeType.hope:
        return 'hope flower';
      case TreeType.peace:
        return 'peace tree';
      case TreeType.willow:
        return 'willow';
      case TreeType.lantern:
        return 'lantern tree';
    }
  }

  void _showDeathToast(String message) {
    // REPLACE policy — kill any in-flight death toast first, mirrors
    // _showXpToast so two quick sweeps don't stack two overlays.
    _deathToastOverlay?.remove();
    _deathToastOverlay = null;

    final screenW = MediaQuery.of(context).size.width;
    // Centred horizontally, just below the top bar. Sits slightly lower and
    // further to the centre than the XP toast (0.35 of width @ y=60) so the
    // two toasts don't visually collide if both fire in close succession.
    final position = Offset(screenW * 0.5 - 80, 70);

    final entry = OverlayEntry(
      builder: (_) => TreeDeathToastOverlay(
        message: message,
        position: position,
        onComplete: () {
          _deathToastOverlay?.remove();
          _deathToastOverlay = null;
        },
      ),
    );
    _deathToastOverlay = entry;
    Overlay.of(context).insert(entry);
  }

  // ================================================================
  // REMOVE DECORATION CONFIRM
  // ================================================================
  void _confirmRemoveDecoration(BuildContext context, GardenDecoration deco, GardenProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove ${deco.type.name}?', style: GoogleFonts.quintessential(fontWeight: FontWeight.w700)),
        content: const Text('This decoration will be removed from your garden.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.removeDecoration(deco.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// SHOP BOTTOM SHEET
// ==================================================================
class _ShopSheet extends StatefulWidget {
  final GardenState state;
  final GardenProvider provider;
  final ValueChanged<TreeType> onTreeSelected;
  final ValueChanged<DecorationType> onDecoSelected;
  final Future<void> Function(int) onBuyWater;

  const _ShopSheet({
    required this.state,
    required this.provider,
    required this.onTreeSelected,
    required this.onDecoSelected,
    required this.onBuyWater,
  });

  @override
  State<_ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<_ShopSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text('Shop', style: GoogleFonts.quintessential(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('XP: ${widget.state.points}', style: GoogleFonts.quintessential(fontSize: 13, color: _C.textSecondary)),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            labelColor: _C.green,
            unselectedLabelColor: _C.textDisabled,
            indicatorColor: _C.green,
            labelStyle: GoogleFonts.quintessential(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Trees'),
              Tab(text: 'Decor'),
              Tab(text: 'Water'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTreesTab(),
                _buildDecorTab(),
                _buildWaterTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreesTab() {
    final trees = [
      (TreeType.sakura, 'Sakura', 0, 'Free'),
      (TreeType.lotus, 'Lotus', 0, 'Free'),
      (TreeType.hope, 'Hope', 0, 'Free'),
      (TreeType.peace, 'Peace', 700, '700 XP'),
      (TreeType.willow, 'Willow', 700, '700 XP'),
      (TreeType.lantern, 'Lantern', 3000, '3000 XP'),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: trees.length,
      itemBuilder: (_, i) {
        final (type, name, cost, label) = trees[i];
        const canAfford = true; // TODO: restore cost check after testing
        return _ShopItemCard(
          assetPath: treeAssetPath(type, 2, 100),
          name: name,
          costLabel: label,
          enabled: canAfford,
          onTap: canAfford ? () => widget.onTreeSelected(type) : null,
        );
      },
    );
  }

  Widget _buildDecorTab() {
    final decos = DecorationType.values.map((d) {
      final cost = GardenProvider.getDecorationCost(d);
      return (d, d.name, cost);
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: decos.length,
      itemBuilder: (_, i) {
        final (type, name, cost) = decos[i];
        const canAfford = true; // TODO: restore cost check after testing
        return _ShopItemCard(
          assetPath: decorationAssetPath(type),
          name: name,
          costLabel: '$cost XP',
          enabled: canAfford,
          onTap: canAfford ? () => widget.onDecoSelected(type) : null,
        );
      },
    );
  }

  Widget _buildWaterTab() {
    return Consumer<GardenProvider>(
      builder: (context, provider, _) {
        final points = provider.state.points;
        final water = provider.state.water;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/ui_icons/icons/dewdrop_icon_@2x.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (_, __, ___) => const Text('💧', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Water: $water',
                    style: GoogleFonts.quintessential(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    'XP: $points',
                    style: GoogleFonts.quintessential(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _waterBuyBtn(1, 10, null, points),
              const SizedBox(height: 10),
              _waterBuyBtn(5, 40, 'Save 10', points),
              const SizedBox(height: 10),
              _waterBuyBtn(10, 70, 'Save 30', points),
            ],
          ),
        );
      },
    );
  }

  Widget _waterBuyBtn(int amount, int cost, String? savingsLabel, int currentXp) {
    final canAfford = currentXp >= cost;
    return GestureDetector(
      onTap: canAfford ? () => widget.onBuyWater(amount) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: canAfford ? _C.green : Colors.grey[300],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(
              '$amount Water',
              style: GoogleFonts.quintessential(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: canAfford ? Colors.white : _C.textDisabled,
              ),
            ),
            if (savingsLabel != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  savingsLabel,
                  style: GoogleFonts.quintessential(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: canAfford ? Colors.white : _C.textDisabled,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(
              '$cost XP',
              style: GoogleFonts.quintessential(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: canAfford ? Colors.white70 : _C.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ==================================================================
// SHOP ITEM CARD
// ==================================================================
class _ShopItemCard extends StatelessWidget {
  final String assetPath;
  final String name;
  final String costLabel;
  final bool enabled;
  final VoidCallback? onTap;

  const _ShopItemCard({
    required this.assetPath,
    required this.name,
    required this.costLabel,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withAlpha(60)),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Text('🌿', style: TextStyle(fontSize: 28))),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: GoogleFonts.quintessential(fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                costLabel,
                style: GoogleFonts.quintessential(fontSize: 10, color: _C.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// DIAMOND CELL PAINTER
// ==================================================================
class _DiamondCellPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth = 1.5;

  _DiamondCellPainter({
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();

    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _DiamondCellPainter oldDelegate) =>
      fillColor != oldDelegate.fillColor || borderColor != oldDelegate.borderColor;
}
