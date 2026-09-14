class UserModel {
  final int userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String role;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] is int
          ? json['userId']
          : int.parse(json['userId'].toString()),
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: (json['role'] ?? 'ADVERTISER').toString().toUpperCase(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
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
      'updatedAt': updatedAt,
    };
  }

  UserModel copyWith({String? fullName, String? email, String? phoneNumber}) {
    return UserModel(
      userId: userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
