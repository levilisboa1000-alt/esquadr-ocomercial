import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../models/lead_model.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_text_field.dart';

class CallFeedbackDialog extends StatefulWidget {
  final LeadModel lead;
  final int estimatedDurationSeconds;
  final Function({
    required CallResult result,
    String? notes,
  }) onConfirm;

  const CallFeedbackDialog({
    super.key,
    required this.lead,
    this.estimatedDurationSeconds = 0,
    required this.onConfirm,
  });

  @override
  State<CallFeedbackDialog> createState() => _CallFeedbackDialogState();
}

class _CallFeedbackDialogState extends State<CallFeedbackDialog> {
  CallResult _selectedResult = CallResult.atendeu;
  final TextEditingController _notesController = TextEditingController();

  final List<CallResult> _results = [
    CallResult.atendeu,
    CallResult.interessado,
    CallResult.agendamento,
    CallResult.retornarDepois,
    CallResult.naoAtendeu,
    CallResult.caixaPostal,
    CallResult.naoInteressado,
    CallResult.numeroInvalido,
  ];

  Color _getResultColor(CallResult res) {
    switch (res) {
      case CallResult.atendeu:
      case CallResult.interessado:
        return AppColors.actionRight;
      case CallResult.agendamento:
        return AppColors.actionUp;
      case CallResult.caixaPostal:
      case CallResult.retornarDepois:
        return AppColors.actionLeft;
      case CallResult.naoAtendeu:
      case CallResult.naoInteressado:
      case CallResult.numeroInvalido:
        return AppColors.actionDown;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      color: AppColors.actionRight.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_callback_rounded, color: AppColors.actionRight, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Resultado da Chamada",
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
              Text(
                "Telefone: ${PhoneUtils.formatDisplay(widget.lead.phone)}",
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(color: Colors.white12, height: 1),
              ),

              const Text(
                "Como foi a ligação?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Grade de Opções de Resultado
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _results.map((res) {
                  final isSelected = _selectedResult == res;
                  final color = _getResultColor(res);

                  return InkWell(
                    onTap: () => setState(() => _selectedResult = res),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.25) : AppColors.glassBackgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : AppColors.glassBorder,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? color : Colors.white30,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            res.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Observações da ligação
              GlassTextField(
                controller: _notesController,
                label: "Observações da conversa (opcional)",
                hint: "Ex: Pediu para retornar na sexta às 15h...",
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Botões de Ação
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
                        backgroundColor: _getResultColor(_selectedResult),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        widget.onConfirm(
                          result: _selectedResult,
                          notes: _notesController.text.trim().isNotEmpty
                              ? _notesController.text.trim()
                              : null,
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text("Salvar Chamada", style: TextStyle(fontWeight: FontWeight.bold)),
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
