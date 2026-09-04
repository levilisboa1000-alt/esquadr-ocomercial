import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/call_model.dart';
import '../core/constants/app_enums.dart';

class CallRepository {
  final SupabaseClient _supabase;

  CallRepository({required SupabaseClient supabase}) : _supabase = supabase;

  /// Registra uma chamada efetuada no banco
  Future<CallModel> recordCall({
    required String leadId,
    required String operatorId,
    required CallResult result,
    int attemptNumber = 1,
    int durationSeconds = 0,
    String? notes,
    DateTime? startedAt,
  }) async {
    final response = await _supabase.from('calls').insert({
      'lead_id': leadId,
      'operator_id': operatorId,
      'attempt_number': attemptNumber,
      'result': result.dbValue,
      'notes': notes,
      'duration_seconds': durationSeconds,
      'started_at': (startedAt ?? DateTime.now()).toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    return CallModel.fromJson(response);
  }

  /// Recupera as chamadas de um lead específico
  Future<List<CallModel>> getCallsForLead(String leadId) async {
    final response = await _supabase
        .from('calls')
        .select()
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => CallModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Quantidade de chamadas feitas por um operador hoje
  Future<int> getOperatorCallsToday(String operatorId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    final response = await _supabase
        .from('calls')
        .select('id')
        .eq('operator_id', operatorId)
        .gte('created_at', startOfDay);

    return (response as List).length;
  }
}
