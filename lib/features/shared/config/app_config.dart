import 'dart:io';

import 'package:flutter/foundation.dart';

/// Central application configuration.
///
/// **Base URL selection (current auto-detection):**
/// - Web          → http://localhost:8000
/// - Android emu  → http://10.0.2.2:8000  (emulator loopback to host machine)
/// - iOS sim / macOS / Windows / Linux → http://localhost:8000
///
/// **Physical device:** Auto-detection is not possible — the device and the
/// host machine are on a LAN (or Tailscale) and `localhost` won't resolve.
/// For development on a real device, manually replace [apiBaseUrl] with your
/// LAN/Tailscale IP, e.g. `'http://192.168.1.42:8000'`. Production builds
/// should point to an HTTPS domain.
class AppConfig {
  AppConfig._();

  /// Host port the backend is reachable on during development.
  ///
  /// The docker-compose stack maps the API container's uvicorn (port 80) to
  /// host port **8081** (`ports: - 8081:80`). If you instead run uvicorn
  /// directly (e.g. `uvicorn main:app --port 8000`), change this to match.
  static const int _devPort = 8081;

  /// The base URL used by [ApiClient] to reach the FastAPI backend.
  ///
  /// Returns the correct value for the current platform automatically for
  /// emulator / simulator / desktop dev. See class doc for physical-device
  /// and production notes.
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_devPort';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 is the Android emulator's alias for the host machine's
      // loopback address (127.0.0.1 on the dev machine).
      return 'http://10.0.2.2:$_devPort';
    }
    // iOS simulator, macOS, Windows, Linux — localhost resolves to the host.
    return 'http://localhost:$_devPort';
  }
}
