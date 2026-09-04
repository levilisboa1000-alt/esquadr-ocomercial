import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/appointment_model.dart';
import '../../../repositories/appointment_repository.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_badge.dart';

class AdminCalendarTab extends StatefulWidget {
  final AppointmentRepository appointmentRepository;

  const AdminCalendarTab({super.key, required this.appointmentRepository});

  @override
  State<AdminCalendarTab> createState() => _AdminCalendarTabState();
}

class _AdminCalendarTabState extends State<AdminCalendarTab> {
  String _currentView = 'Lista'; // 'Dia', 'Semana', 'Lista'
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.appointmentRepository.getAppointments();
      if (mounted) setState(() => _appointments = list);
    } catch (e) {
      print('Erro ao carregar agendamentos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.agendado: return AppColors.actionUp;
      case AppointmentStatus.vinteQuatroHoras: return AppColors.gold;
      case AppointmentStatus.confirmado: return AppColors.actionRight;
      case AppointmentStatus.emAtendimento: return AppColors.purpleGlow;
      case AppointmentStatus.atendido: return Colors.teal;
      case AppointmentStatus.naoCompareceu: return AppColors.actionDown;
      case AppointmentStatus.cancelado: return AppColors.textMuted;
      default: return AppColors.statusNovo;
    }
  }

  void _updateAppointmentStatus(AppointmentModel item, AppointmentStatus newStatus) async {
    await widget.appointmentRepository.updateStatus(item.id, newStatus);
    _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Agenda Operacional",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Sincronizada com Google Calendar",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                // Seletor de Visão
                GlassContainer(
                  padding: const EdgeInsets.all(4),
                  borderRadius: 14,
                  child: Row(
                    children: ['Dia', 'Semana', 'Lista'].map((view) {
                      final isSelected = _currentView == view;
                      return GestureDetector(
                        onTap: () => setState(() => _currentView = view),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.actionUp : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            view,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Agendamentos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.actionUp))
                : _appointments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded, color: Colors.white24, size: 64),
                            SizedBox(height: 12),
                            Text(
                              "Nenhum agendamento encontrado",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              "Os agendamentos feitos pelos operadores aparecerão aqui.",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAppointments,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 90),
                          itemCount: _appointments.length,
                          itemBuilder: (context, index) {
                            final item = _appointments[index];
                            final statusColor = _getStatusColor(item.status);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(16),
                                borderRadius: 18,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_month, color: AppColors.actionUp, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              Formatters.formatDateTime(item.scheduledAt),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        GlassBadge(
                                          text: item.status.label,
                                          color: statusColor,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Lead ID: #${item.leadId.substring(0, 8)}",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.notes!,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (item.googleCalendarEventId != null)
                                          const Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded, color: AppColors.actionRight, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                "Sincronizado Google Calendar",
                                                style: TextStyle(color: AppColors.actionRight, fontSize: 11),
                                              ),
                                            ],
                                          )
                                        else
                                          const Text(
                                            "Sincronização local",
                                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                          ),
                                        const Spacer(),
                                        // Menu para alterar status do agendamento
                                        PopupMenuButton<AppointmentStatus>(
                                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
                                          color: AppColors.backgroundStart,
                                          onSelected: (newStatus) => _updateAppointmentStatus(item, newStatus),
                                          itemBuilder: (_) => AppointmentStatus.values.map((st) {
                                            return PopupMenuItem<AppointmentStatus>(
                                              value: st,
                                              child: Text(st.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
