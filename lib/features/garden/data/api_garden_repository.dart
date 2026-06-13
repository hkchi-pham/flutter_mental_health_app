import '../../auth/data/auth_session.dart';
import '../../shared/models/garden_model.dart';
import 'dto/tree_dto.dart';
import 'garden_repository.dart';
import 'remote/tree_remote_data_source.dart';
import 'remote/user_remote_data_source.dart';

/// Backend-backed [GardenRepository] that merges server-owned data (currency +
/// trees) with client-only data the backend has no concept of (grid layout,
/// decorations, badges, palette), which it delegates to a [local] repository.
///
/// IMPORTANT — read path only is fully wired. The backend exposes NO bulk
/// "save whole garden" endpoint, and currency/growth are server-authoritative,
/// so [saveGardenState] persists ONLY the client-owned slices locally. Economy
/// mutations (plant / water / grow) must go through [TreeRemoteDataSource]; the
/// GardenProvider needs rewiring to call those granular methods and then
/// re-read via [getGardenState]. That rewiring is a follow-up phase — see
/// .planning/research/backend-sync-gap-analysis.md.
class ApiGardenRepository implements GardenRepository {
  ApiGardenRepository({
    required TreeRemoteDataSource trees,
    required UserRemoteDataSource users,
    required AuthSession session,
    required GardenRepository local,
  })  : _trees = trees,
        _users = users,
        _session = session,
        _local = local;

  final TreeRemoteDataSource _trees;
  final UserRemoteDataSource _users;
  final AuthSession _session;
  final GardenRepository _local; // SharedPreferences-backed: layout/decor/badges

  @override
  Future<GardenState> getGardenState() async {
    // Client-only data (layout, decorations, badges, palette) always comes local.
    final localState = await _local.getGardenState();

    final userName = _session.userName;
    if (userName == null) return localState; // not logged in → local-only

    final currency = await _users.currency(userName);
    final remoteTrees = await _trees.list();

    return localState.copyWith(
      points: currency.points,
      water: currency.water,
      trees: _placeTrees(remoteTrees, localState),
    );
  }

  /// The backend stores no grid position. Reuse a tree's existing local row/col
  /// when its id matches; otherwise drop new trees into the next free cells,
  /// avoiding cells already taken by decorations or earlier trees.
  List<Tree> _placeTrees(List<TreeDto> remote, GardenState local) {
    final localById = {for (final t in local.trees) t.id: t};
    final used = <String>{
      for (final d in local.decorations) '${d.row}:${d.col}',
    };
    int nextRow = 0, nextCol = 0;
    String key(int r, int c) => '$r:$c';

    Tree place(TreeDto dto) {
      final existing = localById[dto.id];
      if (existing != null) {
        used.add(key(existing.row, existing.col));
        return dto.toLocal(row: existing.row, col: existing.col);
      }
      while (nextRow < gardenRows && used.contains(key(nextRow, nextCol))) {
        nextCol++;
        if (nextCol >= colsForRow(nextRow)) {
          nextCol = 0;
          nextRow++;
        }
      }
      final r = nextRow.clamp(0, gardenRows - 1);
      final c = nextCol;
      used.add(key(r, c));
      return dto.toLocal(row: r, col: c);
    }

    return [for (final dto in remote) place(dto)];
  }

  @override
  Future<void> saveGardenState(GardenState state) async {
    // Persist ONLY client-owned slices. Currency + tree growth/health are
    // server-authoritative and change via the granular tree endpoints, not a
    // bulk push. See the class doc + the gap-analysis note.
    await _local.saveGardenState(state);
  }
}
