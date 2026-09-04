import '../core/constants/app_enums.dart';

class LeadModel {
  final String id;
  final String name;
  final String phone;
  final String city;
  final String state;
  final String interest;
  final double propertyValue;
  final String source;
  final String? notes;
  final LeadStatus status;
  final LeadPriority priority;
  final String? assignedOperatorId;
  final int attemptCount;
  final DateTime? lastContactAt;
  final DateTime? nextActionAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeadModel({
    required this.id,
    required this.name,
    required this.phone,
    this.city = '',
    this.state = '',
    this.interest = '',
    this.propertyValue = 0.0,
    this.source = 'Outros',
    this.notes,
    this.status = LeadStatus.novo,
    this.priority = LeadPriority.normal,
    this.assignedOperatorId,
    this.attemptCount = 0,
    this.lastContactAt,
    this.nextActionAt,
    this.metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Sem Nome',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      interest: json['interest'] as String? ?? '',
      propertyValue: (json['property_value'] != null)
          ? double.tryParse(json['property_value'].toString()) ?? 0.0
          : 0.0,
      source: json['source'] as String? ?? 'Outros',
      notes: json['notes'] as String?,
      status: LeadStatus.fromString(json['status'] as String?),
      priority: LeadPriority.fromString(json['priority'] as String?),
      assignedOperatorId: json['assigned_operator_id'] as String?,
      attemptCount: json['attempt_count'] as int? ?? 0,
      lastContactAt: json['last_contact_at'] != null
          ? DateTime.tryParse(json['last_contact_at'] as String)
          : null,
      nextActionAt: json['next_action_at'] != null
          ? DateTime.tryParse(json['next_action_at'] as String)
          : null,
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : const {},
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
      'name': name,
      'phone': phone,
      'city': city,
      'state': state,
      'interest': interest,
      'property_value': propertyValue,
      'source': source,
      'notes': notes,
      'status': status.dbValue,
      'priority': priority.dbValue,
      'assigned_operator_id': assignedOperatorId,
      'attempt_count': attemptCount,
      'last_contact_at': lastContactAt?.toIso8601String(),
      'next_action_at': nextActionAt?.toIso8601String(),
      'metadata': metadata,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  LeadModel copyWith({
    String? name,
    String? phone,
    String? city,
    String? state,
    String? interest,
    double? propertyValue,
    String? source,
    String? notes,
    LeadStatus? status,
    LeadPriority? priority,
    String? assignedOperatorId,
    bool clearAssignedOperator = false,
    int? attemptCount,
    DateTime? lastContactAt,
    DateTime? nextActionAt,
    bool clearNextActionAt = false,
    Map<String, dynamic>? metadata,
  }) {
    return LeadModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      state: state ?? this.state,
      interest: interest ?? this.interest,
      propertyValue: propertyValue ?? this.propertyValue,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedOperatorId: clearAssignedOperator
          ? null
          : (assignedOperatorId ?? this.assignedOperatorId),
      attemptCount: attemptCount ?? this.attemptCount,
      lastContactAt: lastContactAt ?? this.lastContactAt,
      nextActionAt: clearNextActionAt
          ? null
          : (nextActionAt ?? this.nextActionAt),
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
