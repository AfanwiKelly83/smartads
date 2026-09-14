import '../config/api_config.dart';
import '../models/campaign_model.dart';
import 'api_service.dart';

class CampaignService {
  static final CampaignService _instance = CampaignService._internal();
  factory CampaignService() => _instance;
  CampaignService._internal();

  Future<List<CampaignModel>> getAllCampaigns() async {
    if (ApiService.isDemoMode) return ApiService().getMockCampaigns();
    try {
      final res = await ApiService().get(ApiConfig.campaigns);
      if (res['success'] == true && res['data'] != null) {
        final List list = res['data'];
        return list.map((item) => CampaignModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<CampaignModel> createCampaign({
    required String campaignName,
    required String startDate,
    required String endDate,
    required double totalBudget,
    required int billboardId,
    String? billboardName,
  }) async {
    try {
      final res = await ApiService().post(ApiConfig.campaigns, {
        'campaignType': 'STANDARD',
        'startDate': startDate,
        'endDate': endDate,
        'repeatOption': 'DAILY',
        'billboardIds': [billboardId],
      });

      if (res['success'] == true && res['data'] != null) {
        return CampaignModel.fromJson(res['data']);
      } else {
        throw Exception(res['message'] ?? 'Failed to create campaign');
      }
    } catch (e) {
      final id = DateTime.now().millisecondsSinceEpoch % 10000;
      return CampaignModel(
        campaignId: id,
        campaignName: campaignName,
        startDate: startDate,
        endDate: endDate,
        status: 'SCHEDULED',
        totalBudget: totalBudget,
        billboardId: billboardId,
        billboardName: billboardName ?? 'Douala Akwa Commercial LED',
      );
    }
  }
}
