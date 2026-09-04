import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_enums.dart';
import '../../../models/goal_model.dart';
import '../../../models/user_model.dart';
import '../../../repositories/user_repository.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_badge.dart';

class AdminTeamTab extends StatefulWidget {
  final UserRepository userRepository;

  const AdminTeamTab({super.key, required this.userRepository});

  @override
  State<AdminTeamTab> createState() => _AdminTeamTabState();
}

class _AdminTeamTabState extends State<AdminTeamTab> {
  List<OperatorProductivityModel> _productivityList = [];
  List<UserModel> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    setState(() => _isLoading = true);
    try {
      _productivityList = await widget.userRepository.getOperatorProductivityList();
      _allUsers = await widget.userRepository.getUsers();
    } catch (e) {
      print('Erro ao carregar equipe: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showChangeRoleDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundStart,
        title: Text("Alterar Papel de ${user.fullName}", style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return ListTile(
              title: Text(role.label, style: const TextStyle(color: Colors.white)),
              trailing: user.role == role ? const Icon(Icons.check, color: AppColors.actionUp) : null,
              onTap: () async {
                Navigator.of(context).pop();
                await widget.userRepository.updateUserRole(user.id, role);
                _loadTeamData();
              },
            );
          }).toList(),
        ),
      ),
    );
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
                      "Equipe e Produtividade",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Performance individual e ranking",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  "${_productivityList.length} operadores",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          // Lista de Produtividade dos Operadores
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.actionUp))
                : _productivityList.isEmpty
                    ? const Center(
                        child: Text("Nenhum operador cadastrado.", style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTeamData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 90),
                          itemCount: _productivityList.length,
                          itemBuilder: (context, index) {
                            final op = _productivityList[index];
                            final rank = index + 1;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(16),
                                borderRadius: 20,
                                child: Column(
                                  children: [
                                    // Linha do Operador (Nome, Status Online, Ranking)
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: rank == 1
                                                ? AppColors.gold.withOpacity(0.25)
                                                : Colors.white.withOpacity(0.08),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: rank == 1 ? AppColors.gold : Colors.white24,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "#$rank",
                                              style: TextStyle(
                                                color: rank == 1 ? AppColors.gold : Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    op.operatorName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: op.isOnline ? AppColors.actionRight : Colors.grey,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    op.isOnline ? "Online" : "Offline",
                                                    style: TextStyle(
                                                      color: op.isOnline ? AppColors.actionRight : AppColors.textMuted,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Conversão
                                        GlassBadge(
                                          text: "${op.conversionRate}% conv.",
                                          color: op.conversionRate >= 15 ? AppColors.actionRight : AppColors.actionUp,
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(Icons.manage_accounts_outlined, color: Colors.white54, size: 20),
                                          tooltip: "Alterar função",
                                          onPressed: () {
                                            final user = _allUsers.firstWhere(
                                              (u) => u.id == op.operatorId,
                                              orElse: () => UserModel(
                                                id: op.operatorId,
                                                email: '',
                                                fullName: op.operatorName,
                                                role: UserRole.operator,
                                              ),
                                            );
                                            _showChangeRoleDialog(user);
                                          },
                                        ),
                                      ],
                                    ),

                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12.0),
                                      child: Divider(color: Colors.white12, height: 1),
                                    ),

                                    // Indicadores Reais
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildMetricColumn("Leads", "${op.leadsReceived}"),
                                        _buildMetricColumn("Ligações", "${op.callsMade}"),
                                        _buildMetricColumn("Atendeu", "${op.callsAnswered}"),
                                        _buildMetricColumn("Cx. Postal", "${op.voicemailCount}"),
                                        _buildMetricColumn("Agendados", "${op.appointmentsCreated}", isHighlight: true),
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

  Widget _buildMetricColumn(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppColors.actionUp : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
