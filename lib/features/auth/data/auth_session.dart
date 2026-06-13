import 'package:flutter/foundation.dart';

/// In-memory holder for the current authenticated identity. Widgets can listen
/// to flip between the login screen and the app once [isAuthenticated] changes.
/// The token also lives in [ApiClient] (for requests) and [TokenStore] (for
/// persistence); this is the reactive UI-facing copy.
class AuthSession extends ChangeNotifier {
  String? token;
  String? userId;
  String? userName;

  bool get isAuthenticated => token != null;

  void set({
    required String token,
    required String userId,
    required String userName,
  }) {
    this.token = token;
    this.userId = userId;
    this.userName = userName;
    notifyListeners();
  }

  void clear() {
    token = null;
    userId = null;
    userName = null;
    notifyListeners();
  }
}
