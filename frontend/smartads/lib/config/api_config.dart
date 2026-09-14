import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // ── Base URL selection ───────────────────────────────────────────────────
  // • Flutter Web / Windows desktop  → localhost:3000
  // • Android Emulator               → 10.0.2.2:3000  (routes to host machine)
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    } catch (_) {}
    return 'http://localhost:3000/api/v1';
  }

  static String get serverBaseUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  static String resolveAssetUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$serverBaseUrl${path.startsWith('/') ? path : '/$path'}';
  }

  // ── Auth endpoints ────────────────────────────────────────────────────────
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';

  /// GET/PUT /auth/me — returns the authenticated user's profile
  static String get me => '$baseUrl/auth/me';

  /// Alias kept for backward compatibility (points to same /auth/me)
  static String get profile => '$baseUrl/auth/me';

  static String get users => '$baseUrl/users';
  static String user(int userId) => '$users/$userId';
  static String get billboards => '$baseUrl/billboards';
  static String get advertisements => '$baseUrl/advertisements';
  static String get campaigns => '$baseUrl/campaigns';
  static String get bookings => '$baseUrl/bookings';
  static String billboardAvailability(int billboardId, String date) =>
      '$bookings/availability/$billboardId?date=$date';
  static String get payments => '$baseUrl/payments';
  static String get analytics => '$baseUrl/analytics';
  static String get notifications => '$baseUrl/notifications';
  static String get iotDevices => '$baseUrl/iot/devices';
  static String get iotHeartbeat => '$baseUrl/iot/heartbeat';

  // ── Health check ──────────────────────────────────────────────────────────
  static String get health => '$baseUrl/health';
}
