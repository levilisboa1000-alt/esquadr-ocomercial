import '../core/constants/app_enums.dart';

class CallModel {
  final String id;
  final String leadId;
  final String operatorId;
  final int attemptNumber;
  final CallResult result;
  final String? notes;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime createdAt;

  CallModel({
    required this.id,
    required this.leadId,
    required this.operatorId,
    this.attemptNumber = 1,
    required this.result,
    this.notes,
    this.durationSeconds = 0,
    DateTime? startedAt,
    DateTime? createdAt,
  })  : startedAt = startedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'] as String,
      leadId: json['lead_id'] as String,
      operatorId: json['operator_id'] as String,
      attemptNumber: json['attempt_number'] as int? ?? 1,
      result: CallResult.fromString(json['result'] as String?),
      notes: json['notes'] as String?,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'operator_id': operatorId,
      'attempt_number': attemptNumber,
      'result': result.dbValue,
      'notes': notes,
      'duration_seconds': durationSeconds,
      'started_at': startedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
