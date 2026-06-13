import 'package:flutter/material.dart';

// ========================================================================
// GARDEN GRID CONSTANTS
// ========================================================================
/// The garden grid: 7 staggered rows covering the grass area below the fence.
/// Even rows (0,2,4,6) have 7 columns; odd rows (1,3,5) have 6 columns offset by half.
const int gardenRows = 7;
const int gardenCols = 7; // max columns (even rows); odd rows use gardenCols - 1

/// Returns the number of columns for a given row.
int colsForRow(int row) => row.isEven ? gardenCols : gardenCols - 1;

int get gardenTotalSlots {
  int total = 0;
  for (int r = 0; r < gardenRows; r++) {
    total += colsForRow(r);
  }
  return total;
}

// ========================================================================
// SIZE CONFIG — height as fraction of screen height
// ========================================================================

/// Large-stage height for each TreeType (fraction of screenHeight).
/// Reference: the wooden gate is ~22% of screen height.
/// Large sakura ≈ 2x gate height, medium sakura > gate height.
const Map<TreeType, double> treeLargeHeightFrac = {
  TreeType.willow:  0.85, // Tallest — weeping willow
  TreeType.sakura:  0.80, // Large flowering tree — ~3x gate height
  TreeType.peace:   0.75, // Tall spreading tree
  TreeType.lantern: 0.65, // Ornamental lantern tree
  TreeType.hope:    0.50, // Sunflower — medium height
  TreeType.lotus:   0.30, // Lotus — low ground plant
};

/// Stage multiplier relative to the large size.
/// Tall trees use wider spread; short plants use compressed range
/// so sprouts are still clearly visible.
const Map<TreeType, Map<int, double>> _treeStageMult = {
  // Tall trees: large spread between stages
  TreeType.willow:  {0: 0.18, 1: 0.35, 2: 0.58, 3: 0.78, 4: 1.00},
  TreeType.sakura:  {0: 0.20, 1: 0.38, 2: 0.60, 3: 0.80, 4: 1.00},
  TreeType.peace:   {0: 0.22, 1: 0.40, 2: 0.62, 3: 0.82, 4: 1.00},
  TreeType.lantern: {0: 0.25, 1: 0.42, 2: 0.62, 3: 0.82, 4: 1.00},
  // Short plants: compressed range so sprouts are clearly visible
  TreeType.hope:    {0: 0.35, 1: 0.50, 2: 0.68, 3: 0.85, 4: 1.00},
  TreeType.lotus:   {0: 0.45, 1: 0.60, 2: 0.75, 3: 0.88, 4: 1.00},
};

/// Legacy global multiplier (kept for reference).
const Map<int, double> treeStageMult = {
  0: 0.22,
  1: 0.40,
  2: 0.62, // medium — taller than gate
  3: 0.82, // medium-large — approaching full size
  4: 1.00, // large — full grown
};

/// Returns the display height for a tree given its type, level, and screen height.
double treeDisplayHeight(TreeType type, int level, double screenH) {
  final largeFrac = treeLargeHeightFrac[type] ?? 0.30;
  final stage = level.clamp(0, 4);
  final stageMult = _treeStageMult[type]?[stage] ?? treeStageMult[stage] ?? 1.0;
  return screenH * largeFrac * stageMult;
}

/// Aspect ratio (width / height) of each tree asset, measured from actual PNGs.
/// Used to render trees at their natural proportions instead of forcing a square.
const Map<TreeType, Map<int, double>> _treeAspectRatio = {
  TreeType.sakura:  {0: 1.15, 1: 0.77, 2: 1.11, 3: 1.11, 4: 1.17},
  TreeType.lotus:   {0: 0.79, 1: 1.01, 2: 0.98, 3: 0.98, 4: 0.90},
  TreeType.hope:    {0: 1.27, 1: 1.01, 2: 0.94, 3: 0.94, 4: 0.63},
  TreeType.peace:   {0: 1.19, 1: 1.26, 2: 0.93, 3: 0.93, 4: 1.06},
  TreeType.willow:  {0: 1.35, 1: 0.91, 2: 0.97, 3: 0.97, 4: 1.04},
  TreeType.lantern: {0: 0.97, 1: 0.85, 2: 0.98, 3: 0.98, 4: 1.11},
};

/// Returns the display width for a tree based on its height and natural aspect ratio.
double treeDisplayWidth(TreeType type, int level, double displayHeight) {
  final stage = level.clamp(0, 4);
  final ratio = _treeAspectRatio[type]?[stage] ?? 1.0;
  return displayHeight * ratio;
}

/// Trunk base Y position as fraction of image height (where trunk meets ground).
/// Measured manually from each PNG asset. Used to anchor the tree so that its
/// trunk base aligns with the grid cell center.
const Map<TreeType, Map<int, double>> _trunkBaseYFrac = {
  TreeType.sakura:  {0: 0.78, 1: 0.78, 2: 0.85, 3: 0.85, 4: 0.87},
  TreeType.lotus:   {0: 0.72, 1: 0.75, 2: 0.78, 3: 0.78, 4: 0.80},
  TreeType.hope:    {0: 0.78, 1: 0.77, 2: 0.80, 3: 0.80, 4: 0.87},
  TreeType.peace:   {0: 0.78, 1: 0.72, 2: 0.84, 3: 0.84, 4: 0.86},
  TreeType.willow:  {0: 0.78, 1: 0.77, 2: 0.84, 3: 0.84, 4: 0.86},
  TreeType.lantern: {0: 0.78, 1: 0.80, 2: 0.82, 3: 0.82, 4: 0.85},
};

/// Returns the trunk base Y fraction for a given tree type and level.
/// Used for positioning: top = cellCenterY - trunkBaseYFrac * displayHeight
double trunkBaseY(TreeType type, int level) {
  final stage = level.clamp(0, 4);
  return _trunkBaseYFrac[type]?[stage] ?? 0.85;
}

/// Decoration display height (fraction of screenHeight) per type.
const Map<DecorationType, double> decoHeightFrac = {
  DecorationType.chair:    0.14,  // Bench — ~1 cell tall
  DecorationType.light:    0.18,  // Lantern
  DecorationType.well:     0.28,  // Well — medium
  DecorationType.bridge:   0.18,  // Bridge
  DecorationType.tent:     0.30,  // Tent — ~2 cells tall
  DecorationType.swing:    0.38,  // Swing — tall, ~2.5 cells
  DecorationType.fountain: 0.20,  // Fountain — medium
};

/// Aspect ratio (width / height) of each decoration asset, measured from PNGs.
const Map<DecorationType, double> _decoAspectRatio = {
  DecorationType.bridge:   1.56,
  DecorationType.chair:    1.67,
  DecorationType.fountain: 1.03,
  DecorationType.light:    0.66,
  DecorationType.swing:    0.87,
  DecorationType.tent:     0.89,
  DecorationType.well:     0.91,
};

/// Returns the display width for a decoration based on its height and aspect ratio.
double decoDisplayWidth(DecorationType type, double displayHeight) {
  final ratio = _decoAspectRatio[type] ?? 1.0;
  return displayHeight * ratio;
}

/// Base Y position as fraction of image height (where item meets ground).
/// Measured manually from each PNG asset. Used to anchor the decoration so
/// that its base aligns with the grid cell center.
const Map<DecorationType, double> _decoBaseYFrac = {
  DecorationType.bridge:   0.55,  // Flat item — center vertically in cell
  DecorationType.chair:    0.92,
  DecorationType.fountain: 0.90,
  DecorationType.light:    0.95,
  DecorationType.swing:    0.93,
  DecorationType.tent:     0.92,
  DecorationType.well:     0.93,
};

/// Returns the base Y fraction for a decoration type.
double decoBaseY(DecorationType type) {
  return _decoBaseYFrac[type] ?? 0.90;
}

/// Returns the display height for a decoration given its type and screen height.
double decoDisplayHeight(DecorationType type, double screenH) {
  final frac = decoHeightFrac[type] ?? 0.10;
  return screenH * frac;
}

enum TreeType {
  sakura, // Free — sakura_flower assets
  lotus, // Free — lotus_flower assets
  hope, // Free — hope_flower assets
  peace, // 700 XP — peace_tree assets
  willow, // 700 XP — willow_tree assets
  lantern, // 3000 XP — lantern_tree assets
}

/// Maps TreeType to the asset filename prefix in assets/trees/
String treeAssetPrefix(TreeType type) {
  switch (type) {
    case TreeType.sakura:
      return 'sakura_flower';
    case TreeType.lotus:
      return 'lotus_flower';
    case TreeType.hope:
      return 'hope_flower';
    case TreeType.peace:
      return 'peace_tree';
    case TreeType.willow:
      return 'willow_tree';
    case TreeType.lantern:
      return 'lantern_tree';
  }
}

/// Maps tree level (0-4) to the asset stage suffix
String treeAssetStage(int level) {
  if (level <= 0) return 'sprout';
  if (level == 1) return 'small';
  if (level <= 3) return 'medium';
  return 'large';
}

/// Resolves the tree sprite asset path based on tree type, growth stage, and
/// current health bucket. Boundaries are lower-inclusive: health == 80 is
/// `healthy`, health == 60 is `thirsty`, etc.
///
/// health >= 81  → assets/trees/{prefix}_{stage}_@2x.png  (existing normal sprites)
/// health 61..80 → assets/tree_health_stages/{prefix}_{stage}_healthy_@3x.png
/// health 41..60 → assets/tree_health_stages/{prefix}_{stage}_thirsty_@3x.png
/// health 21..40 → assets/tree_health_stages/{prefix}_{stage}_wilting_@3x.png
/// health 1..20  → assets/tree_health_stages/{prefix}_{stage}_dying_@3x.png
/// health == 0   → returns the dying-sprite path as a defensive fallback
///                 (trees at 0 are removed by GardenProvider.checkHealth before render)
String treeAssetPath(TreeType type, int level, int health) {
  final prefix = treeAssetPrefix(type);
  final stage = treeAssetStage(level);
  if (health >= 81) {
    return 'assets/trees/${prefix}_${stage}_@2x.png';
  }
  final String state;
  if (health >= 61) {
    state = 'healthy';
  } else if (health >= 41) {
    state = 'thirsty';
  } else if (health >= 21) {
    state = 'wilting';
  } else {
    state = 'dying'; // covers health 1..20 and defensive health == 0
  }
  return 'assets/tree_health_stages/${prefix}_${stage}_${state}_@3x.png';
}

// ========================================================================
// DECORATION
// ========================================================================
enum DecorationType {
  bridge,
  chair,
  fountain,
  light,
  swing,
  tent,
  well,
}

String decorationAssetPath(DecorationType type) {
  final name = type.toString().split('.').last;
  return 'assets/ui_icons/decorations/${name}_decorations_@2x.png';
}

// ========================================================================
// BADGE ASSET HELPERS
// ========================================================================

/// Maps TreeType to the asset filename prefix used in assets/badges/.
/// NOTE: this differs from `treeAssetPrefix` for `TreeType.sakura`
/// — badge files use 'sakura_tree' while tree sprites use 'sakura_flower'.
String badgeAssetPrefix(TreeType type) {
  switch (type) {
    case TreeType.sakura:  return 'sakura_tree';
    case TreeType.lotus:   return 'lotus_flower';
    case TreeType.hope:    return 'hope_flower';
    case TreeType.peace:   return 'peace_tree';
    case TreeType.willow:  return 'willow_tree';
    case TreeType.lantern: return 'lantern_tree';
  }
}

/// Maps a badge's recorded tree level (1..4) to its badge stage name.
/// Distinct from `treeAssetStage` which collapses levels 2 and 3 into 'medium'.
String stageName(int level) {
  if (level <= 1) return 'sprout';
  if (level == 2) return 'small';
  if (level == 3) return 'medium';
  return 'large';
}

/// Resolves the badge sprite asset path. Badges always exist at a fixed
/// stage (the level the tree was when earned) and have no health variant.
String badgeAssetPath(TreeType type, int level) {
  return 'assets/badges/badge_${badgeAssetPrefix(type)}_${stageName(level)}_@2x.png';
}

class GardenDecoration {
  final String id;
  final DecorationType type;
  final int row;
  final int col;

  GardenDecoration({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
  });

  GardenDecoration copyWith({String? id, DecorationType? type, int? row, int? col}) {
    return GardenDecoration(
      id: id ?? this.id,
      type: type ?? this.type,
      row: row ?? this.row,
      col: col ?? this.col,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString().split('.').last,
    'row': row,
    'col': col,
  };

  factory GardenDecoration.fromJson(Map<String, dynamic> json) {
    // Migration: old format used double x/y, new uses int row/col
    int row = 1;
    int col = 2;
    if (json.containsKey('row')) {
      row = json['row'] as int;
      col = json['col'] as int;
    } else if (json.containsKey('x')) {
      // Convert old normalized x,y to nearest grid cell
      final x = (json['x'] as num).toDouble();
      final y = (json['y'] as num).toDouble();
      col = (x * (gardenCols - 1)).round().clamp(0, gardenCols - 1);
      row = (y * (gardenRows - 1)).round().clamp(0, gardenRows - 1);
    }

    return GardenDecoration(
      id: json['id'] as String,
      type: DecorationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DecorationType.chair,
      ),
      row: row,
      col: col,
    );
  }
}

// ========================================================================
// BADGE — earned when a tree levels up
// ========================================================================

/// Reward kind a badge has been traded for. `null` on the Badge means untraded.
enum TradeReward { water, seeds }

class Badge {
  final String id;          // stable id, set on creation (legacy badges = '')
  final int treeLevel;      // 1-4, the level the tree reached
  final String treeType;    // tree type .name string for display
  final String treeId;      // id of the tree that earned this badge (legacy badges = '')
  final TradeReward? tradedFor;  // null = untraded; .water = traded for water; .seeds = traded for XP
  final bool seen;          // true once the user has viewed the badge in its tab
  final DateTime earnedAt;

  Badge({
    required this.id,
    required this.treeLevel,
    required this.treeType,
    required this.treeId,
    this.tradedFor,
    this.seen = false,
    required this.earnedAt,
  });

  Badge copyWith({
    String? id,
    int? treeLevel,
    String? treeType,
    String? treeId,
    TradeReward? tradedFor,
    bool? seen,
    DateTime? earnedAt,
  }) {
    return Badge(
      id: id ?? this.id,
      treeLevel: treeLevel ?? this.treeLevel,
      treeType: treeType ?? this.treeType,
      treeId: treeId ?? this.treeId,
      tradedFor: tradedFor ?? this.tradedFor,
      seen: seen ?? this.seen,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'treeLevel': treeLevel,
    'treeType': treeType,
    'treeId': treeId,
    'tradedFor': tradedFor?.name,
    'seen': seen,
    'earnedAt': earnedAt.toIso8601String(),
  };

  factory Badge.fromJson(Map<String, dynamic> json) {
    TradeReward? parseTrade(dynamic raw) {
      if (raw == null) return null;
      final s = raw.toString();
      for (final v in TradeReward.values) {
        if (v.name == s) return v;
      }
      return null; // unrecognised value — safe fallback
    }
    return Badge(
      id: json['id'] as String? ?? '',
      treeLevel: json['treeLevel'] as int,
      treeType: json['treeType'] as String,
      treeId: json['treeId'] as String? ?? '',
      tradedFor: parseTrade(json['tradedFor']),
      seen: json['seen'] as bool? ?? true, // legacy = already seen (no phantom notification dot)
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );
  }
}

// ========================================================================
// KOMO MOOD — determines which Komo asset to show
// ========================================================================
enum KomoMood { wave, happy, proud, encourage, sad }

String komoAssetPath(KomoMood mood) {
  final name = mood.toString().split('.').last;
  return 'assets/komo/komo_${name}_@2x.png';
}

/// Determine Komo's mood from garden state
KomoMood getKomoMood(GardenState state) {
  // Sad: any tree health < 30
  if (state.trees.any((t) => t.health < 30)) return KomoMood.sad;
  // Proud: at least one tree fully grown (level 4+)
  if (state.trees.any((t) => t.level >= 4)) return KomoMood.proud;
  // Happy: has trees
  if (state.trees.isNotEmpty) return KomoMood.happy;
  // Encourage: has XP but no trees yet
  if (state.points > 0) return KomoMood.encourage;
  // Default: wave (greeting)
  return KomoMood.wave;
}

// ========================================================================
// TREE
// ========================================================================
class Tree {
  final String id;
  final TreeType type;
  final int row;
  final int col;
  final int growth; // 0 to infinity
  final int level; // 0-4
  final int health; // 0-100
  final DateTime plantedDate;
  final DateTime? lastWatered;

  Tree({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
    this.growth = 0,
    this.level = 0,
    this.health = 100,
    required this.plantedDate,
    this.lastWatered,
  });

  Tree copyWith({
    String? id,
    TreeType? type,
    int? row,
    int? col,
    int? growth,
    int? level,
    int? health,
    DateTime? plantedDate,
    DateTime? lastWatered,
  }) {
    return Tree(
      id: id ?? this.id,
      type: type ?? this.type,
      row: row ?? this.row,
      col: col ?? this.col,
      growth: growth ?? this.growth,
      level: level ?? this.level,
      health: health ?? this.health,
      plantedDate: plantedDate ?? this.plantedDate,
      lastWatered: lastWatered ?? this.lastWatered,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'row': row,
      'col': col,
      'growth': growth,
      'level': level,
      'health': health,
      'plantedDate': plantedDate.toIso8601String(),
      'lastWatered': lastWatered?.toIso8601String(),
    };
  }

  factory Tree.fromJson(Map<String, dynamic> json) {
    // Migration: old format used double x/y, new uses int row/col
    int row = 1;
    int col = 2;
    if (json.containsKey('row')) {
      row = json['row'] as int;
      col = json['col'] as int;
    } else if (json.containsKey('x')) {
      final x = (json['x'] as num).toDouble();
      final y = (json['y'] as num).toDouble();
      col = (x * (gardenCols - 1)).round().clamp(0, gardenCols - 1);
      row = (y * (gardenRows - 1)).round().clamp(0, gardenRows - 1);
    }

    return Tree(
      id: json['id'] as String,
      type: TreeType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TreeType.sakura,
      ),
      row: row,
      col: col,
      growth: json['growth'] as int? ?? 0,
      level: json['level'] as int? ?? 0,
      health: json['health'] as int? ?? 100,
      plantedDate: DateTime.parse(json['plantedDate'] as String),
      lastWatered: json['lastWatered'] != null
          ? DateTime.parse(json['lastWatered'] as String)
          : null,
    );
  }
}

enum PaletteType { warm, calm, deep }

class GardenPalette {
  final PaletteType type;
  final List<Color> skyColors;
  final Color platformColor;
  final Color shadowColor;

  const GardenPalette({
    required this.type,
    required this.skyColors,
    required this.platformColor,
    required this.shadowColor,
  });

  static const warm = GardenPalette(
    type: PaletteType.warm,
    skyColors: [Color(0xFFE9D7C0), Color(0xFFDAA38F)],
    platformColor: Color(0xFFE9D7C0),
    shadowColor: Color(0xFFDAA38F),
  );

  static const calm = GardenPalette(
    type: PaletteType.calm,
    skyColors: [Color(0xFFBED2BA), Color(0xFF8DAF9B)],
    platformColor: Color(0xFFBED2BA),
    shadowColor: Color(0xFF8DAF9B),
  );

  static const deep = GardenPalette(
    type: PaletteType.deep,
    skyColors: [Color(0xFFDEE2B0), Color(0xFF243D1D)],
    platformColor: Color(0xFFDEE2B0),
    shadowColor: Color(0xFF243D1D),
  );

  static GardenPalette fromType(PaletteType type) {
    switch (type) {
      case PaletteType.warm:
        return warm;
      case PaletteType.calm:
        return calm;
      case PaletteType.deep:
        return deep;
    }
  }
}

class GardenState {
  final int points; // XP
  final int water; // Water inventory
  final List<Tree> trees;
  final List<GardenDecoration> decorations;
  final PaletteType currentPalette;
  final int maxPoints;
  final List<Badge> badges;

  GardenState({
    this.points = 0,
    this.water = 0,
    this.trees = const [],
    this.decorations = const [],
    this.currentPalette = PaletteType.calm,
    this.maxPoints = 1500,
    this.badges = const [],
  });

  /// Check if a grid cell is occupied by any tree or decoration
  bool isCellOccupied(int row, int col) {
    return trees.any((t) => t.row == row && t.col == col) ||
        decorations.any((d) => d.row == row && d.col == col);
  }

  GardenState copyWith({
    int? points,
    int? water,
    List<Tree>? trees,
    List<GardenDecoration>? decorations,
    PaletteType? currentPalette,
    int? maxPoints,
    List<Badge>? badges,
  }) {
    return GardenState(
      points: points ?? this.points,
      water: water ?? this.water,
      trees: trees ?? this.trees,
      decorations: decorations ?? this.decorations,
      currentPalette: currentPalette ?? this.currentPalette,
      maxPoints: maxPoints ?? this.maxPoints,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'water': water,
      'trees': trees.map((t) => t.toJson()).toList(),
      'decorations': decorations.map((d) => d.toJson()).toList(),
      'currentPalette': currentPalette.toString().split('.').last,
      'maxPoints': maxPoints,
      'badges': badges.map((b) => b.toJson()).toList(),
    };
  }

  factory GardenState.fromJson(Map<String, dynamic> json) {
    var treesList = <Tree>[];
    if (json['trees'] != null) {
      treesList = (json['trees'] as List).map((e) => Tree.fromJson(e)).toList();
    } else if (json['treeLevel'] != null && (json['treeLevel'] as int) > 0) {
      treesList.add(
        Tree(
          id: DateTime.now().toIso8601String(),
          type: TreeType.sakura,
          row: 1,
          col: 2,
          growth: (json['treeLevel'] as int) * 20,
          level: (json['treeLevel'] as int),
          plantedDate: DateTime.now(),
        ),
      );
    }

    var decorationsList = <GardenDecoration>[];
    if (json['decorations'] != null) {
      decorationsList = (json['decorations'] as List)
          .map((e) => GardenDecoration.fromJson(e))
          .toList();
    }

    var badgesList = <Badge>[];
    if (json['badges'] != null) {
      badgesList = (json['badges'] as List)
          .map((e) => Badge.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return GardenState(
      points: json['points'] as int? ?? 0,
      water: json['water'] as int? ?? 0,
      trees: treesList,
      decorations: decorationsList,
      currentPalette: PaletteType.values.firstWhere(
        (e) => e.toString().split('.').last == json['currentPalette'],
        orElse: () => PaletteType.calm,
      ),
      maxPoints: json['maxPoints'] as int? ?? 1500,
      badges: badgesList,
    );
  }
}
