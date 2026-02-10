import 'package:flutter/foundation.dart';
import '../data/journal_model.dart';
import '../data/journal_repository.dart';

class JournalProvider extends ChangeNotifier {
  final JournalRepository _repository;
  List<Journal> _journals = [];
  bool _isLoading = false;
  String? _error;

  JournalProvider({required JournalRepository repository})
    : _repository = repository;

  List<Journal> get journals => _journals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadJournals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _journals = await _repository.getJournals();
    } catch (e) {
      _error = 'Không thể tải nhật ký: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createJournal(String title, String emoji) async {
    final tempJournal = Journal(
      id: '',
      title: title,
      emoji: emoji,
      createdAt: DateTime.now(),
    );

    try {
      final newJournal = await _repository.addJournal(tempJournal);
      _journals.insert(0, newJournal);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Không thể tạo nhật ký: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteJournal(String journalId) async {
    try {
      await _repository.deleteJournal(journalId);
      _journals.removeWhere((j) => j.id == journalId);
      notifyListeners();
    } catch (e) {
      _error = 'Không thể xóa nhật ký: $e';
      notifyListeners();
    }
  }

  Future<bool> addEntry(String journalId, String content) async {
    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
    );

    try {
      await _repository.addEntryToJournal(journalId, entry);
      final index = _journals.indexWhere((j) => j.id == journalId);
      if (index != -1) {
        _journals[index] = _journals[index].copyWith(
          entries: [entry, ..._journals[index].entries],
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Không thể thêm entry: $e';
      notifyListeners();
      return false;
    }
  }

  Journal? getJournalById(String id) {
    try {
      return _journals.firstWhere((j) => j.id == id);
    } catch (e) {
      return null;
    }
  }
}
