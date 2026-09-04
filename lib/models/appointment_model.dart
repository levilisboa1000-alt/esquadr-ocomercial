import '../core/constants/app_enums.dart';

class AppointmentModel {
  final String id;
  final String leadId;
  final String operatorId;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String? notes;
  final String? googleCalendarEventId;
  final String? googleCalendarHtmlLink;
  final bool reminderSent24h;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentModel({
    required this.id,
    required this.leadId,
    required this.operatorId,
    required this.scheduledAt,
    this.status = AppointmentStatus.agendado,
    this.notes,
    this.googleCalendarEventId,
    this.googleCalendarHtmlLink,
    this.reminderSent24h = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      leadId: json['lead_id'] as String,
      operatorId: json['operator_id'] as String,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: AppointmentStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      googleCalendarEventId: json['google_calendar_event_id'] as String?,
      googleCalendarHtmlLink: json['google_calendar_html_link'] as String?,
      reminderSent24h: json['reminder_sent_24h'] as bool? ?? false,
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
      'lead_id': leadId,
      'operator_id': operatorId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': status.dbValue,
      'notes': notes,
      'google_calendar_event_id': googleCalendarEventId,
      'google_calendar_html_link': googleCalendarHtmlLink,
      'reminder_sent_24h': reminderSent24h,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  AppointmentModel copyWith({
    DateTime? scheduledAt,
    AppointmentStatus? status,
    String? notes,
    String? googleCalendarEventId,
    String? googleCalendarHtmlLink,
    bool? reminderSent24h,
  }) {
    return AppointmentModel(
      id: id,
      leadId: leadId,
      operatorId: operatorId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      googleCalendarEventId: googleCalendarEventId ?? this.googleCalendarEventId,
      googleCalendarHtmlLink: googleCalendarHtmlLink ?? this.googleCalendarHtmlLink,
      reminderSent24h: reminderSent24h ?? this.reminderSent24h,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
