import 'package:flutter/foundation.dart';
import '../../shared/models/garden_model.dart';
import '../data/garden_repository.dart';

// ── BADGE VALUE HELPERS ─────────────────────────────────────────
// Tiered values for trading a badge for water vs XP. Lifted out of
// _ShopSheetState in Phase 7 so the new _BadgePopup widget can reuse them.
int badgeWaterValue(int level) => const {1: 2, 2: 4, 3: 7, 4: 10}[level] ?? 2;
int badgeXpValue(int level)    => const {1: 20, 2: 40, 3: 70, 4: 100}[level] ?? 20;

class GardenProvider extends ChangeNotifier {
  final GardenRepository _repository;
  GardenState _state = GardenState();
  bool _isLoading = false;
  bool _isWatering = false;

  /// Called once per checkHealth() invocation when one or more trees have wilted
  /// (health reached 0) and been removed from state.trees. The list contains the
  /// wilted Tree objects in their pre-removal state so the UI can show a toast.
  /// Fires AFTER notifyListeners() so the UI has already seen the removal.
  void Function(List<Tree> wilted)? onTreesWilted;

  GardenProvider({required GardenRepository repository})
    : _repository = repository;

  GardenState get state => _state;
  bool get isLoading => _isLoading;
  bool get isWatering => _isWatering;

  Future<void> loadGardenState() async {
    _isLoading = true;
    notifyListeners();

    try {
      _state = await _repository.getGardenState();
      await checkHealth();
    } catch (e) {
      print('Error loading garden state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // XP Gains
  Future<void> addPoints(int amount) async {
    final newPoints = (_state.points + amount).clamp(0, 999999);
    _state = _state.copyWith(points: newPoints);
    await _repository.saveGardenState(_state);
    notifyListeners();
  }

  // Tiered water pricing: 1=10 XP, 5=40 XP, 10=70 XP
  static int _waterCost(int amount) {
    if (amount >= 10) return 70;
    if (amount >= 5) return 40;
    return amount * 10; // 1 water = 10 XP
  }

  // Water Shop — tiered pricing
  Future<bool> buyWater(int amount) async {
    final cost = _waterCost(amount);
    if (_state.points < cost) return false;

    _state = _state.copyWith(
      points: _state.points - cost,
      water: _state.water + amount,
    );
    await _repository.saveGardenState(_state);
    notifyListeners();
    return true;
  }

  /// Trades a badge for water or XP. Mutates the badge in place by setting
  /// `tradedFor` so it stays visible in the popup grid (full-color sprite,
  /// only the unused trade button greys out). Returns false if badgeId is
  /// not found or the badge has already been traded.
  Future<bool> tradeBadge(String badgeId, {required bool forWater}) async {
    final idx = _state.badges.indexWhere((b) => b.id == badgeId);
    if (idx == -1) return false;
    final badge = _state.badges[idx];
    if (badge.tradedFor != null) return false; // already traded — no-op

    final waterGain = forWater ? badgeWaterValue(badge.treeLevel) : 0;
    final xpGain    = forWater ? 0 : badgeXpValue(badge.treeLevel);

    final newBadges = List<Badge>.from(_state.badges);
    newBadges[idx] = badge.copyWith(
      tradedFor: forWater ? TradeReward.water : TradeReward.seeds,
    );

    _state = _state.copyWith(
      badges: newBadges,
      water: _state.water + waterGain,
      points: (_state.points + xpGain).clamp(0, 999999),
    );
    await _repository.saveGardenState(_state);
    notifyListeners();
    return true;
  }

  /// Marks every badge at the given tree level as seen. Called by the
  /// badge popup when a stage tab becomes visible. The notification
  /// indicator on the top-bar button reads `badges.any((b) => !b.seen)`.
  Future<void> markBadgesSeen(int treeLevel) async {
    final updated = _state.badges
        .map((b) => (b.treeLevel == treeLevel && !b.seen)
            ? b.copyWith(seen: true)
            : b)
        .toList();
    _state = _state.copyWith(badges: updated);
    notifyListeners();                          // synchronous, then persist
    await _repository.saveGardenState(_state);
  }

  // Planting logic — grid based
  Future<bool> plantTree(TreeType type, int row, int col) async {
    // Validate grid bounds
    if (row < 0 || row >= gardenRows || col < 0 || col >= colsForRow(row)) return false;
    // Check cell not occupied
    if (_state.isCellOccupied(row, col)) return false;
    // Max trees check
    if (_state.trees.length >= gardenTotalSlots) return false;

    final newTree = Tree(
      id: DateTime.now().toIso8601String(),
      type: type,
      row: row,
      col: col,
      plantedDate: DateTime.now(),
    );

    final newTrees = List<Tree>.from(_state.trees)..add(newTree);
    _state = _state.copyWith(trees: newTrees);
    await _repository.saveGardenState(_state);
    notifyListeners();
    return true;
  }

  // Watering logic: 1 Water -> +5 Growth, +10 Health
  Future<bool> waterTree(String treeId) async {
    if (_state.water < 1) return false;

    _isWatering = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1200));

    final treeIndex = _state.trees.indexWhere((t) => t.id == treeId);
    if (treeIndex == -1) {
      _isWatering = false;
      notifyListeners();
      return false;
    }

    final tree = _state.trees[treeIndex];
    int newGrowth = tree.growth + 5;
    int newLevel = tree.level;

    // Level up: 80 Growth per level, max level 4
    if (newGrowth >= 80 * (newLevel + 1) && newLevel < 4) {
      newLevel++;
    }

    // Award a badge when the tree levels up
    List<Badge>? newBadges;
    if (newLevel > tree.level) {
      final badge = Badge(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        treeLevel: newLevel,
        treeType: tree.type.name,
        treeId: tree.id,
        earnedAt: DateTime.now(),
      );
      newBadges = List<Badge>.from(_state.badges)..add(badge);
    }

    final newTree = tree.copyWith(
      growth: newGrowth,
      level: newLevel,
      health: (tree.health + 10).clamp(0, 100),
      lastWatered: DateTime.now(),
    );

    final newTrees = List<Tree>.from(_state.trees);
    newTrees[treeIndex] = newTree;

    _state = _state.copyWith(
      // Clamp so concurrent watering during the 1200ms delay (both passed the
      // water<1 guard before the first decrement landed) can't push it below 0.
      water: (_state.water - 1).clamp(0, 999999),
      trees: newTrees,
      badges: newBadges, // null means no change (copyWith ignores null)
    );
    await _repository.saveGardenState(_state);

    _isWatering = false;
    notifyListeners();
    return true;
  }

  // Decoration placement — grid based
  Future<bool> placeDecoration(DecorationType type, int row, int col) async {
    if (row < 0 || row >= gardenRows || col < 0 || col >= colsForRow(row)) return false;
    if (_state.isCellOccupied(row, col)) return false;
    if (_state.decorations.length >= gardenTotalSlots) return false;

    // TODO: restore cost check after testing
    // final cost = getDecorationCost(type);
    // if (_state.points < cost) return false;

    final newDeco = GardenDecoration(
      id: DateTime.now().toIso8601String(),
      type: type,
      row: row,
      col: col,
    );

    final newDecos = List<GardenDecoration>.from(_state.decorations)..add(newDeco);
    _state = _state.copyWith(
      decorations: newDecos,
    );
    await _repository.saveGardenState(_state);
    notifyListeners();
    return true;
  }

  Future<void> removeDecoration(String decoId) async {
    final newDecos = List<GardenDecoration>.from(_state.decorations)
      ..removeWhere((d) => d.id == decoId);
    _state = _state.copyWith(decorations: newDecos);
    await _repository.saveGardenState(_state);
    notifyListeners();
  }

  static int getDecorationCost(DecorationType type) {
    switch (type) {
      case DecorationType.chair:
      case DecorationType.light:
        return 200;
      case DecorationType.swing:
      case DecorationType.tent:
        return 500;
      case DecorationType.well:
      case DecorationType.bridge:
        return 800;
      case DecorationType.fountain:
        return 1500;
    }
  }

  /// Health decay: if lastWatered > 3 days ago, -10 health per day past grace period.
  /// Trees that reach health == 0 are removed from state.trees and reported to the
  /// optional [onTreesWilted] listener exactly once per sweep.
  Future<void> checkHealth() async {
    final now = DateTime.now();
    bool changed = false;
    final newTrees = List<Tree>.from(_state.trees);

    for (int i = 0; i < newTrees.length; i++) {
      final tree = newTrees[i];
      final lastWatered = tree.lastWatered ?? tree.plantedDate;
      final daysSinceWatering = now.difference(lastWatered).inDays;

      if (daysSinceWatering > 3) {
        final penaltyDays = daysSinceWatering - 3;
        final healthLoss = penaltyDays * 10;
        final newHealth = (tree.health - healthLoss).clamp(0, 100);

        if (newHealth != tree.health) {
          newTrees[i] = tree.copyWith(health: newHealth);
          changed = true;
        }
      }
    }

    // Split survivors from wilted (health == 0). Wilted trees are removed from
    // state and reported via onTreesWilted so the UI can show a batched toast.
    final wilted = <Tree>[];
    final survivors = <Tree>[];
    for (final t in newTrees) {
      if (t.health == 0) {
        wilted.add(t);
      } else {
        survivors.add(t);
      }
    }
    if (wilted.isNotEmpty) {
      // Force persistence even if no health change happened this tick (e.g. a
      // tree was already at 0 before checkHealth ran — orphan cleanup).
      changed = true;
    }

    if (changed) {
      // Clean up badges whose tree just wilted. Legacy badges with empty
      // treeId are preserved — they predate the treeId field and have no
      // tree linkage to validate.
      final deadTreeIds = wilted.map((t) => t.id).toSet();
      final survivingBadges = _state.badges
          .where((b) => b.treeId.isEmpty || !deadTreeIds.contains(b.treeId))
          .toList();
      _state = _state.copyWith(trees: survivors, badges: survivingBadges);
      await _repository.saveGardenState(_state);
      notifyListeners();
      // Fire the callback once per sweep, AFTER listeners have rebuilt with the
      // removed trees gone. The UI sees the disappearance first, then the toast.
      if (wilted.isNotEmpty) {
        onTreesWilted?.call(List<Tree>.unmodifiable(wilted));
      }
    }
  }

  void onJournalEntryAdded() {
    addPoints(20);
  }

  void onJournalEntryWithWordCount(int wordCount) {
    int xp = 20;
    if (wordCount >= 100) {
      final hundreds = (wordCount / 100).floor();
      xp = 25 + (hundreds * 25);
    }
    addPoints(xp);
  }
}
