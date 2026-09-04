import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/import/lead_import_service.dart';
import '../../../services/audit/audit_service.dart';
import '../../../shared/widgets/glass_container.dart';

class LeadImportModal extends StatefulWidget {
  final VoidCallback onImportSuccess;

  const LeadImportModal({super.key, required this.onImportSuccess});

  @override
  State<LeadImportModal> createState() => _LeadImportModalState();
}

class _LeadImportModalState extends State<LeadImportModal> {
  late LeadImportService _importService;
  ImportPreviewResult? _previewResult;
  bool _isAnalyzing = false;
  bool _isImporting = false;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _importService = LeadImportService(
      supabase: supabase,
      auditService: AuditService(client: supabase),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;

        if (bytes != null) {
          setState(() {
            _fileName = file.name;
            _isAnalyzing = true;
          });

          final content = utf8.decode(bytes, allowMalformed: true);
          final preview = await _importService.previewCsv(csvContent: content);

          setState(() {
            _previewResult = preview;
            _isAnalyzing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao analisar arquivo: $e')),
        );
      }
    }
  }

  Future<void> _confirmImport() async {
    if (_previewResult == null || _previewResult!.validLeads.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final count = await _importService.commitImport(_previewResult!.validLeads);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onImportSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.actionRight,
            content: Text('$count leads foram importados para a fila central!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.actionDown,
            content: Text('Erro ao importar: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.file_upload_outlined, color: AppColors.actionUp, size: 24),
                      SizedBox(width: 10),
                      Text(
                        "Importar Leads",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Carregue arquivos CSV com colunas: Nome, Telefone, Cidade, Estado, Interesse, Valor, Origem.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),

              const SizedBox(height: 20),

              // Botão Selecionar Arquivo
              Center(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    side: const BorderSide(color: AppColors.actionUp),
                  ),
                  onPressed: _isAnalyzing || _isImporting ? null : _pickFile,
                  icon: const Icon(Icons.attach_file, color: AppColors.actionUp),
                  label: Text(
                    _fileName ?? "Selecionar Arquivo CSV",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              if (_isAnalyzing) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator(color: AppColors.actionUp)),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    "Analisando linhas, validando telefones e checando duplicados...",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],

              if (_previewResult != null && !_isAnalyzing) ...[
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),

                // Resumo das estatísticas do arquivo
                const Text("Resultado da Análise:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _buildStatPill("Total", "${_previewResult!.totalRows}", Colors.white70),
                    const SizedBox(width: 8),
                    _buildStatPill("Válidos", "${_previewResult!.validCount}", AppColors.actionRight),
                    const SizedBox(width: 8),
                    _buildStatPill("Duplicados", "${_previewResult!.duplicateCount}", AppColors.actionLeft),
                    const SizedBox(width: 8),
                    _buildStatPill("Inválidos", "${_previewResult!.invalidCount}", AppColors.actionDown),
                  ],
                ),

                if (_previewResult!.invalidRows.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text("Erros Encontrados:", style: TextStyle(color: AppColors.actionDown, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 90),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.actionDown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: _previewResult!.invalidRows.take(5).map((e) => Text(e, style: const TextStyle(color: Colors.white70, fontSize: 11))).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Botão de Confirmação
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.actionRight,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isImporting || _previewResult!.validLeads.isEmpty
                        ? null
                        : _confirmImport,
                    child: _isImporting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            "Confirmar e Inserir ${_previewResult!.validCount} Leads na Fila",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
