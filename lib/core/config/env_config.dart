import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // Fallback gracioso caso .env não exista ou esteja vazio
      print('Aviso: Arquivo .env não encontrado ou não inicializado: $e');
    }
  }

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get googleClientIdWeb => dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? '';
  static String get googleClientIdAndroid => dotenv.env['GOOGLE_CLIENT_ID_ANDROID'] ?? '';
  static String get googleClientIdIos => dotenv.env['GOOGLE_CLIENT_ID_IOS'] ?? '';

  static int get defaultVoicemailReturnMinutes {
    final val = dotenv.env['DEFAULT_VOICEMAIL_RETURN_MINUTES'];
    return int.tryParse(val ?? '30') ?? 30;
  }

  static int get defaultDailyLeadGoal {
    final val = dotenv.env['DEFAULT_DAILY_LEAD_GOAL'];
    return int.tryParse(val ?? '30') ?? 30;
  }

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project-id') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('your-anon-key');

  static bool get isGoogleOAuthConfigured =>
      googleClientIdWeb.isNotEmpty ||
      googleClientIdAndroid.isNotEmpty ||
      googleClientIdIos.isNotEmpty;
}
