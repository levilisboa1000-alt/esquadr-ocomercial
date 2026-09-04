import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/lead_model.dart';
import '../../models/user_model.dart';
import '../voicemail/voicemail_scheduler_service.dart';
import '../audit/audit_service.dart';

abstract class ILeadDistributionStrategy {
  Future<List<LeadModel>> fetchNextBatch({
    required SupabaseClient supabase,
    required UserModel operator,
    int batchSize = 10,
  });
}

/// Estratégia padrão baseada em fila central com SKIP LOCKED no PostgreSQL
class CentralQueueStrategy implements ILeadDistributionStrategy {
  @override
  Future<List<LeadModel>> fetchNextBatch({
    required SupabaseClient supabase,
    required UserModel operator,
    int batchSize = 10,
  }) async {
    try {
      // 1. Invoca a RPC atômica anti-colisão do PostgreSQL
      final response = await supabase.rpc(
        'distribute_leads_to_operator',
        params: {
          'p_operator_id': operator.id,
          'p_limit': batchSize,
        },
      );

      if (response is List) {
        return response
            .map((json) => LeadModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar lote da fila central via RPC: $e');

      // Fallback gracioso: busca leads já atribuídos ao operador que estão ativos
      final assignedResponse = await supabase
          .from('leads')
          .select()
          .eq('assigned_operator_id', operator.id)
          .inFilter('status', ['NOVO', 'DISTRIBUIDO', 'EM_ATENDIMENTO'])
          .order('priority', ascending: false)
          .order('attempt_count', ascending: true)
          .limit(batchSize);

      return (assignedResponse as List)
          .map((json) => LeadModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }
}

class LeadDistributionService {
  final SupabaseClient _supabase;
  final VoicemailSchedulerService _voicemailService;
  final AuditService _auditService;
  ILeadDistributionStrategy _strategy;

  LeadDistributionService({
    required SupabaseClient supabase,
    required VoicemailSchedulerService voicemailService,
    required AuditService auditService,
    ILeadDistributionStrategy? strategy,
  })  : _supabase = supabase,
        _voicemailService = voicemailService,
        _auditService = auditService,
        _strategy = strategy ?? CentralQueueStrategy();

  /// Permite trocar o algoritmo de distribuição em tempo de execução
  void setStrategy(ILeadDistributionStrategy newStrategy) {
    _strategy = newStrategy;
  }

  /// Solicita o próximo lote de leads da fila central para o operador
  Future<List<LeadModel>> getLeadsForOperator({
    required UserModel operator,
    int limit = 10,
  }) async {
    // 1. Antes de distribuir, reconcilia se há leads de Caixa Postal prontos para retornar
    await _voicemailService.reconcileOverdueVoicemails();

    // 2. Busca o lote atômico seguro
    final leads = await _strategy.fetchNextBatch(
      supabase: _supabase,
      operator: operator,
      batchSize: limit,
    );

    if (leads.isNotEmpty) {
      await _auditService.log(
        action: 'LEADS_DISTRIBUTED',
        entityType: 'distribution',
        entityId: operator.id,
        notes: '${leads.length} leads entregues para o operador ${operator.fullName}',
      );
    }

    return leads;
  }

  /// Devolve um lead de volta para a fila central para ser atendido por outro operador
  Future<void> returnLeadToCentralQueue({
    required String leadId,
    required String reason,
    String? operatorId,
  }) async {
    await _supabase.from('leads').update({
      'status': 'RETORNAR_PARA_FILA',
      'assigned_operator_id': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', leadId);

    await _supabase.from('lead_history').insert({
      'lead_id': leadId,
      'user_id': operatorId,
      'action': 'Devolvido para a Fila Central',
      'old_status': 'DISTRIBUIDO',
      'new_status': 'RETORNAR_PARA_FILA',
      'notes': reason,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _auditService.log(
      action: 'LEAD_RETURNED_TO_QUEUE',
      entityType: 'lead',
      entityId: leadId,
      notes: 'Motivo: $reason',
    );
  }

  /// Redistribui manualmente um lead para um operador específico (Ação de Supervisor/Admin)
  Future<void> reassignLead({
    required String leadId,
    required String targetOperatorId,
    required String targetOperatorName,
    required String adminId,
  }) async {
    await _supabase.from('leads').update({
      'assigned_operator_id': targetOperatorId,
      'status': 'DISTRIBUIDO',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', leadId);

    await _supabase.from('lead_history').insert({
      'lead_id': leadId,
      'user_id': adminId,
      'action': 'Redistribuído manualmente',
      'notes': 'Atribuído para $targetOperatorName',
      'created_at': DateTime.now().toIso8601String(),
    });

    await _auditService.log(
      action: 'LEAD_REASSIGNED',
      entityType: 'lead',
      entityId: leadId,
      notes: 'Atribuído para operador $targetOperatorName (ID: $targetOperatorId)',
    );
  }
}
