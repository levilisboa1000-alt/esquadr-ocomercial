import '../core/constants/app_enums.dart';

class LeadHistoryModel {
  final String id;
  final String leadId;
  final String? userId;
  final String userName;
  final String action;
  final LeadStatus? oldStatus;
  final LeadStatus? newStatus;
  final String? notes;
  final DateTime createdAt;

  LeadHistoryModel({
    required this.id,
    required this.leadId,
    this.userId,
    this.userName = 'Sistema',
    required this.action,
    this.oldStatus,
    this.newStatus,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LeadHistoryModel.fromJson(Map<String, dynamic> json) {
    return LeadHistoryModel(
      id: json['id'] as String,
      leadId: json['lead_id'] as String,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String? ?? 'Sistema',
      action: json['action'] as String? ?? '',
      oldStatus: json['old_status'] != null
          ? LeadStatus.fromString(json['old_status'] as String)
          : null,
      newStatus: json['new_status'] != null
          ? LeadStatus.fromString(json['new_status'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'user_id': userId,
      'user_name': userName,
      'action': action,
      'old_status': oldStatus?.dbValue,
      'new_status': newStatus?.dbValue,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
