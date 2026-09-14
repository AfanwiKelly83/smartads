class User {
  final int userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String role; // 'ADMIN', 'ADVERTISER', 'OWNER'
  final String? createdAt;

  User({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: (json['role'] ?? 'ADVERTISER').toString().toUpperCase(),
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'createdAt': createdAt,
    };
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isOwner => role == 'OWNER' || role == 'BILLBOARD_OWNER';
  bool get isAdvertiser => role == 'ADVERTISER';
}
