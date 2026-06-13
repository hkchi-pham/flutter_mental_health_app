import '../../shared/network/api_client.dart';
import 'auth_session.dart';
import 'token_store.dart';

/// Owns login/register/logout and keeps [ApiClient], [TokenStore] and
/// [AuthSession] in sync.
///
/// Backend contract (from the scan):
///   POST /api/v1/auth/login  body {user_name, password}
///        -> {access_token, expires_in, user_name, user_id}
///   POST /api/v1/users/       body UserCreate (no auth) — de-facto registration
///   NOTE: there is no /auth/register endpoint; registration is POST /users/.
class AuthRepository {
  AuthRepository({
    required ApiClient client,
    required TokenStore store,
    required AuthSession session,
  })  : _client = client,
        _store = store,
        _session = session;

  final ApiClient _client;
  final TokenStore _store;
  final AuthSession _session;

  /// Restore a persisted session on app start. Returns true if one was found.
  Future<bool> restore() async {
    final saved = await _store.read();
    if (saved == null) return false;
    _client.setToken(saved.token);
    _session.set(
      token: saved.token,
      userId: saved.userId,
      userName: saved.userName,
    );
    return true;
  }

  Future<void> login({
    required String userName,
    required String password,
  }) async {
    final body = await _client.post('/auth/login', body: {
      'user_name': userName,
      'password': password,
    });
    final map = (body as Map).cast<String, dynamic>();
    final token = '${map['access_token']}';
    final userId = '${map['user_id']}';
    final name = '${map['user_name']}';

    _client.setToken(token);
    await _store.save(token: token, userId: userId, userName: name);
    _session.set(token: token, userId: userId, userName: name);
  }

  /// Creates a user via POST /users/. Sends plaintext password (backend hashes
  /// it server-side). Currency starts at zero — the backend owns the economy.
  Future<void> register({
    required String fullname,
    required String userName,
    required String phone,
    required String password,
    String? email,
  }) async {
    await _client.post('/users/', body: {
      'fullname': fullname,
      'user_name': userName,
      'phone': phone,
      'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
      'points': 0,
      'water_units': 0,
      'tree_grown': 0,
    });
  }

  Future<void> logout() async {
    await _store.clear();
    _client.clearToken();
    _session.clear();
  }
}
