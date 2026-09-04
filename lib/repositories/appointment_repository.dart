import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment_model.dart';
import '../core/constants/app_enums.dart';

class AppointmentRepository {
  final SupabaseClient _supabase;

  AppointmentRepository({required SupabaseClient supabase}) : _supabase = supabase;

  /// Cria um novo agendamento no banco
  Future<AppointmentModel> createAppointment({
    required String leadId,
    required String operatorId,
    required DateTime scheduledAt,
    String? notes,
    String? googleCalendarEventId,
  }) async {
    final response = await _supabase.from('appointments').insert({
      'lead_id': leadId,
      'operator_id': operatorId,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'status': AppointmentStatus.agendado.dbValue,
      'notes': notes,
      'google_calendar_event_id': googleCalendarEventId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).select().single();

    return AppointmentModel.fromJson(response);
  }

  /// Atualiza o status do agendamento
  Future<AppointmentModel> updateStatus(String appointmentId, AppointmentStatus newStatus) async {
    final response = await _supabase
        .from('appointments')
        .update({
          'status': newStatus.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', appointmentId)
        .select()
        .single();

    return AppointmentModel.fromJson(response);
  }

  /// Busca agendamentos com filtros (por data, operador, status)
  Future<List<AppointmentModel>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
    String? operatorId,
    AppointmentStatus? status,
  }) async {
    var query = _supabase.from('appointments').select();

    if (operatorId != null && operatorId.isNotEmpty) {
      query = query.eq('operator_id', operatorId);
    }

    if (status != null) {
      query = query.eq('status', status.dbValue);
    }

    if (startDate != null) {
      query = query.gte('scheduled_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('scheduled_at', endDate.toIso8601String());
    }

    final response = await query.order('scheduled_at', ascending: true);

    return (response as List)
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
