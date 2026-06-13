import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT + identity from a successful login in the platform secure
/// store (Keychain on iOS, Keystore-backed on Android). Chosen over
/// SharedPreferences because a session token is sensitive.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kToken = 'auth_token';
  static const _kUserId = 'auth_user_id';
  static const _kUserName = 'auth_user_name';

  Future<void> save({
    required String token,
    required String userId,
    required String userName,
  }) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kUserId, value: userId);
    await _storage.write(key: _kUserName, value: userName);
  }

  Future<({String token, String userId, String userName})?> read() async {
    final token = await _storage.read(key: _kToken);
    final userId = await _storage.read(key: _kUserId);
    final userName = await _storage.read(key: _kUserName);
    if (token == null || userId == null || userName == null) return null;
    return (token: token, userId: userId, userName: userName);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kUserName);
  }
}
