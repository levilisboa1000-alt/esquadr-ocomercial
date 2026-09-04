import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/lead_model.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_text_field.dart';

class ScheduleModal extends StatefulWidget {
  final LeadModel lead;
  final UserModel currentOperator;
  final List<UserModel> availableOperators;
  final Function({
    required DateTime scheduledAt,
    required String notes,
    required String assignedOperatorId,
  }) onConfirm;

  const ScheduleModal({
    super.key,
    required this.lead,
    required this.currentOperator,
    this.availableOperators = const [],
    required this.onConfirm,
  });

  @override
  State<ScheduleModal> createState() => _ScheduleModalState();
}

class _ScheduleModalState extends State<ScheduleModal> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedOperatorId;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default: Amanhã às 10:00
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day + 1);
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    _selectedOperatorId = widget.currentOperator.id;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.actionUp,
              surface: AppColors.backgroundStart,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.actionUp,
              surface: AppColors.backgroundStart,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassContainer(
        borderRadius: 28,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.actionUp.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.actionUp, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Agendar Atendimento",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.lead.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Text(
                "Sincronização em tempo real com Google Calendar",
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(color: Colors.white12, height: 1),
              ),

              // Seletores de Data e Hora
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Data", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.glassBackgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event, color: AppColors.actionUp, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  Formatters.formatDate(_selectedDate),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Horário", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.glassBackgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, color: AppColors.actionUp, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Responsável
              const Text("Operador Responsável", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.glassBackgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedOperatorId,
                    isExpanded: true,
                    dropdownColor: AppColors.backgroundStart,
                    style: const TextStyle(color: Colors.white),
                    items: widget.availableOperators.isNotEmpty
                        ? widget.availableOperators.map((op) {
                            return DropdownMenuItem<String>(
                              value: op.id,
                              child: Text(op.fullName),
                            );
                          }).toList()
                        : [
                            DropdownMenuItem<String>(
                              value: widget.currentOperator.id,
                              child: Text(widget.currentOperator.fullName),
                            )
                          ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedOperatorId = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Observações
              GlassTextField(
                controller: _notesController,
                label: "Observações do Agendamento",
                hint: "Ex: Cliente tem interesse no empreendimento X...",
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.actionUp,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        widget.onConfirm(
                          scheduledAt: scheduledDateTime,
                          notes: _notesController.text.trim(),
                          assignedOperatorId: _selectedOperatorId,
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text("Agendar Evento", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
