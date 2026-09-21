import '../config/api_config.dart';
import 'api_service.dart';

class BookingItemModel {
  final int bookingId;
  final int billboardId;
  final String billboardName;
  final String billboardLocation;
  final String billboardCode;
  final int advertiserId;
  final String advertiserName;
  final String advertiserEmail;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final double amount;
  final String status;
  final String? advertisementTitle;
  final String? advertisementMediaUrl;
  final String? advertisementMediaType;
  final String createdAt;

  BookingItemModel({
    required this.bookingId,
    required this.billboardId,
    required this.billboardName,
    this.billboardLocation = '',
    this.billboardCode = '',
    required this.advertiserId,
    required this.advertiserName,
    this.advertiserEmail = '',
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.amount,
    required this.status,
    this.advertisementTitle,
    this.advertisementMediaUrl,
    this.advertisementMediaType,
    required this.createdAt,
  });

  factory BookingItemModel.fromJson(Map<String, dynamic> json) {
    final billboard = json['Billboard'] ?? json['billboard'] ?? {};
    final advertiser = json['User'] ?? json['user'] ?? json['advertiser'] ?? {};
    final ad = json['Advertisement'] ?? json['advertisement'] ?? {};

    return BookingItemModel(
      bookingId: json['bookingId'] is int
          ? json['bookingId']
          : int.tryParse(json['bookingId']?.toString() ?? '0') ?? 0,
      billboardId: json['billboardId'] is int
          ? json['billboardId']
          : int.tryParse(json['billboardId']?.toString() ?? '0') ?? 0,
      billboardName: billboard['billboardName'] ?? json['billboardName'] ?? 'Billboard #${json['billboardId']}',
      billboardLocation: billboard['location'] ?? '',
      billboardCode: billboard['billboardCode'] ?? '',
      advertiserId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      advertiserName: advertiser['fullName'] ?? json['advertiserName'] ?? 'Advertiser',
      advertiserEmail: advertiser['email'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      startTime: json['startTime'] ?? '08:00',
      endTime: json['endTime'] ?? '10:00',
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : 30000.0,
      status: (json['status'] ?? 'CONFIRMED').toString().toUpperCase(),
      advertisementTitle: ad['title'] ?? json['advertisementTitle'],
      advertisementMediaUrl: ad['mediaUrl'] ?? ad['filePath'] ?? json['mediaUrl'],
      advertisementMediaType: ad['mediaType'] ?? json['mediaType'],
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  Future<List<BookingItemModel>> getOwnerBookings() async {
    try {
      final res = await ApiService().get('${ApiConfig.bookings}/owner-bookings');
      if (res['success'] == true && res['data'] != null) {
        final List list = res['data'];
        return list.map((item) => BookingItemModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      if (ApiService.isDemoMode) {
        return [
          BookingItemModel(
            bookingId: 101,
            billboardId: 1,
            billboardName: 'Smart TV #01 - Akwa LED Screen',
            billboardLocation: 'Akwa Boulevard, Douala',
            billboardCode: 'BILL-A001',
            advertiserId: 2,
            advertiserName: 'MTN Cameroon Promo',
            advertiserEmail: 'marketing@mtn.cm',
            startDate: '2026-09-20',
            endDate: '2026-09-20',
            startTime: '08:00',
            endTime: '12:00',
            amount: 60000,
            status: 'CONFIRMED',
            advertisementTitle: 'MTN 5G Promo Launch',
            advertisementMediaType: 'IMAGE',
            createdAt: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
          ),
          BookingItemModel(
            bookingId: 102,
            billboardId: 2,
            billboardName: 'Smart TV #02 - Bastos Display',
            billboardLocation: 'Bastos Junction, Yaoundé',
            billboardCode: 'BILL-B002',
            advertiserId: 3,
            advertiserName: 'Orange Money Flash',
            advertiserEmail: 'om@orange.cm',
            startDate: '2026-09-21',
            endDate: '2026-09-21',
            startTime: '14:00',
            endTime: '18:00',
            amount: 80000,
            status: 'PENDING',
            advertisementTitle: 'Orange Money 0% Fees Campaign',
            advertisementMediaType: 'VIDEO',
            createdAt: DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
          ),
        ];
      }
      rethrow;
    }
  }

  Future<List<BookingItemModel>> getAllBookings() async {
    try {
      final res = await ApiService().get(ApiConfig.bookings);
      if (res['success'] == true && res['data'] != null) {
        final List list = res['data'];
        return list.map((item) => BookingItemModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      if (ApiService.isDemoMode) {
        return [];
      }
      rethrow;
    }
  }
}
