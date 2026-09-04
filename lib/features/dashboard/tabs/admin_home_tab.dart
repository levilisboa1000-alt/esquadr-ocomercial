import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/audit_log_model.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../services/audit/audit_service.dart';

class AdminHomeTab extends StatefulWidget {
  final SupabaseClient supabase;
  final AuditService auditService;

  const AdminHomeTab({
    super.key,
    required this.supabase,
    required this.auditService,
  });

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  bool _isLoading = true;
  int _activeLeads = 0;
  int _newLeads = 0;
  int _callsToday = 0;
  int _appointmentsToday = 0;
  int _voicemailsCount = 0;
  int _rejectedCount = 0;
  int _onlineOperators = 0;
  List<AuditLogModel> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Leads Ativos
      final activeRes = await widget.supabase
          .from('leads')
          .select('id')
          .inFilter('status', ['NOVO', 'DISTRIBUIDO', 'EM_ATENDIMENTO', 'RETORNAR_PARA_FILA']);
      _activeLeads = (activeRes as List).length;

      // 2. Leads Novos
      final newRes = await widget.supabase
          .from('leads')
          .select('id')
          .eq('status', 'NOVO');
      _newLeads = (newRes as List).length;

      // 3. Chamadas Hoje
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final callsRes = await widget.supabase
          .from('calls')
          .select('id, result')
          .gte('created_at', startOfDay);
      final callsList = callsRes as List;
      _callsToday = callsList.length;

      _voicemailsCount = callsList.where((c) => c['result'] == 'caixa_postal').length;
      _rejectedCount = callsList.where((c) => c['result'] == 'nao_interessado').length;

      // 4. Agendamentos
      final apptRes = await widget.supabase
          .from('appointments')
          .select('id')
          .gte('created_at', startOfDay);
      _appointmentsToday = (apptRes as List).length;

      // 5. Operadores Online
      final onlineRes = await widget.supabase
          .from('profiles')
          .select('id')
          .eq('is_online', true)
          .eq('role', 'operator');
      _onlineOperators = (onlineRes as List).length;

      // 6. Logs de Auditoria Recentes
      _recentLogs = await widget.auditService.getRecentLogs(limit: 6);
    } catch (e) {
      print('Erro ao carregar dados do dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _conversionRate {
    if (_callsToday == 0) return 0.0;
    final rate = (_appointmentsToday / _callsToday) * 100.0;
    return double.parse(rate.toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.actionUp));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.actionUp,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Título e Seletor de Período
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Painel Geral",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "$_newLeads novos leads aguardando na fila central",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                borderRadius: 14,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.actionRight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$_onlineOperators online",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Grid de Cards de Estatísticas Reais do Banco
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: [
              _buildStatCard("Leads Ativos", "$_activeLeads", Icons.layers_rounded, AppColors.actionUp),
              _buildStatCard("Ligações Hoje", "$_callsToday", Icons.phone_in_talk_rounded, AppColors.actionRight),
              _buildStatCard("Agendamentos", "$_appointmentsToday", Icons.event_available_rounded, AppColors.statusAgendado),
              _buildStatCard("Taxa de Conversão", "$_conversionRate%", Icons.trending_up_rounded, AppColors.gold),
              _buildStatCard("Caixa Postal", "$_voicemailsCount", Icons.voicemail_rounded, AppColors.actionLeft),
              _buildStatCard("Não Interessados", "$_rejectedCount", Icons.close_rounded, AppColors.actionDown),
            ],
          ),

          const SizedBox(height: 28),

          // Gráfico de Produtividade em Linha (FlChart)
          const Text(
            "Distribuição de Resultados da Operação",
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          GlassContainer(
            padding: const EdgeInsets.all(20),
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: ([_callsToday, _appointmentsToday, _voicemailsCount, _rejectedCount, 5].reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        switch (val.toInt()) {
                          case 0: return const Text('Ligações', style: TextStyle(color: AppColors.textSecondary, fontSize: 10));
                          case 1: return const Text('Agendados', style: TextStyle(color: AppColors.textSecondary, fontSize: 10));
                          case 2: return const Text('Cx. Postal', style: TextStyle(color: AppColors.textSecondary, fontSize: 10));
                          case 3: return const Text('Descartes', style: TextStyle(color: AppColors.textSecondary, fontSize: 10));
                          default: return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _callsToday.toDouble(), color: AppColors.actionRight, width: 22, borderRadius: BorderRadius.circular(6))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _appointmentsToday.toDouble(), color: AppColors.actionUp, width: 22, borderRadius: BorderRadius.circular(6))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _voicemailsCount.toDouble(), color: AppColors.actionLeft, width: 22, borderRadius: BorderRadius.circular(6))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: _rejectedCount.toDouble(), color: AppColors.actionDown, width: 22, borderRadius: BorderRadius.circular(6))]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Feed de Atividade Recente (Auditoria Real)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Atividade Recente",
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Text(
                "${_recentLogs.length} eventos",
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_recentLogs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text("Nenhuma atividade recente registrada.", style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ..._recentLogs.map((log) => _buildAuditTile(log)),

          const SizedBox(height: 80), // Espaço para a BottomNavigationBar Liquid Glass
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTile(AuditLogModel log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glassBackgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, color: AppColors.actionUp, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${log.userName}: ${log.action}",
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  log.newValue?['notes']?.toString() ?? log.entityType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            Formatters.formatRelative(log.createdAt),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
