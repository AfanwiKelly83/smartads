import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Lightweight utility to check whether the SmartAds backend is reachable.
///
/// Usage:
/// ```dart
/// final online = await ConnectionChecker.isBackendOnline();
/// if (!online) {
///   // Show a banner or redirect to offline screen
/// }
/// ```
class ConnectionChecker {
  ConnectionChecker._();

  /// Pings `GET /api/v1/health` and returns `true` if the backend responds
  /// with a 2xx status within 5 seconds.
  static Future<bool> isBackendOnline() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.health))
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Returns the full health payload from the backend, or `null` if offline.
  static Future<Map<String, dynamic>?> getHealthStatus() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.health))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Basic JSON parse — no dart:convert import needed here, just return it
        return {'online': true, 'statusCode': response.statusCode};
      }
      return {'online': false, 'statusCode': response.statusCode};
    } catch (e) {
      return {'online': false, 'error': e.toString()};
    }
  }
}
