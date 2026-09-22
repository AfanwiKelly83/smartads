import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/billboard_model.dart';
import '../models/campaign_model.dart';
import '../models/advertisement_model.dart';
import '../utils/http_exception.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  /// Set to true to use local mock data instead of hitting the real backend.
  /// Useful for UI development without a running server.
  static bool isDemoMode = false;

  String? _token;
  UserModel? _currentUser;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  void setToken(String? token) {
    _token = token;
    if (token == null) {
      _secureStorage.delete(key: 'smartads_jwt');
      _secureStorage.delete(key: 'smartads_user');
    } else {
      _secureStorage.write(key: 'smartads_jwt', value: token);
    }
  }

  Future<void> saveSession(String token, UserModel user) async {
    _token = token;
    _currentUser = user;
    try {
      await _secureStorage.write(key: 'smartads_jwt', value: token);
      await _secureStorage.write(
        key: 'smartads_user',
        value: jsonEncode(user.toJson()),
      );
    } catch (_) {}
  }

  ApiService._internal() {
    _loadTokenFromStorage();
  }

  Future<void> _loadTokenFromStorage() async {
    try {
      final t = await _secureStorage.read(key: 'smartads_jwt');
      if (t != null && t.isNotEmpty) {
        _token = t;
      }
      final userJsonStr = await _secureStorage.read(key: 'smartads_user');
      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        try {
          _currentUser = UserModel.fromJson(jsonDecode(userJsonStr));
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<UserModel?> restoreSession() async {
    try {
      final token = await _secureStorage.read(key: 'smartads_jwt');
      if (token == null || token.isEmpty) {
        _token = null;
        _currentUser = null;
        return null;
      }
      _token = token;

      final userJsonStr = await _secureStorage.read(key: 'smartads_user');
      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        try {
          _currentUser = UserModel.fromJson(jsonDecode(userJsonStr));
        } catch (_) {}
      }

      try {
        final profile = await fetchProfile();
        _currentUser = profile;
        await _secureStorage.write(
          key: 'smartads_user',
          value: jsonEncode(profile.toJson()),
        );
        return _currentUser;
      } catch (e) {
        if (e is HttpException && e.statusCode == 401) {
          await logout();
          return null;
        }
        if (_currentUser != null) {
          return _currentUser;
        }
        if (isDemoMode) {
          _currentUser = UserModel(
            userId: 1,
            fullName: 'SMARTADS User',
            email: 'user@smartads.cm',
            phoneNumber: '+237 670000000',
            role: 'ADVERTISER',
            createdAt: DateTime.now().toIso8601String(),
          );
          return _currentUser;
        }
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  String? get token => _token;
  UserModel? get currentUser => _currentUser;

  Map<String, String> _getHeaders({bool isMultipart = false}) {
    final headers = <String, String>{};
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Generic HTTP GET
  Future<dynamic> get(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      return _processResponse(response);
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException(0, 'Network request failed: $e');
    }
  }

  // Generic HTTP POST
  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      debugPrint('[ApiService] POST $url');
      debugPrint('[ApiService] Headers: ${_getHeaders()}');
      debugPrint('[ApiService] Body: ${jsonEncode(body)}');
      final response = await http
          .post(Uri.parse(url), headers: _getHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      debugPrint(
        '[ApiService] Response ${response.statusCode} from $url: ${response.body}',
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('[ApiService] POST $url failed: $e');
      if (e is HttpException) rethrow;
      throw HttpException(0, 'Network request failed: $e');
    }
  }

  // Generic HTTP PUT
  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(Uri.parse(url), headers: _getHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      return _processResponse(response);
    } catch (e) {
      throw HttpException(0, 'Network request failed: $e');
    }
  }

  // Generic HTTP DELETE
  Future<dynamic> delete(String url) async {
    try {
      final response = await http
          .delete(Uri.parse(url), headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      return _processResponse(response);
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException(0, 'Network request failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBillboardAvailability({
    required int billboardId,
    DateTime? date,
  }) async {
    final selectedDate = date ?? DateTime.now();
    final dateText = selectedDate.toIso8601String().substring(0, 10);
    final res = await get(
      ApiConfig.billboardAvailability(billboardId, dateText),
    );
    if (res['success'] == true) {
      if (res['data'] is List) {
        return List<Map<String, dynamic>>.from(res['data']);
      } else if (res['data'] is Map && res['data']['slots'] is List) {
        return List<Map<String, dynamic>>.from(res['data']['slots']);
      }
    }
    throw Exception(res['message'] ?? 'Failed to load billboard availability');
  }

  Future<Map<String, dynamic>> getBillboardCapacity({
    required int billboardId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = (startDate ?? DateTime.now()).toIso8601String().substring(0, 10);
    final end = (endDate ?? startDate ?? DateTime.now()).toIso8601String().substring(0, 10);

    final res = await get('${ApiConfig.billboards}/$billboardId/availability?startDate=$start&endDate=$end');
    if (res['success'] == true && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data']);
    }
    // Fallback if not reachable
    return {
      'billboardId': billboardId,
      'maxActiveCampaigns': 10,
      'occupiedCampaignsCount': 0,
      'remainingCapacity': 10,
      'isAvailable': true,
      'startDate': start,
      'endDate': end
    };
  }

  dynamic _processResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'HTTP Error ${response.statusCode}';

    switch (response.statusCode) {
      case 401:
        setToken(null);
        _currentUser = null;
        throw HttpException(401, message);
      case 403:
        throw HttpException(403, message);
      case 404:
        throw HttpException(404, message);
      case 409:
        throw HttpException(409, message);
      default:
        if (response.statusCode >= 500) {
          throw HttpException(
            response.statusCode,
            'Server error (${response.statusCode}).',
          );
        }
        throw HttpException(response.statusCode, message);
    }
  }

  // Authentication helper methods
  Future<UserModel> login(String email, String password) async {
    final res = await post(ApiConfig.login, {
      'email': email,
      'password': password,
    });

    if (res['success'] == true && res['data'] != null) {
      final token = res['data']['token'];
      final user = UserModel.fromJson(res['data']['user']);
      await saveSession(token, user);
      return _currentUser!;
    } else {
      throw Exception(res['message'] ?? 'Login failed');
    }
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    final res = await post(ApiConfig.register, {
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role,
      'phoneNumber': phoneNumber,
    });

    if (res['success'] == true && res['data'] != null) {
      final token = res['data']['token'];
      final user = UserModel.fromJson(res['data']['user']);
      await saveSession(token, user);
      return _currentUser!;
    } else {
      throw Exception(res['message'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    try {
      await _secureStorage.delete(key: 'smartads_jwt');
      await _secureStorage.delete(key: 'smartads_user');
    } catch (_) {}
  }

  // Profile Methods
  Future<UserModel> fetchProfile() async {
    try {
      final res = await get(ApiConfig.profile);
      if (res['success'] == true && res['data'] != null) {
        _currentUser = UserModel.fromJson(res['data']);
        return _currentUser!;
      } else {
        throw Exception(res['message'] ?? 'Failed to load user profile');
      }
    } catch (e) {
      if (_currentUser != null) return _currentUser!;
      if (!isDemoMode) rethrow;
      _currentUser = UserModel(
        userId: 1,
        fullName: 'SMARTADS User',
        email: 'user@smartads.cm',
        phoneNumber: '+237 670000000',
        role: 'ADVERTISER',
        createdAt: DateTime.now().toIso8601String(),
      );
      return _currentUser!;
    }
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

      final res = await put(ApiConfig.profile, body);
      if (res['success'] == true && res['data'] != null) {
        _currentUser = UserModel.fromJson(res['data']);
        return _currentUser!;
      } else {
        throw Exception(res['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
        );
        return _currentUser!;
      }
      _currentUser = UserModel(
        userId: 1,
        fullName: fullName ?? 'SMARTADS User',
        email: email ?? 'user@smartads.cm',
        phoneNumber: phoneNumber ?? '+237 670000000',
        role: 'ADVERTISER',
      );
      return _currentUser!;
    }
  }

  // Payment Processing Method
  Future<bool> processPayment({
    required dynamic bookingId,
    required double amount,
    required String paymentMethod,
    required String phoneNumber,
  }) async {
    try {
      final res = await post(ApiConfig.payments, {
        'bookingId': bookingId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'phoneNumber': phoneNumber,
      });
      return res['success'] == true;
    } catch (e) {
      // Demo success
      return true;
    }
  }

  // Mock / Listing Data Methods
  List<BillboardModel> getMockBillboards() {
    return [
      BillboardModel(
        billboardId: 1,
        billboardName: 'Douala Akwa Commercial LED',
        location: 'Akwa Boulevard, Douala',
        screenSize: '4K UHD (3840x2160)',
        hourlyRate: 15000.0,
        status: 'ACTIVE',
        availabilityStatus: 'AVAILABLE',
        latitude: '4.0511',
        longitude: '9.7679',
        description: 'High-traffic commercial display for retail and product launches.',
        qrCodeUrl:
            'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=SMARTADS_BB_1',
      ),
      BillboardModel(
        billboardId: 2,
        billboardName: 'Yaoundé Bastos Highway Screen',
        location: 'Bastos Junction, Yaoundé',
        screenSize: 'Full HD (1920x1080)',
        hourlyRate: 12000.0,
        status: 'ACTIVE',
        availabilityStatus: 'AVAILABLE',
        latitude: '3.8830',
        longitude: '11.5120',
        description: 'Prime highway visibility for brand awareness and promotions.',
        qrCodeUrl:
            'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=SMARTADS_BB_2',
      ),
      BillboardModel(
        billboardId: 3,
        billboardName: 'Buea Town Campus Digital Board',
        location: 'Main University Road, Buea',
        screenSize: '2K Display (2560x1440)',
        hourlyRate: 8000.0,
        status: 'ACTIVE',
        availabilityStatus: 'AVAILABLE',
        latitude: '4.1560',
        longitude: '9.2435',
        description: 'Campus-facing screen for youth, education and technology campaigns.',
        qrCodeUrl:
            'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=SMARTADS_BB_3',
      ),
      BillboardModel(
        billboardId: 4,
        billboardName: 'Limbe Beachfront LED Display',
        location: 'Down Beach Road, Limbe',
        screenSize: '4K Outdoor Screen',
        hourlyRate: 10000.0,
        status: 'ACTIVE',
        availabilityStatus: 'AVAILABLE',
        latitude: '4.0167',
        longitude: '9.2167',
        description: 'High leisure and tourist footfall area near the Atlantic coastline.',
        qrCodeUrl:
            'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=SMARTADS_BB_4',
      ),
      BillboardModel(
        billboardId: 5,
        billboardName: 'Bafoussam Central Market LED',
        location: 'Marche A, Bafoussam',
        screenSize: 'Full HD (1920x1080)',
        hourlyRate: 9000.0,
        status: 'ACTIVE',
        availabilityStatus: 'AVAILABLE',
        latitude: '5.4777',
        longitude: '10.4176',
        description: 'Bustling commercial hub in the West Region with maximum merchant audience.',
        qrCodeUrl:
            'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=SMARTADS_BB_5',
      ),
    ];
  }

  List<CampaignModel> getMockCampaigns() {
    return [
      CampaignModel(
        campaignId: 101,
        campaignName: 'Summer Product Launch 2026',
        startDate: '2026-09-01',
        endDate: '2026-09-30',
        status: 'ACTIVE',
        totalBudget: 450000.0,
        billboardId: 1,
        billboardName: 'Douala Akwa Commercial LED',
      ),
      CampaignModel(
        campaignId: 102,
        campaignName: 'Back-to-School Tech Promo',
        startDate: '2026-09-05',
        endDate: '2026-09-20',
        status: 'SCHEDULED',
        totalBudget: 280000.0,
        billboardId: 2,
        billboardName: 'Yaoundé Bastos Highway Screen',
      ),
    ];
  }

  // Admin Management Methods
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final res = await get(ApiConfig.users);
      if (res['success'] == true && res['data'] != null) {
        return List<Map<String, dynamic>>.from(res['data']);
      }
    } catch (_) {}
    // Mock users fallback
    return [
      {
        'userId': 1,
        'fullName': 'Kelly Afanwi (Admin)',
        'email': 'admin@smartads.cm',
        'role': 'ADMIN',
        'phoneNumber': '+237 671 234 567',
        'createdAt': '2026-08-01T10:00:00Z',
      },
      {
        'userId': 2,
        'fullName': 'Apex Media Solutions',
        'email': 'contact@apexmedia.cm',
        'role': 'ADVERTISER',
        'phoneNumber': '+237 690 112 233',
        'createdAt': '2026-08-15T14:30:00Z',
      },
      {
        'userId': 3,
        'fullName': 'Douala Out-of-Home Ltd',
        'email': 'owner@doualaled.cm',
        'role': 'BILLBOARD_OWNER',
        'phoneNumber': '+237 677 889 900',
        'createdAt': '2026-08-20T09:15:00Z',
      },
      {
        'userId': 4,
        'fullName': 'Zenith Beverages Marketing',
        'email': 'marketing@zenith.cm',
        'role': 'ADVERTISER',
        'phoneNumber': '+237 655 443 322',
        'createdAt': '2026-08-28T16:00:00Z',
      },
    ];
  }

  Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    String? accountStatus,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (role != null) body['role'] = role;
    if (accountStatus != null) body['accountStatus'] = accountStatus;
    final res = await put(ApiConfig.user(userId), body);
    if (res['success'] == true && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data']);
    }
    throw Exception(res['message'] ?? 'Failed to update user account');
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    try {
      final res = await get(ApiConfig.payments);
      if (res['success'] == true && res['data'] != null) {
        return List<Map<String, dynamic>>.from(res['data']);
      }
    } catch (_) {}
    // Mock payments fallback
    return [
      {
        'paymentId': 501,
        'bookingId': 101,
        'amount': 280000.0,
        'paymentMethod': 'MTN Mobile Money',
        'paymentStatus': 'SUCCESSFUL',
        'paymentDate': '2026-09-02T11:40:00Z',
        'transactionReference': 'TXN-MTN-994821',
        'advertiserName': 'Apex Media Solutions',
        'billboardName': 'Douala Akwa Commercial LED',
      },
      {
        'paymentId': 502,
        'bookingId': 102,
        'amount': 150000.0,
        'paymentMethod': 'Orange Money',
        'paymentStatus': 'SUCCESSFUL',
        'paymentDate': '2026-09-01T15:20:00Z',
        'transactionReference': 'TXN-OM-773412',
        'advertiserName': 'Zenith Beverages Marketing',
        'billboardName': 'Yaoundé Bastos Highway Screen',
      },
      {
        'paymentId': 503,
        'bookingId': 103,
        'amount': 85000.0,
        'paymentMethod': 'DigiPay Card',
        'paymentStatus': 'SUCCESSFUL',
        'paymentDate': '2026-08-30T09:10:00Z',
        'transactionReference': 'TXN-DP-338291',
        'advertiserName': 'Global Retail Group',
        'billboardName': 'Buea Town Campus Digital Board',
      },
    ];
  }

  List<AdvertisementModel> getMockAdvertisements() {
    return [
      AdvertisementModel(
        advertisementId: 201,
        title: 'SmartWatch X Brand Video',
        mediaUrl:
            'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
        mediaType: 'VIDEO',
        verificationStatus: 'APPROVED',
        aiConfidence: 0.98,
        createdAt: '2026-08-30T10:00:00Z',
        slotTime: '08:00 AM - 12:00 PM',
        duration: '4 Hours',
        playStartTime: '08:00',
        playEndTime: '12:00',
        progressPercentage: 65,
        status: 'RUNNING',
        billboardName: 'Douala Akwa Commercial LED',
      ),
      AdvertisementModel(
        advertisementId: 202,
        title: 'Mobile Banking Promo Poster',
        mediaUrl:
            'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?q=80&w=800',
        mediaType: 'IMAGE',
        verificationStatus: 'APPROVED',
        aiConfidence: 0.95,
        createdAt: '2026-08-31T09:15:00Z',
        slotTime: '02:00 PM - 06:00 PM',
        duration: '4 Hours',
        playStartTime: '14:00',
        playEndTime: '18:00',
        progressPercentage: 0,
        status: 'SCHEDULED',
        billboardName: 'Yaoundé Bastos Highway Screen',
      ),
      AdvertisementModel(
        advertisementId: 203,
        title: 'Grand Opening Billboard Teaser',
        mediaUrl:
            'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
        mediaType: 'VIDEO',
        verificationStatus: 'APPROVED',
        aiConfidence: 0.99,
        createdAt: '2026-08-28T14:00:00Z',
        slotTime: '06:00 PM - 10:00 PM',
        duration: '4 Hours',
        playStartTime: '18:00',
        playEndTime: '22:00',
        progressPercentage: 100,
        status: 'COMPLETED',
        billboardName: 'Buea Town Campus Digital Board',
      ),
    ];
  }

  String? _cachedMapsApiKey;

  Future<String?> getGoogleMapsApiKey() async {
    if (_cachedMapsApiKey != null && _cachedMapsApiKey!.isNotEmpty) {
      return _cachedMapsApiKey;
    }
    try {
      final res = await get(ApiConfig.configMapsKey);
      if (res['success'] == true && res['data'] != null) {
        final key = res['data']['apiKey']?.toString();
        if (key != null && key.isNotEmpty) {
          _cachedMapsApiKey = key;
          return key;
        }
      }
    } catch (_) {}
    return null;
  }
}
