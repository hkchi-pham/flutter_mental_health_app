import 'package:flutter/foundation.dart';

import '../data/journal_repository.dart';
import '../data/models/notebook.dart';

/// UI-facing state holder for the journal feature, mirroring [GardenProvider]'s
/// ChangeNotifier-over-repository pattern.
///
/// The [JournalRepository] is offline-first (cache is the source of truth, the
/// backend is a sync target). This provider owns the in-memory notebook list
/// the journal screens render, kept newest-first by [Notebook.lastWritten], plus
/// the pagination cursor for infinite scroll and CRUD / entry mutations.
///
/// Every mutating method updates local state then calls [notifyListeners] so
/// `Consumer<JournalProvider>` widgets rebuild. All ordering goes through the
/// single private [_sort] helper so newest-first is enforced in one place.
class JournalProvider extends ChangeNotifier {
  JournalProvider({required JournalRepository repository})
      : _repository = repository;

  final JournalRepository _repository;

  /// Notebooks shown in the list, always newest-first (see [_sort]).
  List<Notebook> notebooks = [];

  /// `true` during the initial / refresh load.
  bool loading = false;

  /// `true` while a [loadMore] page fetch is in flight.
  bool loadingMore = false;

  /// `false` once the server returns a short page (no more pages to fetch).
  bool hasMore = true;

  /// Last error message from a load, or `null`. Cleared at the start of a load.
  String? error;

  int _page = 1;
  static const int _pageSize = 20;

  // ===========================================================================
  // Read / pagination
  // ===========================================================================

  /// Loads the first page (cache-first via the repository). Resets pagination.
  /// Safe to call on screen-open and as the pull-to-refresh / reconnect path.
  Future<void> loadInitial() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final loaded = await _repository.loadNotebooks();
      notebooks = _sort(loaded);
      _page = 1;
      hasMore = loaded.length >= _pageSize;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Fetches the next page and appends it (de-duplicated by id). No-op when
  /// there are no more pages or a fetch is already running.
  Future<void> loadMore() async {
    if (!hasMore || loadingMore || loading) return;
    loadingMore = true;
    notifyListeners();
    try {
      final fetched = await _repository.fetchPage(_page + 1, _pageSize);
      if (fetched.isNotEmpty) {
        final existingIds = notebooks.map((n) => n.id).toSet();
        final additions =
            fetched.where((n) => !existingIds.contains(n.id)).toList();
        notebooks = _sort([...notebooks, ...additions]);
        _page++;
      }
      hasMore = fetched.length == _pageSize;
    } catch (e) {
      error = '$e';
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  /// Re-runs [loadInitial] — used for pull-to-refresh and reconnect.
  Future<void> refresh() => loadInitial();

  // ===========================================================================
  // Write — notebooks
  // ===========================================================================

  /// Creates a notebook, inserting the result at the top of the list.
  Future<Notebook> create(Notebook draft) async {
    final nb = await _repository.createNotebook(draft);
    notebooks = _sort([nb, ...notebooks]);
    notifyListeners();
    return nb;
  }

  /// Updates notebook metadata and replaces it in the list (re-sorted).
  Future<void> update(Notebook nb) async {
    await _repository.updateNotebook(nb);
    notebooks = _sort(_replace(nb));
    notifyListeners();
  }

  /// Deletes a notebook and removes it from the list.
  Future<void> delete(String id) async {
    await _repository.deleteNotebook(id);
    notebooks = notebooks.where((n) => n.id != id).toList();
    notifyListeners();
  }

  // ===========================================================================
  // Write — entries
  // ===========================================================================

  /// Appends an entry to [nb], replaces the notebook in the list (re-sorted —
  /// a new entry makes it the most-recently-written), and returns the updated
  /// notebook.
  Future<Notebook> addEntry(Notebook nb, NotebookEntry e) async {
    final updated = await _repository.addEntry(nb, e);
    notebooks = _sort(_replace(updated));
    notifyListeners();
    return updated;
  }

  /// Replaces the whole page of [nb] (used for entry edit AND delete) and
  /// re-sorts.
  Future<void> replacePage(Notebook nb) async {
    await _repository.replacePage(nb);
    notebooks = _sort(_replace(nb));
    notifyListeners();
  }

  // ===========================================================================
  // Sync
  // ===========================================================================

  /// Called by the SyncCoordinator reconnect hook: drain the offline queue +
  /// refresh from server, then reload local state into the UI.
  Future<void> syncOnReconnect() async {
    await _repository.backgroundSync();
    await refresh();
  }

  // ===========================================================================
  // Private
  // ===========================================================================

  /// Returns [list] sorted newest-first by **created time**. Single source of
  /// truth for ordering. Using createdAt (not lastWritten) keeps the list order
  /// STABLE — adding/editing entries doesn't reshuffle notebooks.
  List<Notebook> _sort(List<Notebook> list) {
    final sorted = [...list]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Returns a copy of [notebooks] with the entry matching [nb].id replaced by
  /// [nb] (unsorted — callers pass the result through [_sort]).
  List<Notebook> _replace(Notebook nb) => [
        for (final n in notebooks)
          if (n.id == nb.id) nb else n,
      ];
}
