import '../models/user.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Thin wrapper around [ApiService] that keeps a typed [User] reference
/// (using the simpler [User] model used by the auth screens).
///
/// All real HTTP calls are delegated to [ApiService] — no duplicate logic here.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  User? get currentUser => _currentUser;

  // ── Login ──────────────────────────────────────────────────────────────────
  /// Throws an exception with a user-readable message on failure.
  Future<User> login(String email, String password) async {
    final userModel = await ApiService().login(email, password);
    _setCurrentUser(userModel);
    return _currentUser!;
  }

  // ── Register ───────────────────────────────────────────────────────────────
  /// Throws an exception with a user-readable message on failure.
  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    final userModel = await ApiService().register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      phoneNumber: phoneNumber,
    );
    _setCurrentUser(userModel);
    return _currentUser!;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  void logout() {
    _currentUser = null;
    ApiService().logout();
  }

  /// Restores the authenticated user after the JWT has been loaded from storage.
  Future<User?> restoreSession() async {
    final token = ApiService().token;
    if (token == null || token.isEmpty) {
      _currentUser = null;
      return null;
    }

    try {
      final userModel = await ApiService().fetchProfile();
      _setCurrentUser(userModel);
      return _currentUser;
    } catch (_) {
      _currentUser = null;
      return null;
    }
  }

  // ── Helper ─────────────────────────────────────────────────────────────────
  void _setCurrentUser(UserModel m) {
    _currentUser = _fromUserModel(m);
  }

  User _fromUserModel(UserModel m) => User(
    userId: m.userId,
    fullName: m.fullName,
    email: m.email,
    phoneNumber: m.phoneNumber,
    role: m.role,
    createdAt: m.createdAt,
  );
}
