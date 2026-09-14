class AdvertisementModel {
  final int advertisementId;
  final String title;
  final String mediaUrl;
  final String mediaType; // IMAGE, VIDEO
  final String verificationStatus; // APPROVED, REJECTED, PENDING
  final double aiConfidence;
  final String? rejectionReason;
  final String createdAt;
  final String slotTime;
  final String duration;
  final String playStartTime;
  final String playEndTime;
  final int progressPercentage; // 0 for upcoming, 1-99 for running, 100 for completed
  final String status; // RUNNING, SCHEDULED, COMPLETED
  final String? billboardName;

  AdvertisementModel({
    required this.advertisementId,
    required this.title,
    required this.mediaUrl,
    required this.mediaType,
    required this.verificationStatus,
    required this.aiConfidence,
    this.rejectionReason,
    required this.createdAt,
    this.slotTime = '08:00 AM - 12:00 PM',
    this.duration = '4 Hours',
    this.playStartTime = '08:00',
    this.playEndTime = '12:00',
    this.progressPercentage = 0,
    this.status = 'SCHEDULED',
    this.billboardName,
  });

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    final int prog = json['progressPercentage'] is int
        ? json['progressPercentage']
        : int.tryParse(json['progressPercentage']?.toString() ?? '0') ?? 0;

    return AdvertisementModel(
      advertisementId: json['advertisementId'] is int
          ? json['advertisementId']
          : int.tryParse(json['advertisementId']?.toString() ?? '1') ?? 1,
      title: json['title'] ?? '',
      mediaUrl: json['mediaUrl'] ?? json['filePath'] ?? '',
      mediaType: (json['mediaType'] ?? 'IMAGE').toString().toUpperCase(),
      verificationStatus: (json['verificationStatus'] ?? json['approvalStatus'] ?? 'APPROVED').toString().toUpperCase(),
      aiConfidence: json['aiConfidence'] != null
          ? (json['aiConfidence'] as num).toDouble()
          : 0.95,
      rejectionReason: json['rejectionReason'],
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      slotTime: json['slotTime'] ?? '${json['playStartTime'] ?? '08:00 AM'} - ${json['playEndTime'] ?? '12:00 PM'}',
      duration: json['duration'] ?? '4 Hours',
      playStartTime: json['playStartTime'] ?? '08:00',
      playEndTime: json['playEndTime'] ?? '12:00',
      progressPercentage: prog,
      status: json['status'] ?? (prog == 0 ? 'SCHEDULED' : (prog >= 100 ? 'COMPLETED' : 'RUNNING')),
      billboardName: json['billboardName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advertisementId': advertisementId,
      'title': title,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'verificationStatus': verificationStatus,
      'aiConfidence': aiConfidence,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
      'slotTime': slotTime,
      'duration': duration,
      'playStartTime': playStartTime,
      'playEndTime': playEndTime,
      'progressPercentage': progressPercentage,
      'status': status,
      'billboardName': billboardName,
    };
  }

  AdvertisementModel copyWith({
    String? title,
    String? mediaUrl,
    String? mediaType,
    String? verificationStatus,
    double? aiConfidence,
    String? slotTime,
    String? duration,
    String? playStartTime,
    String? playEndTime,
    int? progressPercentage,
    String? status,
    String? billboardName,
  }) {
    return AdvertisementModel(
      advertisementId: advertisementId,
      title: title ?? this.title,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      rejectionReason: rejectionReason,
      createdAt: createdAt,
      slotTime: slotTime ?? this.slotTime,
      duration: duration ?? this.duration,
      playStartTime: playStartTime ?? this.playStartTime,
      playEndTime: playEndTime ?? this.playEndTime,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      status: status ?? this.status,
      billboardName: billboardName ?? this.billboardName,
    );
  }
}
