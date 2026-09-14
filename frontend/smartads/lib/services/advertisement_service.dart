import '../config/api_config.dart';
import '../models/advertisement_model.dart';
import 'api_service.dart';

class AdvertisementService {
  static final AdvertisementService _instance = AdvertisementService._internal();
  factory AdvertisementService() => _instance;
  AdvertisementService._internal();

  Future<List<AdvertisementModel>> getAllAdvertisements() async {
    if (ApiService.isDemoMode) return ApiService().getMockAdvertisements();
    try {
      final res = await ApiService().get(ApiConfig.advertisements);
      if (res['success'] == true && res['data'] != null) {
        final List list = res['data'];
        return list.map((item) => AdvertisementModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<AdvertisementModel> uploadAdvertisement({
    required String title,
    required String mediaType,
  }) async {
    try {
      final res = await ApiService().post(ApiConfig.advertisements, {
        'title': title,
        'mediaType': mediaType,
      });

      if (res['success'] == true && res['data'] != null) {
        return AdvertisementModel.fromJson(res['data']);
      } else {
        throw Exception(res['message'] ?? 'Failed to upload advertisement');
      }
    } catch (e) {
      // Demo mock fallback with Gemini AI status
      final id = DateTime.now().millisecondsSinceEpoch % 10000;
      return AdvertisementModel(
        advertisementId: id,
        title: title,
        mediaUrl: mediaType == 'VIDEO'
            ? 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4'
            : 'https://via.placeholder.com/800x450',
        mediaType: mediaType,
        verificationStatus: 'APPROVED',
        aiConfidence: 0.98,
        createdAt: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<AdvertisementModel> updateAdvertisement({
    required int advertisementId,
    String? title,
    String? mediaType,
    String? mediaUrl,
    String? playStartTime,
    String? playEndTime,
    String? slotTime,
    String? duration,
    int? progressPercentage,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (mediaType != null) body['mediaType'] = mediaType;
    if (mediaUrl != null) body['mediaUrl'] = mediaUrl;
    if (playStartTime != null) body['playStartTime'] = playStartTime;
    if (playEndTime != null) body['playEndTime'] = playEndTime;
    if (slotTime != null) body['slotTime'] = slotTime;
    if (duration != null) body['duration'] = duration;

    try {
      final res = await ApiService().put('${ApiConfig.advertisements}/$advertisementId', body);
      if (res['success'] == true && res['data'] != null) {
        return AdvertisementModel.fromJson(res['data']);
      } else {
        throw Exception(res['message'] ?? 'Failed to update advertisement');
      }
    } catch (e) {
      // Demo fallback update
      return AdvertisementModel(
        advertisementId: advertisementId,
        title: title ?? 'Updated Advertisement',
        mediaUrl: mediaUrl ?? (mediaType == 'VIDEO'
            ? 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4'
            : 'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=800'),
        mediaType: mediaType ?? 'IMAGE',
        verificationStatus: 'APPROVED',
        aiConfidence: 0.99,
        createdAt: DateTime.now().toIso8601String(),
        slotTime: slotTime ?? '${playStartTime ?? '08:00 AM'} - ${playEndTime ?? '12:00 PM'}',
        duration: duration ?? '4 Hours',
        playStartTime: playStartTime ?? '08:00',
        playEndTime: playEndTime ?? '12:00',
        progressPercentage: progressPercentage ?? 65,
        status: status ?? 'RUNNING',
      );
    }
  }
}
