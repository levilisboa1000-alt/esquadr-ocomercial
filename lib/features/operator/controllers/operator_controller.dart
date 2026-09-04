import 'package:flutter/material.dart';
import '../../../core/constants/app_enums.dart';
import '../../../models/lead_model.dart';
import '../../../models/user_model.dart';
import '../../../repositories/lead_repository.dart';
import '../../../repositories/call_repository.dart';
import '../../../repositories/appointment_repository.dart';
import '../../../services/lead_distribution/lead_distribution_service.dart';
import '../../../services/phone_call/phone_call_service.dart';
import '../../../services/calendar/google_calendar_service.dart';
import '../../../services/voicemail/voicemail_scheduler_service.dart';
import '../../../services/audit/audit_service.dart';

class OperatorController extends ChangeNotifier {
  final LeadDistributionService _distributionService;
  final PhoneCallService _phoneCallService;
  final GoogleCalendarService _calendarService;
  final VoicemailSchedulerService _voicemailService;
  final LeadRepository _leadRepository;
  final CallRepository _callRepository;
  final AppointmentRepository _appointmentRepository;
  final AuditService _auditService;

  final UserModel operator;

  List<LeadModel> _queue = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Gamificação
  int _processedToday = 0;
  int _callsMadeToday = 0;
  int _appointmentsToday = 0;

  OperatorController({
    required this.operator,
    required LeadDistributionService distributionService,
    required PhoneCallService phoneCallService,
    required GoogleCalendarService calendarService,
    required VoicemailSchedulerService voicemailService,
    required LeadRepository leadRepository,
    required CallRepository callRepository,
    required AppointmentRepository appointmentRepository,
    required AuditService auditService,
  })  : _distributionService = distributionService,
        _phoneCallService = phoneCallService,
        _calendarService = calendarService,
        _voicemailService = voicemailService,
        _leadRepository = leadRepository,
        _callRepository = callRepository,
        _appointmentRepository = appointmentRepository,
        _auditService = auditService {
    loadInitialBatch();
    loadTodayMetrics();
  }

  List<LeadModel> get queue => _queue;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get processedToday => _processedToday;
  int get callsMadeToday => _callsMadeToday;
  int get appointmentsToday => _appointmentsToday;
  int get dailyGoal => operator.dailyLeadGoal;
  double get goalProgress => dailyGoal > 0 ? (_processedToday / dailyGoal).clamp(0.0, 1.0) : 0.0;

  PhoneCallService get phoneCallService => _phoneCallService;

  /// Carrega o lote inicial de leads da fila central
  Future<void> loadInitialBatch() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final batch = await _distributionService.getLeadsForOperator(
        operator: operator,
        limit: 10,
      );
      _queue = batch;
    } catch (e) {
      _errorMessage = 'Erro ao buscar leads da fila central: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega métricas diárias de chamadas já efetuadas pelo operador
  Future<void> loadTodayMetrics() async {
    try {
      _callsMadeToday = await _callRepository.getOperatorCallsToday(operator.id);
      _processedToday = _callsMadeToday;
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar métricas do operador: $e');
    }
  }

  /// Trata a ação de Swipe do operador
  Future<void> handleSwipeAction({
    required LeadModel lead,
    required SwipeAction action,
    BuildContext? context,
  }) async {
    // Remove o card da frente
    _queue.removeWhere((l) => l.id == lead.id);
    notifyListeners();

    switch (action) {
      case SwipeAction.callRight:
        await _processCallAction(lead);
        break;

      case SwipeAction.voicemailLeft:
        await _processVoicemailAction(lead);
        break;

      case SwipeAction.scheduleUp:
        // O diálogo é aberto pela tela, e ao confirmar chama completeSchedule
        break;

      case SwipeAction.rejectDown:
        await _processRejectAction(lead);
        break;
    }

    _processedToday++;
    notifyListeners();

    // Se a fila estiver esvaziando, solicita novo lote automaticamente
    if (_queue.length <= 2 && !_isLoading) {
      _fetchMoreLeads();
    }
  }

  /// DIREITA = LIGAR: Dispara discador nativo com tel:
  Future<void> _processCallAction(LeadModel lead) async {
    // 1. Marca no banco como EM_ATENDIMENTO
    await _leadRepository.updateLead(lead.copyWith(
      status: LeadStatus.emAtendimento,
      attemptCount: lead.attemptCount + 1,
      lastContactAt: DateTime.now(),
    ));

    await _leadRepository.addHistoryEntry(
      leadId: lead.id,
      userId: operator.id,
      userName: operator.fullName,
      action: 'Iniciou Ligação',
      oldStatus: lead.status,
      newStatus: LeadStatus.emAtendimento,
    );

    // 2. Dispara discador nativo real (url_launcher tel:)
    await _phoneCallService.initiateCall(lead);
  }

  /// Salva o feedback da ligação efetuada
  Future<void> saveCallFeedback({
    required LeadModel lead,
    required CallResult result,
    String? notes,
  }) async {
    final duration = _phoneCallService.getEstimatedDurationSeconds();
    _phoneCallService.clearActiveCallContext();

    // 1. Salva registro na tabela calls
    await _callRepository.recordCall(
      leadId: lead.id,
      operatorId: operator.id,
      result: result,
      attemptNumber: lead.attemptCount + 1,
      durationSeconds: duration,
      notes: notes,
    );

    // 2. Determina o novo status baseado no resultado
    LeadStatus newStatus = LeadStatus.ligacaoRealizada;
    if (result == CallResult.caixaPostal) {
      await _processVoicemailAction(lead);
      return;
    } else if (result == CallResult.naoInteressado) {
      newStatus = LeadStatus.naoInteressado;
    } else if (result == CallResult.atendeu || result == CallResult.interessado) {
      newStatus = LeadStatus.emAtendimento;
    }

    await _leadRepository.updateLead(lead.copyWith(
      status: newStatus,
      attemptCount: lead.attemptCount + 1,
      lastContactAt: DateTime.now(),
      notes: notes,
    ));

    await _leadRepository.addHistoryEntry(
      leadId: lead.id,
      userId: operator.id,
      userName: operator.fullName,
      action: 'Ligação finalizada: ${result.label}',
      newStatus: newStatus,
      notes: notes,
    );

    await _auditService.log(
      action: 'CALL_COMPLETED',
      entityType: 'call',
      entityId: lead.id,
      notes: 'Resultado: ${result.label} | Duração: ${duration}s',
    );
  }

  /// ESQUERDA = CAIXA POSTAL: Expiração e retorno em 30 minutos via backend
  Future<void> _processVoicemailAction(LeadModel lead) async {
    await _voicemailService.markLeadAsVoicemail(
      lead: lead,
      operatorId: operator.id,
    );
  }

  /// CIMA = AGENDAR: Integração com Google Calendar e marcação de AGENDADO
  Future<void> completeSchedule({
    required LeadModel lead,
    required DateTime scheduledAt,
    required String notes,
    required String assignedOperatorId,
  }) async {
    String? googleEventId;

    // Tenta sincronizar com a API real do Google Calendar se as credenciais existirem
    try {
      googleEventId = await _calendarService.createEvent(
        lead: lead,
        operator: operator,
        scheduledAt: scheduledAt,
        notes: notes,
      );
    } catch (e) {
      print('Aviso: Não foi possível sincronizar com Google Calendar (verifique OAuth): $e');
    }

    // 1. Salva na tabela appointments
    await _appointmentRepository.createAppointment(
      leadId: lead.id,
      operatorId: assignedOperatorId,
      scheduledAt: scheduledAt,
      notes: notes,
      googleCalendarEventId: googleEventId,
    );

    // 2. Atualiza lead para AGENDADO e retira da fila ativa
    await _leadRepository.updateLead(lead.copyWith(
      status: LeadStatus.agendado,
      assignedOperatorId: assignedOperatorId,
      notes: notes,
    ));

    await _leadRepository.addHistoryEntry(
      leadId: lead.id,
      userId: operator.id,
      userName: operator.fullName,
      action: 'Atendimento Agendado',
      newStatus: LeadStatus.agendado,
      notes: 'Data: $scheduledAt | EventId: ${googleEventId ?? "Local"}',
    );

    await _auditService.log(
      action: 'LEAD_SCHEDULED',
      entityType: 'appointment',
      entityId: lead.id,
      notes: 'Agendado para $scheduledAt (Google Calendar: ${googleEventId ?? "N/A"})',
    );

    _appointmentsToday++;
    notifyListeners();
  }

  /// BAIXO = NÃO INTERESSADO
  Future<void> _processRejectAction(LeadModel lead) async {
    await _leadRepository.updateLead(lead.copyWith(
      status: LeadStatus.naoInteressado,
      attemptCount: lead.attemptCount + 1,
      lastContactAt: DateTime.now(),
    ));

    await _leadRepository.addHistoryEntry(
      leadId: lead.id,
      userId: operator.id,
      userName: operator.fullName,
      action: 'Marcado como Não Interessado',
      oldStatus: lead.status,
      newStatus: LeadStatus.naoInteressado,
    );

    await _auditService.log(
      action: 'LEAD_REJECTED',
      entityType: 'lead',
      entityId: lead.id,
      notes: 'Lead marcado como Não Interessado pelo operador ${operator.fullName}',
    );
  }

  /// Busca mais leads da fila central silenciosamente
  Future<void> _fetchMoreLeads() async {
    try {
      final moreLeads = await _distributionService.getLeadsForOperator(
        operator: operator,
        limit: 10,
      );
      if (moreLeads.isNotEmpty) {
        _queue.addAll(moreLeads);
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao repor fila de leads: $e');
    }
  }
}
