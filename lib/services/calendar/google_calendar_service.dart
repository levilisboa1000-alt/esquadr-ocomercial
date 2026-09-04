import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env_config.dart';
import '../../models/lead_model.dart';
import '../../models/user_model.dart';

class GoogleCalendarService {
  final SupabaseClient _supabase;
  GoogleSignIn? _googleSignIn;

  GoogleCalendarService({required SupabaseClient supabase}) : _supabase = supabase {
    _initGoogleSignIn();
  }

  void _initGoogleSignIn() {
    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        gcal.CalendarApi.calendarEventsScope,
      ],
      clientId: EnvConfig.googleClientIdWeb.isNotEmpty
          ? EnvConfig.googleClientIdWeb
          : null,
    );
  }

  /// Verifica se o usuário atual possui uma conta Google conectada
  Future<bool> isAccountConnected(String userId) async {
    try {
      final response = await _supabase
          .from('google_calendar_accounts')
          .select('id, is_active')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null && response['is_active'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Inicia o fluxo real de autenticação OAuth 2.0 com o Google
  Future<GoogleSignInAccount?> connectGoogleAccount(String userId) async {
    if (!EnvConfig.isGoogleOAuthConfigured) {
      throw Exception(
        'Credenciais do Google OAuth não configuradas no .env. '
        'Configure GOOGLE_CLIENT_ID_WEB no arquivo .env.',
      );
    }

    try {
      final account = await _googleSignIn!.signIn();
      if (account == null) return null; // Cancelado pelo usuário

      final auth = await account.authentication;
      final accessToken = auth.accessToken;

      if (accessToken != null) {
        // Salva na tabela google_calendar_accounts
        await _supabase.from('google_calendar_accounts').upsert({
          'user_id': userId,
          'email': account.email,
          'access_token': accessToken,
          'calendar_id': 'primary',
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return account;
    } catch (e) {
      print('Erro ao autenticar no Google Calendar: $e');
      rethrow;
    }
  }

  /// Desconecta a conta Google do usuário
  Future<void> disconnectGoogleAccount(String userId) async {
    try {
      await _googleSignIn?.signOut();
      await _supabase
          .from('google_calendar_accounts')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId);
    } catch (e) {
      print('Erro ao desconectar conta Google: $e');
    }
  }

  /// Obtém um cliente autenticado para a API do Google Calendar
  Future<gcal.CalendarApi?> _getCalendarApi() async {
    if (_googleSignIn == null) return null;

    GoogleSignInAccount? account = _googleSignIn!.currentUser;
    account ??= await _googleSignIn!.signInSilently();

    account ??= await _googleSignIn!.signIn();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final authenticateClient = _GoogleAuthClient(authHeaders);
    return gcal.CalendarApi(authenticateClient);
  }

  /// Cria um evento real no Google Calendar
  Future<String?> createEvent({
    required LeadModel lead,
    required UserModel operator,
    required DateTime scheduledAt,
    required String notes,
    int durationMinutes = 60,
  }) async {
    try {
      final calendarApi = await _getCalendarApi();
      if (calendarApi == null) {
        throw Exception('Não foi possível obter acesso à Google Calendar API');
      }

      final startDateTime = scheduledAt.toUtc();
      final endDateTime = startDateTime.add(Duration(minutes: durationMinutes));

      final event = gcal.Event(
        summary: 'Atendimento: ${lead.name} [Esquadrão Comercial]',
        description: '''
Cliente: ${lead.name}
Telefone: ${lead.phone}
Localização: ${lead.city} - ${lead.state}
Interesse: ${lead.interest}
Valor: R\$ ${lead.propertyValue.toStringAsFixed(2)}
Operador Responsável: ${operator.fullName}
Observações: $notes
Origem: ${lead.source}
''',
        start: gcal.EventDateTime(
          dateTime: startDateTime,
          timeZone: 'UTC',
        ),
        end: gcal.EventDateTime(
          dateTime: endDateTime,
          timeZone: 'UTC',
        ),
        reminders: gcal.EventReminders(
          useDefault: false,
          overrides: [
            gcal.EventReminder(method: 'popup', minutes: 1440), // 24 horas antes
            gcal.EventReminder(method: 'popup', minutes: 60),   // 1 hora antes
          ],
        ),
      );

      final created = await calendarApi.events.insert(event, 'primary');
      return created.id;
    } catch (e) {
      print('Erro ao criar evento no Google Calendar: $e');
      rethrow;
    }
  }

  /// Cancela/remove um evento do Google Calendar
  Future<bool> cancelEvent(String eventId) async {
    try {
      final calendarApi = await _getCalendarApi();
      if (calendarApi == null) return false;
      await calendarApi.events.delete('primary', eventId);
      return true;
    } catch (e) {
      print('Erro ao cancelar evento no Google Calendar: $e');
      return false;
    }
  }
}

/// Cliente HTTP com cabeçalhos de autenticação Bearer
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}
