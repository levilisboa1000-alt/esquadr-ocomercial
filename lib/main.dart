import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env_config.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/liquid_theme.dart';
import 'models/user_model.dart';

import 'services/audit/audit_service.dart';
import 'services/auth/supabase_auth_service.dart';
import 'services/calendar/google_calendar_service.dart';
import 'services/lead_distribution/lead_distribution_service.dart';
import 'services/phone_call/phone_call_service.dart';
import 'services/voicemail/voicemail_scheduler_service.dart';

import 'repositories/appointment_repository.dart';
import 'repositories/call_repository.dart';
import 'repositories/lead_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/user_repository.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/admin_operations_center.dart';
import 'features/operator/controllers/operator_controller.dart';
import 'features/operator/screens/operator_deck_screen.dart';
import 'shared/widgets/liquid_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Configura overlay de sistema translúcido
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.backgroundStart,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // 2. Carrega variáveis de ambiente
  await EnvConfig.initialize();

  // 3. Inicializa o cliente Supabase se configurado
  if (EnvConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
    } catch (e) {
      print('Erro ao inicializar Supabase: $e');
    }
  }

  runApp(const EsquadraoComercialApp());
}

class EsquadraoComercialApp extends StatelessWidget {
  const EsquadraoComercialApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instância segura do Supabase (mesmo em modo offline/sem credenciais)
    final supabase = Supabase.instance.client;

    // Injeção de dependências modular
    final auditService = AuditService(client: supabase);
    final authService = SupabaseAuthService(client: supabase, auditService: auditService);
    final calendarService = GoogleCalendarService(supabase: supabase);
    final voicemailService = VoicemailSchedulerService(supabase: supabase, auditService: auditService);
    final distributionService = LeadDistributionService(
      supabase: supabase,
      voicemailService: voicemailService,
      auditService: auditService,
    );
    final phoneCallService = PhoneCallService();

    final leadRepository = LeadRepository(supabase: supabase);
    final callRepository = CallRepository(supabase: supabase);
    final appointmentRepository = AppointmentRepository(supabase: supabase);
    final userRepository = UserRepository(supabase: supabase);
    final settingsRepository = SettingsRepository(supabase: supabase);

    return MultiProvider(
      providers: [
        Provider<SupabaseClient>.value(value: supabase),
        Provider<AuditService>.value(value: auditService),
        Provider<SupabaseAuthService>.value(value: authService),
        Provider<GoogleCalendarService>.value(value: calendarService),
        Provider<VoicemailSchedulerService>.value(value: voicemailService),
        Provider<LeadDistributionService>.value(value: distributionService),
        Provider<PhoneCallService>.value(value: phoneCallService),
        Provider<LeadRepository>.value(value: leadRepository),
        Provider<CallRepository>.value(value: callRepository),
        Provider<AppointmentRepository>.value(value: appointmentRepository),
        Provider<UserRepository>.value(value: userRepository),
        Provider<SettingsRepository>.value(value: settingsRepository),
      ],
      child: MaterialApp(
        title: 'Esquadrão Comercial',
        debugShowCheckedModeBanner: false,
        theme: LiquidTheme.darkTheme,
        builder: (context, child) {
          return LiquidBackground(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AppRootNavigator(),
      ),
    );
  }
}

/// Navegador raiz reativo que direciona o usuário baseado no estado de login e papel
class AppRootNavigator extends StatefulWidget {
  const AppRootNavigator({super.key});

  @override
  State<AppRootNavigator> createState() => _AppRootNavigatorState();
}

class _AppRootNavigatorState extends State<AppRootNavigator> {
  UserModel? _loggedUser;

  @override
  void initState() {
    super.initState();
    final authService = context.read<SupabaseAuthService>();
    _loggedUser = authService.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<SupabaseAuthService>();
    final user = _loggedUser ?? authService.currentUser;

    // Se não estiver logado -> Tela de Login
    if (user == null) {
      return LoginScreen(
        authService: authService,
        onLoginSuccess: (logged) {
          setState(() => _loggedUser = logged);
        },
      );
    }

    // Se for Administrador ou Supervisor -> Central de Operações
    if (user.canAccessAdminPanel) {
      return AdminOperationsCenter(
        currentUser: user,
        authService: authService,
        calendarService: context.read<GoogleCalendarService>(),
        distributionService: context.read<LeadDistributionService>(),
        auditService: context.read<AuditService>(),
        onLogout: () {
          setState(() => _loggedUser = null);
        },
      );
    }

    // Se for Operador -> Tinder de Leads com Controller Dedicado
    return ChangeNotifierProvider(
      create: (_) => OperatorController(
        operator: user,
        distributionService: context.read<LeadDistributionService>(),
        phoneCallService: context.read<PhoneCallService>(),
        calendarService: context.read<GoogleCalendarService>(),
        voicemailService: context.read<VoicemailSchedulerService>(),
        leadRepository: context.read<LeadRepository>(),
        callRepository: context.read<CallRepository>(),
        appointmentRepository: context.read<AppointmentRepository>(),
        auditService: context.read<AuditService>(),
      ),
      child: const OperatorDeckScreen(),
    );
  }
}
