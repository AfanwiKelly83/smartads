import '../config/api_config.dart';
import 'api_service.dart';

class OwnerEarningsSummary {
  final double totalEarnings;
  final double pendingEarnings;
  final int totalTransactions;
  final List<OwnerPaymentItem> payments;

  OwnerEarningsSummary({
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.totalTransactions,
    required this.payments,
  });

  factory OwnerEarningsSummary.fromJson(Map<String, dynamic> json) {
    final list = (json['payments'] as List?) ?? [];
    return OwnerEarningsSummary(
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      pendingEarnings: (json['pendingEarnings'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? list.length,
      payments: list.map((p) => OwnerPaymentItem.fromJson(p)).toList(),
    );
  }
}

class OwnerPaymentItem {
  final int paymentId;
  final int bookingId;
  final double amount;
  final String paymentMethod;
  final String status;
  final String transactionReference;
  final String? billboardName;
  final String? billboardCode;
  final String? advertiserName;
  final String createdAt;

  OwnerPaymentItem({
    required this.paymentId,
    required this.bookingId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.transactionReference,
    this.billboardName,
    this.billboardCode,
    this.advertiserName,
    required this.createdAt,
  });

  factory OwnerPaymentItem.fromJson(Map<String, dynamic> json) {
    final booking = json['Booking'] ?? json['booking'] ?? {};
    final billboard = booking['Billboard'] ?? booking['billboard'] ?? {};
    final advertiser = booking['User'] ?? booking['user'] ?? {};

    return OwnerPaymentItem(
      paymentId: json['paymentId'] is int
          ? json['paymentId']
          : int.tryParse(json['paymentId']?.toString() ?? '0') ?? 0,
      bookingId: json['bookingId'] is int
          ? json['bookingId']
          : int.tryParse(json['bookingId']?.toString() ?? '0') ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? 'MOMO',
      status: (json['status'] ?? 'COMPLETED').toString().toUpperCase(),
      transactionReference: json['transactionReference'] ?? 'TXN-${json['paymentId']}',
      billboardName: billboard['billboardName'],
      billboardCode: billboard['billboardCode'],
      advertiserName: advertiser['fullName'],
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  Future<OwnerEarningsSummary> getOwnerEarnings() async {
    try {
      final res = await ApiService().get('${ApiConfig.payments}/owner-earnings');
      if (res['success'] == true && res['data'] != null) {
        return OwnerEarningsSummary.fromJson(res['data']);
      }
      return OwnerEarningsSummary(
        totalEarnings: 0,
        pendingEarnings: 0,
        totalTransactions: 0,
        payments: [],
      );
    } catch (e) {
      if (ApiService.isDemoMode) {
        return OwnerEarningsSummary(
          totalEarnings: 450000,
          pendingEarnings: 80000,
          totalTransactions: 3,
          payments: [
            OwnerPaymentItem(
              paymentId: 1,
              bookingId: 101,
              amount: 60000,
              paymentMethod: 'MTN_MOMO',
              status: 'COMPLETED',
              transactionReference: 'TXN-MOMO-98472',
              billboardName: 'Smart TV #01 - Akwa LED Screen',
              billboardCode: 'BILL-A001',
              advertiserName: 'MTN Cameroon Promo',
              createdAt: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
            ),
            OwnerPaymentItem(
              paymentId: 2,
              bookingId: 102,
              amount: 140000,
              paymentMethod: 'ORANGE_MONEY',
              status: 'COMPLETED',
              transactionReference: 'TXN-OM-10293',
              billboardName: 'Smart TV #02 - Bastos Display',
              billboardCode: 'BILL-B002',
              advertiserName: 'Orange Money Flash',
              createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            ),
            OwnerPaymentItem(
              paymentId: 3,
              bookingId: 103,
              amount: 80000,
              paymentMethod: 'MTN_MOMO',
              status: 'PENDING',
              transactionReference: 'TXN-MOMO-38192',
              billboardName: 'Smart TV #01 - Akwa LED Screen',
              billboardCode: 'BILL-A001',
              advertiserName: 'UBA Bank Cameroon',
              createdAt: DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
            ),
          ],
        );
      }
      rethrow;
    }
  }
}
