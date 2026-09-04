import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import '../models/lead_history_model.dart';
import '../core/constants/app_enums.dart';

class LeadRepository {
  final SupabaseClient _supabase;

  LeadRepository({required SupabaseClient supabase}) : _supabase = supabase;

  /// Busca leads filtrados para a Central de Operações com paginação
  Future<List<LeadModel>> getLeads({
    String? searchQuery,
    LeadStatus? status,
    String? assignedOperatorId,
    String? city,
    String? source,
    int page = 0,
    int pageSize = 25,
  }) async {
    var query = _supabase.from('leads').select();

    if (status != null) {
      query = query.eq('status', status.dbValue);
    }

    if (assignedOperatorId != null && assignedOperatorId.isNotEmpty) {
      query = query.eq('assigned_operator_id', assignedOperatorId);
    }

    if (city != null && city.isNotEmpty) {
      query = query.ilike('city', '%$city%');
    }

    if (source != null && source.isNotEmpty) {
      query = query.eq('source', source);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = searchQuery.trim();
      query = query.or('name.ilike.%$term%,phone.ilike.%$term%,interest.ilike.%$term%');
    }

    final from = page * pageSize;
    final to = from + pageSize - 1;

    final response = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return (response as List)
        .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Recupera um lead específico pelo seu ID
  Future<LeadModel?> getLeadById(String id) async {
    final response = await _supabase
        .from('leads')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return LeadModel.fromJson(response);
  }

  /// Atualiza dados cadastrais de um lead
  Future<LeadModel> updateLead(LeadModel lead) async {
    final response = await _supabase
        .from('leads')
        .update(lead.toJson())
        .eq('id', lead.id)
        .select()
        .single();

    return LeadModel.fromJson(response);
  }

  /// Remove um lead do sistema (apenas Admin)
  Future<void> deleteLead(String id) async {
    await _supabase.from('leads').delete().eq('id', id);
  }

  /// Recupera a linha do tempo / histórico do lead
  Future<List<LeadHistoryModel>> getLeadHistory(String leadId) async {
    final response = await _supabase
        .from('lead_history')
        .select()
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => LeadHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Adiciona uma entrada no histórico do lead
  Future<void> addHistoryEntry({
    required String leadId,
    required String action,
    String? userId,
    String? userName,
    LeadStatus? oldStatus,
    LeadStatus? newStatus,
    String? notes,
  }) async {
    await _supabase.from('lead_history').insert({
      'lead_id': leadId,
      'user_id': userId,
      'user_name': userName ?? 'Sistema',
      'action': action,
      'old_status': oldStatus?.dbValue,
      'new_status': newStatus?.dbValue,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
