import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../models/lead_model.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/action_button.dart';
import '../controllers/operator_controller.dart';
import '../widgets/swipe_card.dart';
import '../widgets/call_feedback_dialog.dart';
import '../widgets/schedule_modal.dart';

class OperatorDeckScreen extends StatefulWidget {
  const OperatorDeckScreen({super.key});

  @override
  State<OperatorDeckScreen> createState() => _OperatorDeckScreenState();
}

class _OperatorDeckScreenState extends State<OperatorDeckScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quando o operador retorna da ligação telefônica nativa,
    // o app retoma o foco e abre automaticamente o feedback da chamada
    if (state == AppLifecycleState.resumed) {
      _checkPendingCallFeedback();
    }
  }

  void _checkPendingCallFeedback() {
    final controller = context.read<OperatorController>();
    if (controller.phoneCallService.hasPendingCallFeedback) {
      final activeLead = controller.phoneCallService.activeLeadInCall!;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CallFeedbackDialog(
          lead: activeLead,
          estimatedDurationSeconds: controller.phoneCallService.getEstimatedDurationSeconds(),
          onConfirm: ({required result, notes}) {
            controller.saveCallFeedback(
              lead: activeLead,
              result: result,
              notes: notes,
            );
          },
        ),
      );
    }
  }

  void _handleAction(SwipeAction action, LeadModel lead) {
    final controller = context.read<OperatorController>();

    if (action == SwipeAction.scheduleUp) {
      // Abre o modal de agendamento antes de descartar o card
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ScheduleModal(
          lead: lead,
          currentOperator: controller.operator,
          onConfirm: ({
            required scheduledAt,
            required notes,
            required assignedOperatorId,
          }) {
            controller.completeSchedule(
              lead: lead,
              scheduledAt: scheduledAt,
              notes: notes,
              assignedOperatorId: assignedOperatorId,
            );
            controller.queue.removeWhere((l) => l.id == lead.id);
          },
        ),
      );
      return;
    }

    controller.handleSwipeAction(lead: lead, action: action, context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OperatorController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Barra Superior com Marca e Gamificação
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logotipo Esquadrão Comercial
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ESQUADRÃO",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                            ),
                          ),
                          Text(
                            "COMERCIAL",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.0,
                            ),
                          ),
                        ],
                      ),

                      // Indicador de Gamificação e Fila
                      Row(
                        children: [
                          // Meta Diária
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            borderRadius: 18,
                            child: Row(
                              children: [
                                const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  "${controller.processedToday}/${controller.dailyGoal}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Fila Ativa
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            borderRadius: 18,
                            child: Row(
                              children: [
                                const Icon(Icons.layers_rounded, color: AppColors.actionUp, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "${controller.queue.length} Leads",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Barra de Progresso da Meta
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: controller.goalProgress,
                      minHeight: 3,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.actionUp),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Pilha de Cards de Leads (Tinder de Leads)
                Expanded(
                  child: Center(
                    child: controller.isLoading
                        ? const CircularProgressIndicator(color: AppColors.actionUp)
                        : controller.queue.isEmpty
                            ? _buildEmptyQueue(controller)
                            : _buildCardStack(controller),
                  ),
                ),

                // 3. Botões de Ação Físicos (Acessibilidade & Atalhos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ActionButton(
                        icon: Icons.close_rounded,
                        color: AppColors.actionDown,
                        label: "DESCARTAR",
                        semanticDescription: "Arrastar para baixo: Marcar lead como não interessado",
                        onTap: () {
                          if (controller.queue.isNotEmpty) {
                            _handleAction(SwipeAction.rejectDown, controller.queue.first);
                          }
                        },
                      ),
                      ActionButton(
                        icon: Icons.voicemail_rounded,
                        color: AppColors.actionLeft,
                        label: "CAIXA POSTAL",
                        semanticDescription: "Arrastar para esquerda: Enviar lead para caixa postal por 30 minutos",
                        onTap: () {
                          if (controller.queue.isNotEmpty) {
                            _handleAction(SwipeAction.voicemailLeft, controller.queue.first);
                          }
                        },
                      ),
                      ActionButton(
                        icon: Icons.calendar_month_rounded,
                        color: AppColors.actionUp,
                        label: "AGENDAR",
                        semanticDescription: "Arrastar para cima: Agendar compromisso no Google Calendar",
                        onTap: () {
                          if (controller.queue.isNotEmpty) {
                            _handleAction(SwipeAction.scheduleUp, controller.queue.first);
                          }
                        },
                      ),
                      ActionButton(
                        icon: Icons.phone_in_talk_rounded,
                        color: AppColors.actionRight,
                        label: "LIGAR",
                        semanticDescription: "Arrastar para direita: Abrir discador nativo do celular",
                        onTap: () {
                          if (controller.queue.isNotEmpty) {
                            _handleAction(SwipeAction.callRight, controller.queue.first);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardStack(OperatorController controller) {
    // Renderiza no máximo os dois primeiros cards para performance 60 FPS
    final visibleLeads = controller.queue.take(2).toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        if (visibleLeads.length > 1)
          SwipeCard(
            key: ValueKey(visibleLeads[1].id),
            lead: visibleLeads[1],
            isFront: false,
            onSwipeComplete: (_) {},
          ),
        SwipeCard(
          key: ValueKey(visibleLeads[0].id),
          lead: visibleLeads[0],
          isFront: true,
          onSwipeComplete: (action) => _handleAction(action, visibleLeads[0]),
        ),
      ],
    );
  }

  Widget _buildEmptyQueue(OperatorController controller) {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.actionRight.withOpacity(0.15),
            ),
            child: const Icon(Icons.done_all_rounded, color: AppColors.actionRight, size: 56),
          ),
          const SizedBox(height: 20),
          const Text(
            "Fila Concluída!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Você processou todos os leads disponíveis para você. Solicite um novo lote da fila central.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionUp,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: () => controller.loadInitialBatch(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Solicitar Novos Leads"),
          ),
        ],
      ),
    );
  }
}
