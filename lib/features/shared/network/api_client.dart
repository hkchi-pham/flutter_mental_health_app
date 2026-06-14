import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown when the backend returns a non-2xx status or an unreachable host.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  /// 0 means the request never reached the server (network/DNS/timeout).
  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Minimal authenticated JSON client for the FastAPI backend.
///
/// Every endpoint lives under [baseUrl] + `/api/v1`. The bearer [token]
/// (when set via [setToken]) is attached to all requests. The auth layer owns
/// the token lifecycle — call [setToken] after login, [clearToken] on logout.
///
/// Base URL by platform:
///   Android emulator → http://10.0.2.2:8000
///   iOS simulator    → http://localhost:8000
///   Physical device  → http://`your-LAN-ip`:8000
///   Production        → https://`your-domain`
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  /// Invoked once whenever the backend returns 401, before the [ApiException]
  /// is thrown. The auth layer wires this to `AuthSession.clear()` +
  /// redirect-to-login so any expired/invalid token anywhere in the app
  /// automatically sends the user back to the login screen.
  void Function()? onUnauthorized;

  static const _apiPrefix = '/api/v1';

  String? _token;
  void setToken(String? token) => _token = token;
  void clearToken() => _token = null;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final qp = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$baseUrl$_apiPrefix$path')
        .replace(queryParameters: qp == null || qp.isEmpty ? null : qp);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, {Object? body}) => _send(() => _http.post(
        _uri(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ));

  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query}) =>
      _send(() => _http.put(
            _uri(path, query),
            headers: _headers,
            body: body == null ? null : jsonEncode(body),
          ));

  Future<dynamic> delete(String path) =>
      _send(() => _http.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() run) async {
    final http.Response res;
    try {
      res = await run();
    } catch (e) {
      throw ApiException(0, 'Network error: $e');
    }
    final body = res.body.isEmpty ? null : _tryDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    // The backend returns {"detail": "..."} for errors (and, due to a backend
    // quirk, for some successes too — see INTEGRATION_FIXES.md in the API repo).
    final detail = body is Map ? body['detail']?.toString() : null;
    if (res.statusCode == 401) onUnauthorized?.call();
    throw ApiException(res.statusCode, detail ?? res.body);
  }

  dynamic _tryDecode(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }
}
