class BillboardModel {
  final int billboardId;
  final String billboardCode;
  final int? ownerId;
  final String billboardName;
  final String location;
  final String? address;
  final String screenSize;
  final String billboardType;
  final String? width;
  final String? height;
  final String resolution;
  final double hourlyRate;
  final int maxActiveCampaigns;
  final String status;
  final String approvalStatus;
  final String availabilityStatus;
  final String operatingHours;
  final String description;
  final String? images;
  final String? videoDemo;
  final String? technicalSpecs;
  final String? additionalInfo;
  final String? qrCodeUrl;
  final String? latitude;
  final String? longitude;

  BillboardModel({
    required this.billboardId,
    this.billboardCode = '',
    this.ownerId,
    required this.billboardName,
    required this.location,
    this.address,
    required this.screenSize,
    this.billboardType = 'SMART_TV',
    this.width,
    this.height,
    this.resolution = '1920x1080',
    required this.hourlyRate,
    this.maxActiveCampaigns = 10,
    required this.status,
    this.approvalStatus = 'APPROVED',
    this.availabilityStatus = 'AVAILABLE',
    this.operatingHours = '06:00 - 22:00',
    this.description = 'Digital advertising display available for scheduled campaigns.',
    this.images,
    this.videoDemo,
    this.technicalSpecs,
    this.additionalInfo,
    this.qrCodeUrl,
    this.latitude,
    this.longitude,
  });

  factory BillboardModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['billboardId'] ?? json['id'] ?? 0;
    final bId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
    final code = (json['billboardCode'] ?? 'BILL-${String.fromCharCode(65 + (bId % 26))}${bId.toString().padLeft(3, '0')}').toString();
    final maxCampaignsRaw = json['maxActiveCampaigns'] ?? json['maxCapacity'] ?? 10;
    final maxCampaigns = maxCampaignsRaw is int ? maxCampaignsRaw : int.tryParse(maxCampaignsRaw.toString()) ?? 10;

    return BillboardModel(
      billboardId: bId,
      billboardCode: code,
      ownerId: json['ownerId'] is int ? json['ownerId'] : int.tryParse(json['ownerId']?.toString() ?? ''),
      billboardName: json['billboardName'] ?? '',
      location: json['location'] ?? '',
      address: json['address'],
      screenSize: json['screenSize'] ?? 'Smart TV HD (1920x1080)',
      billboardType: json['billboardType'] ?? 'SMART_TV',
      width: json['width']?.toString(),
      height: json['height']?.toString(),
      resolution: json['resolution'] ?? '1920x1080',
      hourlyRate: json['pricePerHour'] != null
          ? (json['pricePerHour'] as num).toDouble()
          : json['hourlyRate'] != null
          ? (json['hourlyRate'] as num).toDouble()
          : 15000.0,
      maxActiveCampaigns: maxCampaigns,
      status: json['displayStatus'] ?? json['status'] ?? 'ACTIVE',
      approvalStatus: (json['approvalStatus'] ?? 'APPROVED').toString().toUpperCase(),
      availabilityStatus: (json['availabilityStatus'] ?? 'AVAILABLE').toString().toUpperCase(),
      operatingHours: json['operatingHours'] ?? '06:00 - 22:00',
      description: json['description'] ?? json['advertisingInfo'] ?? 'Digital advertising display available for scheduled campaigns.',
      images: json['images'],
      videoDemo: json['videoDemo'],
      technicalSpecs: json['technicalSpecs'],
      additionalInfo: json['additionalInfo'],
      qrCodeUrl: json['qrCode'] ?? json['qrCodeUrl'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
    );
  }

  bool get isApproved => approvalStatus == 'APPROVED';
  bool get isPendingApproval => approvalStatus == 'PENDING_APPROVAL';
  bool get isRejected => approvalStatus == 'REJECTED';
  bool get isSuspended => approvalStatus == 'SUSPENDED' || approvalStatus == 'UNPUBLISHED';

  double? get lat => latitude != null ? double.tryParse(latitude!) : null;
  double? get lng => longitude != null ? double.tryParse(longitude!) : null;
  bool get hasCoordinates => lat != null && lng != null;
  String get googleMapsUrl => hasCoordinates
      ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
      : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}';

  Map<String, dynamic> toJson() {
    return {
      'billboardId': billboardId,
      'billboardCode': billboardCode,
      'ownerId': ownerId,
      'billboardName': billboardName,
      'location': location,
      'address': address,
      'screenSize': screenSize,
      'billboardType': billboardType,
      'width': width,
      'height': height,
      'resolution': resolution,
      'pricePerHour': hourlyRate,
      'maxActiveCampaigns': maxActiveCampaigns,
      'status': status,
      'approvalStatus': approvalStatus,
      'availabilityStatus': availabilityStatus,
      'operatingHours': operatingHours,
      'description': description,
      'images': images,
      'videoDemo': videoDemo,
      'technicalSpecs': technicalSpecs,
      'additionalInfo': additionalInfo,
      'qrCodeUrl': qrCodeUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
