import '../config/api_config.dart';
import '../models/billboard_model.dart';
import 'api_service.dart';

class BillboardService {
  static final BillboardService _instance = BillboardService._internal();
  factory BillboardService() => _instance;
  BillboardService._internal();

  Future<List<BillboardModel>> getAllBillboards() async {
    if (ApiService.isDemoMode) return ApiService().getMockBillboards();
    try {
      final res = await ApiService().get(ApiConfig.billboards);
      if (res['success'] == true && res['data'] != null) {
        final List list = res['data'];
        return list.map((item) => BillboardModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<BillboardModel?> getBillboardById(int id) async {
    if (ApiService.isDemoMode) {
      final mock = ApiService().getMockBillboards();
      return mock.firstWhere(
        (b) => b.billboardId == id,
        orElse: () => mock.first,
      );
    }
    try {
      final res = await ApiService().get('${ApiConfig.billboards}/$id');
      if (res['success'] == true && res['data'] != null) {
        return BillboardModel.fromJson(res['data']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<BillboardModel> createBillboard({
    required String billboardName,
    required String location,
    required double pricePerHour,
    String? screenSize,
    String? resolution,
    String? latitude,
    String? longitude,
  }) async {
    final res = await ApiService().post(ApiConfig.billboards, {
      'billboardName': billboardName,
      'location': location,
      'pricePerHour': pricePerHour,
      'screenSize': screenSize ?? '4K UHD (3840x2160)',
      'resolution': resolution ?? '3840x2160',
      'latitude': latitude,
      'longitude': longitude,
    });

    if (res['success'] == true && res['data'] != null) {
      return BillboardModel.fromJson(res['data']);
    }

    throw Exception(res['message'] ?? 'Failed to create billboard');
  }
}
