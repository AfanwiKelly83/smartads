class BillboardModel {
  final int billboardId;
  final String billboardName;
  final String location;
  final String screenSize;
  final double hourlyRate;
  final String status;
  final String availabilityStatus;
  final String description;
  final String? qrCodeUrl;
  final String? latitude;
  final String? longitude;

  BillboardModel({
    required this.billboardId,
    required this.billboardName,
    required this.location,
    required this.screenSize,
    required this.hourlyRate,
    required this.status,
    this.availabilityStatus = 'AVAILABLE',
    this.description =
        'Digital advertising display available for scheduled campaigns.',
    this.qrCodeUrl,
    this.latitude,
    this.longitude,
  });

  factory BillboardModel.fromJson(Map<String, dynamic> json) {
    return BillboardModel(
      billboardId: json['billboardId'] is int
          ? json['billboardId']
          : int.parse(json['billboardId'].toString()),
      billboardName: json['billboardName'] ?? '',
      location: json['location'] ?? '',
      screenSize: json['screenSize'] ?? '4K UHD (3840x2160)',
      hourlyRate: json['pricePerHour'] != null
          ? (json['pricePerHour'] as num).toDouble()
          : json['hourlyRate'] != null
          ? (json['hourlyRate'] as num).toDouble()
          : 50.0,
      status: json['displayStatus'] ?? json['status'] ?? 'ACTIVE',
      availabilityStatus: (json['availabilityStatus'] ?? 'AVAILABLE')
          .toString()
          .toUpperCase(),
      description:
          json['description'] ??
          json['advertisingInfo'] ??
          'Digital advertising display available for scheduled campaigns.',
      qrCodeUrl: json['qrCode'] ?? json['qrCodeUrl'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'billboardId': billboardId,
      'billboardName': billboardName,
      'location': location,
      'screenSize': screenSize,
      'hourlyRate': hourlyRate,
      'status': status,
      'availabilityStatus': availabilityStatus,
      'description': description,
      'qrCodeUrl': qrCodeUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
