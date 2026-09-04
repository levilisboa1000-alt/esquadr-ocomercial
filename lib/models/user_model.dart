import '../core/constants/app_enums.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final bool isOnline;
  final String? teamId;
  final int dailyLeadGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.isOnline = false,
    this.teamId,
    this.dailyLeadGoal = 30,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isAdmin => role == UserRole.admin;
  bool get isSupervisor => role == UserRole.supervisor;
  bool get isOperator => role == UserRole.operator;
  bool get canAccessAdminPanel => isAdmin || isSupervisor;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Usuário',
      role: UserRole.fromString(json['role'] as String?),
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      teamId: json['team_id'] as String?,
      dailyLeadGoal: json['daily_lead_goal'] as int? ?? 30,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.dbValue,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
      'team_id': teamId,
      'daily_lead_goal': dailyLeadGoal,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  UserModel copyWith({
    String? email,
    String? fullName,
    UserRole? role,
    String? phone,
    String? avatarUrl,
    bool? isOnline,
    String? teamId,
    int? dailyLeadGoal,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      teamId: teamId ?? this.teamId,
      dailyLeadGoal: dailyLeadGoal ?? this.dailyLeadGoal,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
