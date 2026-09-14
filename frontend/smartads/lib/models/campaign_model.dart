class CampaignModel {
  final int campaignId;
  final String campaignName;
  final String startDate;
  final String endDate;
  final String status;
  final double totalBudget;
  final int billboardId;
  final String? billboardName;

  CampaignModel({
    required this.campaignId,
    required this.campaignName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalBudget,
    required this.billboardId,
    this.billboardName,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      campaignId: json['campaignId'] is int
          ? json['campaignId']
          : int.parse(json['campaignId'].toString()),
      campaignName: json['campaignName'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? 'SCHEDULED',
      totalBudget: json['totalBudget'] != null
          ? (json['totalBudget'] as num).toDouble()
          : 0.0,
      billboardId: json['billboardId'] is int
          ? json['billboardId']
          : int.tryParse(json['billboardId']?.toString() ?? '1') ?? 1,
      billboardName: json['billboardName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campaignId': campaignId,
      'campaignName': campaignName,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'totalBudget': totalBudget,
      'billboardId': billboardId,
      'billboardName': billboardName,
    };
  }
}
