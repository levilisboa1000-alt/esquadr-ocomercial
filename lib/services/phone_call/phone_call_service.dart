import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/phone_utils.dart';
import '../../models/lead_model.dart';

class PhoneCallService {
  LeadModel? _activeLeadInCall;
  DateTime? _callStartTime;

  LeadModel? get activeLeadInCall => _activeLeadInCall;
  bool get hasPendingCallFeedback => _activeLeadInCall != null;

  /// Inicia o processo de ligação:
  /// 1. Sanitiza o telefone e gera a URL no esquema nativo tel:
  /// 2. Salva o contexto do lead atual em memória
  /// 3. Lança o discador nativo com o número preenchido
  Future<bool> initiateCall(LeadModel lead) async {
    final telUriString = PhoneUtils.toTelUri(lead.phone);
    final Uri uri = Uri.parse(telUriString);

    _activeLeadInCall = lead;
    _callStartTime = DateTime.now();

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return launched;
      } else {
        // Tenta fallback com o número limpo simples
        final fallbackUri = Uri.parse('tel:${PhoneUtils.cleanDigits(lead.phone)}');
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Erro ao lançar discador nativo: $e');
      return false;
    }
  }

  /// Calcula a duração estimada da chamada em segundos desde o disparo do discador
  int getEstimatedDurationSeconds() {
    if (_callStartTime == null) return 0;
    final diff = DateTime.now().difference(_callStartTime!).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Limpa o contexto de chamada pendente após o operador preencher o feedback
  void clearActiveCallContext() {
    _activeLeadInCall = null;
    _callStartTime = null;
  }
}
