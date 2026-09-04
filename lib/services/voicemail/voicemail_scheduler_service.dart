import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/lead_model.dart';
import '../../core/constants/app_enums.dart';
import '../audit/audit_service.dart';

class VoicemailSchedulerService {
  final SupabaseClient _supabase;
  final AuditService _auditService;
  Timer? _pollingTimer;

  VoicemailSchedulerService({
    required SupabaseClient supabase,
    required AuditService auditService,
  })  : _supabase = supabase,
        _auditService = auditService;

  /// Inicia ou reinicia o reconciliador periódico no cliente (a cada 60s)
  /// para reforçar a execução do cron do backend PostgreSQL
  void startPeriodicReconciliation() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      reconcileOverdueVoicemails();
    });
  }

  void stopPeriodicReconciliation() {
    _pollingTimer?.cancel();
  }

  /// Marca o lead como Caixa Postal com timestamp de retorno de 30 minutos (ou configurado)
  Future<LeadModel> markLeadAsVoicemail({
    required LeadModel lead,
    required String operatorId,
    int voicemailReturnMinutes = 30,
    String? notes,
  }) async {
    final returnTimestamp = DateTime.now().add(Duration(minutes: voicemailReturnMinutes));

    // 1. Atualiza o lead no banco de dados
    await _supabase.from('leads').update({
      'status': LeadStatus.caixaPostal.dbValue,
      'next_action_at': returnTimestamp.toUtc().toIso8601String(),
      'attempt_count': lead.attemptCount + 1,
      'last_contact_at': DateTime.now().toUtc().toIso8601String(),
      // Remove o operador da atribuição direta para que saia imediatamente da fila dele
      'assigned_operator_id': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', lead.id);

    // 2. Grava histórico
    await _supabase.from('lead_history').insert({
      'lead_id': lead.id,
      'user_id': operatorId,
      'action': 'Marcado como Caixa Postal',
      'old_status': lead.status.dbValue,
      'new_status': LeadStatus.caixaPostal.dbValue,
      'notes': 'Retorno programado para ${returnTimestamp.toLocal()}',
      'created_at': DateTime.now().toIso8601String(),
    });

    // 3. Registra auditoria
    await _auditService.log(
      action: 'LEAD_VOICEMAIL',
      entityType: 'lead',
      entityId: lead.id,
      notes: 'Lead #${lead.id} enviado para Caixa Postal. Retorno em $voicemailReturnMinutes min.',
    );

    return lead.copyWith(
      status: LeadStatus.caixaPostal,
      attemptCount: lead.attemptCount + 1,
      lastContactAt: DateTime.now(),
      nextActionAt: returnTimestamp,
      clearAssignedOperator: true,
    );
  }

  /// Dispara a stored procedure do backend para verificar se há leads de caixa postal vencidos
  Future<int> reconcileOverdueVoicemails() async {
    try {
      final result = await _supabase.rpc('reconcile_voicemail_leads');
      final reconciledCount = (result is int) ? result : 0;
      if (reconciledCount > 0) {
        print('VoicemailScheduler: $reconciledCount leads retornaram para a fila central.');
      }
      return reconciledCount;
    } catch (e) {
      print('Erro ao reconciliar caixa postal no backend: $e');
      return 0;
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}
