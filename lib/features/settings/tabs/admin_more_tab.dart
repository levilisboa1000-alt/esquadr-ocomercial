import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../repositories/settings_repository.dart';
import '../../../services/auth/supabase_auth_service.dart';
import '../../../services/calendar/google_calendar_service.dart';
import '../../../services/audit/audit_service.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/glass_text_field.dart';

class AdminMoreTab extends StatefulWidget {
  final UserModel currentUser;
  final SettingsRepository settingsRepository;
  final SupabaseAuthService authService;
  final GoogleCalendarService calendarService;
  final AuditService auditService;
  final VoidCallback onLogout;

  const AdminMoreTab({
    super.key,
    required this.currentUser,
    required this.settingsRepository,
    required this.authService,
    required this.calendarService,
    required this.auditService,
    required this.onLogout,
  });

  @override
  State<AdminMoreTab> createState() => _AdminMoreTabState();
}

class _AdminMoreTabState extends State<AdminMoreTab> {
  bool _isLoading = true;
  bool _isGoogleConnected = false;

  final TextEditingController _voicemailMinutesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _voicemailMinutesController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final s = await widget.settingsRepository.getSettings();
      _isGoogleConnected = await widget.calendarService.isAccountConnected(widget.currentUser.id);
      _voicemailMinutesController.text = s.voicemailReturnMinutes.toString();
    } catch (e) {
      print('Erro ao carregar configurações: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final minutes = int.tryParse(_voicemailMinutesController.text.trim()) ?? 30;
    await widget.settingsRepository.updateSetting('voicemail_return_minutes', minutes);
    await widget.auditService.log(
      action: 'SETTINGS_UPDATED',
      entityType: 'settings',
      notes: 'Tempo de retorno de caixa postal alterado para $minutes minutos',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.actionRight,
        content: Text('Configurações salvas no banco com sucesso!'),
      ),
    );
  }

  Future<void> _toggleGoogleConnection() async {
    if (_isGoogleConnected) {
      await widget.calendarService.disconnectGoogleAccount(widget.currentUser.id);
      if (mounted) setState(() => _isGoogleConnected = false);
    } else {
      try {
        final account = await widget.calendarService.connectGoogleAccount(widget.currentUser.id);
        if (account != null) {
          if (mounted) {
            setState(() => _isGoogleConnected = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.actionRight,
                content: Text('Conta Google (${account.email}) conectada com sucesso!'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.actionDown,
              content: Text('Erro ao conectar Google: $e'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.actionUp));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        children: [
          // Header
          const Text(
            "Configurações da Operação",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const Text(
            "Parâmetros de telemarketing e regras de negócio",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),

          const SizedBox(height: 24),

          // Seção: Regras de Caixa Postal
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.voicemail_rounded, color: AppColors.actionLeft, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Regra de Caixa Postal",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Tempo de espera antes que o lead retorne automaticamente para a Fila Central do backend.",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GlassTextField(
                        controller: _voicemailMinutesController,
                        label: "Minutos de retorno",
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.actionUp,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        ),
                        onPressed: _saveSettings,
                        child: const Text("Salvar"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Seção: Google Calendar OAuth 2.0
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: AppColors.actionUp, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Integração Google Calendar",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Conecte sua conta Google Workspace para sincronização automática de agendamentos.",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isGoogleConnected ? Icons.check_circle : Icons.error_outline,
                          color: _isGoogleConnected ? AppColors.actionRight : AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isGoogleConnected ? "Conta Conectada" : "Não conectado",
                          style: TextStyle(
                            color: _isGoogleConnected ? AppColors.actionRight : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _isGoogleConnected ? AppColors.actionDown : AppColors.actionUp),
                      ),
                      onPressed: _toggleGoogleConnection,
                      child: Text(
                        _isGoogleConnected ? "Desconectar" : "Conectar Google",
                        style: TextStyle(
                          color: _isGoogleConnected ? AppColors.actionDown : AppColors.actionUp,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Perfil Conectado
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.glassBackgroundLight,
                  ),
                  child: const Icon(Icons.account_circle, color: Colors.white70, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.currentUser.fullName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "${widget.currentUser.role.label} • ${widget.currentUser.email}",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Botão Sair (Logout)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionDown.withOpacity(0.85),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              await widget.authService.signOut();
              widget.onLogout();
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            label: const Text(
              "Sair da Conta (Logout)",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
