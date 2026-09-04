import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../repositories/lead_repository.dart';
import '../../../repositories/appointment_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/settings_repository.dart';
import '../../../services/auth/supabase_auth_service.dart';
import '../../../services/calendar/google_calendar_service.dart';
import '../../../services/lead_distribution/lead_distribution_service.dart';
import '../../../services/audit/audit_service.dart';
import '../tabs/admin_home_tab.dart';
import '../../leads/tabs/admin_leads_tab.dart';
import '../../calendar/tabs/admin_calendar_tab.dart';
import '../../team/tabs/admin_team_tab.dart';
import '../../settings/tabs/admin_more_tab.dart';

class AdminOperationsCenter extends StatefulWidget {
  final UserModel currentUser;
  final SupabaseAuthService authService;
  final GoogleCalendarService calendarService;
  final LeadDistributionService distributionService;
  final AuditService auditService;
  final VoidCallback onLogout;

  const AdminOperationsCenter({
    super.key,
    required this.currentUser,
    required this.authService,
    required this.calendarService,
    required this.distributionService,
    required this.auditService,
    required this.onLogout,
  });

  @override
  State<AdminOperationsCenter> createState() => _AdminOperationsCenterState();
}

class _AdminOperationsCenterState extends State<AdminOperationsCenter> {
  int _currentIndex = 0;
  late final SupabaseClient _supabase;
  late final LeadRepository _leadRepository;
  late final AppointmentRepository _appointmentRepository;
  late final UserRepository _userRepository;
  late final SettingsRepository _settingsRepository;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _leadRepository = LeadRepository(supabase: _supabase);
    _appointmentRepository = AppointmentRepository(supabase: _supabase);
    _userRepository = UserRepository(supabase: _supabase);
    _settingsRepository = SettingsRepository(supabase: _supabase);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminHomeTab(supabase: _supabase, auditService: widget.auditService),
      AdminLeadsTab(
        leadRepository: _leadRepository,
        userRepository: _userRepository,
        distributionService: widget.distributionService,
        auditService: widget.auditService,
      ),
      AdminCalendarTab(appointmentRepository: _appointmentRepository),
      AdminTeamTab(userRepository: _userRepository),
      AdminMoreTab(
        currentUser: widget.currentUser,
        settingsRepository: _settingsRepository,
        authService: widget.authService,
        calendarService: widget.calendarService,
        auditService: widget.auditService,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: screens[_currentIndex],
      extendBody: true, // Permite que o conteúdo deslize por baixo da barra translúcida
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.0),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: AppColors.backgroundStart.withOpacity(0.65),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.actionUp,
              unselectedItemColor: AppColors.textSecondary,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  activeIcon: Icon(Icons.bar_chart_rounded, color: AppColors.actionUp),
                  label: 'Início',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_alt_outlined),
                  activeIcon: Icon(Icons.people_alt_rounded, color: AppColors.actionUp),
                  label: 'Leads',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined),
                  activeIcon: Icon(Icons.calendar_month_rounded, color: AppColors.actionUp),
                  label: 'Agenda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.badge_outlined),
                  activeIcon: Icon(Icons.badge_rounded, color: AppColors.actionUp),
                  label: 'Equipe',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz_rounded),
                  activeIcon: Icon(Icons.more_horiz_rounded, color: AppColors.actionUp),
                  label: 'Mais',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
