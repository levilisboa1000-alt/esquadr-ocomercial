import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../models/lead_model.dart';
import '../../../models/user_model.dart';
import '../../../repositories/lead_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/lead_distribution/lead_distribution_service.dart';
import '../../../services/audit/audit_service.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_badge.dart';
import '../../../shared/widgets/glass_text_field.dart';
import '../../import/screens/lead_import_modal.dart';

class AdminLeadsTab extends StatefulWidget {
  final LeadRepository leadRepository;
  final UserRepository userRepository;
  final LeadDistributionService distributionService;
  final AuditService auditService;

  const AdminLeadsTab({
    super.key,
    required this.leadRepository,
    required this.userRepository,
    required this.distributionService,
    required this.auditService,
  });

  @override
  State<AdminLeadsTab> createState() => _AdminLeadsTabState();
}

class _AdminLeadsTabState extends State<AdminLeadsTab> {
  final TextEditingController _searchController = TextEditingController();
  List<LeadModel> _leads = [];
  List<UserModel> _operators = [];
  bool _isLoading = true;

  LeadStatus? _filterStatus;
  String? _filterOperatorId;
  final int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _operators = await widget.userRepository.getUsers(roleFilter: UserRole.operator);
      await _loadLeads();
    } catch (e) {
      print('Erro ao carregar dados de leads: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLeads() async {
    final leads = await widget.leadRepository.getLeads(
      searchQuery: _searchController.text.trim(),
      status: _filterStatus,
      assignedOperatorId: _filterOperatorId,
      page: _currentPage,
    );
    if (mounted) {
      setState(() => _leads = leads);
    }
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.novo: return AppColors.statusNovo;
      case LeadStatus.distribuido: return AppColors.statusDistribuido;
      case LeadStatus.emAtendimento: return AppColors.statusEmAtendimento;
      case LeadStatus.agendado: return AppColors.statusAgendado;
      case LeadStatus.caixaPostal: return AppColors.statusCaixaPostal;
      case LeadStatus.naoInteressado: return AppColors.statusNaoInteressado;
      default: return AppColors.statusFinalizado;
    }
  }

  void _openLeadDetail(LeadModel lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildLeadDetailModal(lead),
    );
  }

  void _openImportModal() {
    showDialog(
      context: context,
      builder: (_) => LeadImportModal(
        onImportSuccess: () {
          _loadLeads();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header & Ações de Importação
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Gestão de Leads",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Fila central e distribuição",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionUp,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _openImportModal,
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text("Importar", style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),

          // Campo de Pesquisa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: GlassTextField(
              controller: _searchController,
              hint: "Pesquisar por nome, telefone ou interesse...",
              prefixIcon: Icons.search_rounded,
              onChanged: (_) => _loadLeads(),
            ),
          ),

          // Filtros Rápidos por Status
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildFilterChip("Todos", _filterStatus == null && _filterOperatorId == null, () {
                  setState(() {
                    _filterStatus = null;
                    _filterOperatorId = null;
                  });
                  _loadLeads();
                }),
                _buildFilterChip("Novos", _filterStatus == LeadStatus.novo, () {
                  setState(() => _filterStatus = LeadStatus.novo);
                  _loadLeads();
                }),
                _buildFilterChip("Distribuídos", _filterStatus == LeadStatus.distribuido, () {
                  setState(() => _filterStatus = LeadStatus.distribuido);
                  _loadLeads();
                }),
                _buildFilterChip("Em Atendimento", _filterStatus == LeadStatus.emAtendimento, () {
                  setState(() => _filterStatus = LeadStatus.emAtendimento);
                  _loadLeads();
                }),
                _buildFilterChip("Agendados", _filterStatus == LeadStatus.agendado, () {
                  setState(() => _filterStatus = LeadStatus.agendado);
                  _loadLeads();
                }),
                _buildFilterChip("Caixa Postal", _filterStatus == LeadStatus.caixaPostal, () {
                  setState(() => _filterStatus = LeadStatus.caixaPostal);
                  _loadLeads();
                }),
                _buildFilterChip("Não Interessados", _filterStatus == LeadStatus.naoInteressado, () {
                  setState(() => _filterStatus = LeadStatus.naoInteressado);
                  _loadLeads();
                }),
                ..._operators.map((op) => _buildFilterChip(
                  "Op: ${op.fullName}",
                  _filterOperatorId == op.id,
                  () {
                    setState(() => _filterOperatorId = _filterOperatorId == op.id ? null : op.id);
                    _loadLeads();
                  },
                )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Lista de Leads
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.actionUp))
                : _leads.isEmpty
                    ? const Center(
                        child: Text("Nenhum lead encontrado.", style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLeads,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 90),
                          itemCount: _leads.length,
                          itemBuilder: (context, index) {
                            final lead = _leads[index];
                            final statusColor = _getStatusColor(lead.status);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(16),
                                borderRadius: 18,
                                onTap: () => _openLeadDetail(lead),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  lead.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              GlassBadge(
                                                text: lead.status.label,
                                                color: statusColor,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${PhoneUtils.formatDisplay(lead.phone)} • ${lead.city.isNotEmpty ? lead.city : 'Brasil'}",
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${lead.interest.isNotEmpty ? lead.interest : 'Interesse Geral'} | ${lead.propertyValue > 0 ? Formatters.formatCurrency(lead.propertyValue) : 'A consultar'}",
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.white38),
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

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.actionUp : AppColors.glassBackgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.actionUp : AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLeadDetailModal(LeadModel lead) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundStart,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lead.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              GlassBadge(text: lead.status.label, color: _getStatusColor(lead.status)),
            ],
          ),
          const SizedBox(height: 6),
          Text(PhoneUtils.formatDisplay(lead.phone), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          Text("Local: ${lead.city} - ${lead.state}", style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text("Interesse: ${lead.interest}", style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text("Valor: ${Formatters.formatCurrency(lead.propertyValue)}", style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text("Tentativas: ${lead.attemptCount} ligações", style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text("Origem: ${lead.source}", style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 24),

          // Botões de Ação Administrativa
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await widget.distributionService.returnLeadToCentralQueue(
                      leadId: lead.id,
                      reason: 'Devolvido manualmente pelo Administrador',
                    );
                    _loadLeads();
                  },
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text("Devolver à Fila"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.actionDown),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await widget.leadRepository.deleteLead(lead.id);
                    _loadLeads();
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text("Excluir"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
