import '../config/api_config.dart';
import '../models/billboard_model.dart';
import 'api_service.dart';

class BillboardService {
  static final BillboardService _instance = BillboardService._internal();
  factory BillboardService() => _instance;
  BillboardService._internal();

  Future<List<BillboardModel>> getAllBillboards({bool includePending = false, String? search}) async {
    if (ApiService.isDemoMode) return ApiService().getMockBillboards();
    try {
      String url = ApiConfig.billboards;
      final List<String> params = [];
      if (includePending) params.add('all=true');
      if (search != null && search.isNotEmpty) params.add('search=${Uri.encodeComponent(search)}');
      if (params.isNotEmpty) url = '$url?${params.join('&')}';

      final res = await ApiService().get(url);
      if (res['success'] == true && res['data'] != null) {
        final List list = res['data'];
        return list.map((item) => BillboardModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BillboardModel>> getMyBillboards() async {
    try {
      final res = await ApiService().get('${ApiConfig.billboards}/my-billboards');
      if (res['success'] == true && res['data'] != null) {
        final List list = res['data'];
        return list.map((item) => BillboardModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<BillboardModel?> getBillboardById(dynamic idOrCode) async {
    if (ApiService.isDemoMode) {
      final mock = ApiService().getMockBillboards();
      return mock.firstWhere(
        (b) => b.billboardId.toString() == idOrCode.toString() || b.billboardCode == idOrCode.toString(),
        orElse: () => mock.first,
      );
    }
    try {
      final res = await ApiService().get('${ApiConfig.billboards}/$idOrCode');
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
    String? address,
    String? description,
    String? billboardType,
    String? width,
    String? height,
    String? resolution,
    required double pricePerHour,
    int? maxActiveCampaigns,
    String? operatingHours,
    String? images,
    String? videoDemo,
    String? technicalSpecs,
    String? additionalInfo,
    String? screenSize,
    String? latitude,
    String? longitude,
  }) async {
    final res = await ApiService().post(ApiConfig.billboards, {
      'billboardName': billboardName,
      'location': location,
      'address': address ?? location,
      'description': description ?? 'Digital advertising display available for scheduled campaigns.',
      'billboardType': billboardType ?? 'SMART_TV',
      'width': width ?? '1920',
      'height': height ?? '1080',
      'resolution': resolution ?? '1920x1080',
      'pricePerHour': pricePerHour,
      if (maxActiveCampaigns != null) 'maxActiveCampaigns': maxActiveCampaigns,
      'operatingHours': operatingHours ?? '06:00 - 22:00',
      'images': images,
      'videoDemo': videoDemo,
      'technicalSpecs': technicalSpecs,
      'additionalInfo': additionalInfo,
      'screenSize': screenSize ?? 'Smart TV HD (1920x1080)',
      'latitude': latitude,
      'longitude': longitude,
    });

    if (res['success'] == true && res['data'] != null) {
      return BillboardModel.fromJson(res['data']);
    }

    throw Exception(res['message'] ?? 'Failed to create billboard');
  }

  Future<BillboardModel> updateApprovalStatus(int billboardId, String status, {String? notes}) async {
    final res = await ApiService().put('${ApiConfig.billboards}/$billboardId/approval', {
      'status': status,
      if (notes != null) 'notes': notes,
    });

    if (res['success'] == true && res['data'] != null) {
      return BillboardModel.fromJson(res['data']);
    }
    throw Exception(res['message'] ?? 'Failed to update approval status');
  }

  Future<BillboardModel> updateBillboard({
    required int billboardId,
    String? billboardName,
    String? location,
    String? address,
    String? description,
    String? billboardType,
    String? width,
    String? height,
    String? resolution,
    double? pricePerHour,
    int? maxActiveCampaigns,
    String? operatingHours,
    String? displayStatus,
    String? availabilityStatus,
    String? screenSize,
    String? latitude,
    String? longitude,
  }) async {
    final Map<String, dynamic> body = {};
    if (billboardName != null) body['billboardName'] = billboardName;
    if (location != null) body['location'] = location;
    if (address != null) body['address'] = address;
    if (description != null) body['description'] = description;
    if (billboardType != null) body['billboardType'] = billboardType;
    if (width != null) body['width'] = width;
    if (height != null) body['height'] = height;
    if (resolution != null) body['resolution'] = resolution;
    if (pricePerHour != null) body['pricePerHour'] = pricePerHour;
    if (maxActiveCampaigns != null) body['maxActiveCampaigns'] = maxActiveCampaigns;
    if (operatingHours != null) body['operatingHours'] = operatingHours;
    if (displayStatus != null) body['displayStatus'] = displayStatus;
    if (availabilityStatus != null) body['availabilityStatus'] = availabilityStatus;
    if (screenSize != null) body['screenSize'] = screenSize;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final res = await ApiService().put('${ApiConfig.billboards}/$billboardId', body);
    if (res['success'] == true && res['data'] != null) {
      return BillboardModel.fromJson(res['data']);
    }
    throw Exception(res['message'] ?? 'Failed to update billboard');
  }

  Future<bool> deleteBillboard(int billboardId) async {
    try {
      final res = await ApiService().delete('${ApiConfig.billboards}/$billboardId');
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
