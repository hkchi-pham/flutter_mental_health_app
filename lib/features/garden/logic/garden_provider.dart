import 'package:flutter/foundation.dart';
import '../data/garden_model.dart';
import '../data/garden_repository.dart';

class GardenProvider extends ChangeNotifier {
  final GardenRepository _repository;
  GardenState _state = GardenState();
  bool _isLoading = false;
  bool _isWatering = false;

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
    } catch (e) {
      print('Error loading garden state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPoints(int amount) async {
    final newPoints = (_state.points + amount).clamp(0, _state.maxPoints);
    _state = _state.copyWith(points: newPoints);
    await _repository.saveGardenState(_state);
    notifyListeners();
  }

  Future<void> plantSeed() async {
    if (_state.isSeedPlanted) return;

    _state = _state.copyWith(
      isSeedPlanted: true,
      treeLevel: 0, // Ensure it checks out as seedling
    );
    await _repository.saveGardenState(_state);
    notifyListeners();
  }

  Future<bool> waterTree() async {
    if (!_state.isSeedPlanted) return false;

    // Need at least 100 points to water
    if (_state.points < 100) return false;

    _isWatering = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));

    final newPoints = _state.points - 100;
    final newTotalWatered = _state.totalWatered + 1;
    final newLevel = GardenState.calculateLevel(newTotalWatered);

    _state = _state.copyWith(
      points: newPoints,
      totalWatered: newTotalWatered,
      treeLevel: newLevel,
      lastWatered: DateTime.now(),
    );

    await _repository.saveGardenState(_state);

    _isWatering = false;
    notifyListeners();
    return true;
  }

  // Called when user writes a journal entry
  void onJournalEntryAdded() {
    addPoints(20);
  }

  // Called when user chats with bot
  void onChatMessage() {
    addPoints(10);
  }
}
