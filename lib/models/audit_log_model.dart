import '../core/constants/app_enums.dart';

class AuditLogModel {
  final String id;
  final String? userId;
  final String userName;
  final UserRole? role;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    this.userId,
    this.userName = 'Sistema',
    this.role,
    required this.action,
    required this.entityType,
    this.entityId,
    this.oldValue,
    this.newValue,
    this.ipAddress,
    this.userAgent,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String? ?? 'Sistema',
      role: json['role'] != null ? UserRole.fromString(json['role'] as String) : null,
      action: json['action'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? 'general',
      entityId: json['entity_id'] as String?,
      oldValue: json['old_value'] is Map<String, dynamic>
          ? json['old_value'] as Map<String, dynamic>
          : null,
      newValue: json['new_value'] is Map<String, dynamic>
          ? json['new_value'] as Map<String, dynamic>
          : null,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'role': role?.dbValue,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_value': oldValue,
      'new_value': newValue,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
