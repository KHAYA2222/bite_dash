// models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? deliveryAddress;
  final DateTime createdAt;
  final UserRole role; // customer | driver | admin
  final bool isAdmin; // Firestore-based admin flag
  final String? vehicleType; // bike | car | scooter
  final String? vehicleNumber; // licence plate

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.deliveryAddress,
    required this.createdAt,
    this.role = UserRole.customer,
    this.isAdmin = false,
    this.vehicleType,
    this.vehicleNumber,
  });

  bool get isDriver => role == UserRole.driver;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      role: UserRole.fromString(json['role'] as String? ?? 'customer'),
      isAdmin: json['isAdmin'] as bool? ?? false,
      vehicleType: json['vehicleType'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'deliveryAddress': deliveryAddress,
        'createdAt': createdAt.toIso8601String(),
        'role': role.value,
        'isAdmin': isAdmin,
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
      };

  UserModel copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? deliveryAddress,
    UserRole? role,
    bool? isAdmin,
    String? vehicleType,
    String? vehicleNumber,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        createdAt: createdAt,
        role: role ?? this.role,
        isAdmin: isAdmin ?? this.isAdmin,
        vehicleType: vehicleType ?? this.vehicleType,
        vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ── User role ─────────────────────────────────────────────────────────────────

enum UserRole {
  customer,
  driver,
  admin;

  static UserRole fromString(String s) {
    return UserRole.values.firstWhere(
      (r) => r.value == s,
      orElse: () => UserRole.customer,
    );
  }

  String get value {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.driver:
        return 'driver';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.driver:
        return 'Driver';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
