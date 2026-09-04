import 'package:flutter_test/flutter_test.dart';
import 'package:esquadrao_comercial/core/constants/app_enums.dart';
import 'package:esquadrao_comercial/models/lead_model.dart';

void main() {
  group('Voicemail Expiration & Queue Return Logic', () {
    test('Marking lead as voicemail sets CAIXA_POSTAL and exactly 30min future timestamp', () {
      final lead = LeadModel(
        id: 'lead-123',
        name: 'Cliente Teste',
        phone: '61999991234',
        status: LeadStatus.emAtendimento,
      );

      const voicemailMinutes = 30;
      final before = DateTime.now();
      final returnTime = before.add(const Duration(minutes: voicemailMinutes));

      final updatedLead = lead.copyWith(
        status: LeadStatus.caixaPostal,
        attemptCount: lead.attemptCount + 1,
        lastContactAt: before,
        nextActionAt: returnTime,
        clearAssignedOperator: true,
      );

      expect(updatedLead.status, equals(LeadStatus.caixaPostal));
      expect(updatedLead.attemptCount, equals(1));
      expect(updatedLead.assignedOperatorId, isNull);
      expect(updatedLead.nextActionAt, isNotNull);

      // Intervalo deve ser exatamente de 30 minutos
      final diffMinutes = updatedLead.nextActionAt!.difference(before).inMinutes;
      expect(diffMinutes, equals(30));
    });

    test('Expired voicemail leads (>30 min) should be eligible for central queue return', () {
      final expiredLead = LeadModel(
        id: 'lead-expired',
        name: 'Cliente Expirado',
        phone: '61988887777',
        status: LeadStatus.caixaPostal,
        nextActionAt: DateTime.now().subtract(const Duration(minutes: 5)), // Venceu há 5 min
      );

      final activeVoicemailLead = LeadModel(
        id: 'lead-active',
        name: 'Cliente Ativo',
        phone: '61988886666',
        status: LeadStatus.caixaPostal,
        nextActionAt: DateTime.now().add(const Duration(minutes: 20)), // Faltam 20 min
      );

      final now = DateTime.now();

      // Simulação da condição da query SQL do backend:
      // status = 'CAIXA_POSTAL' AND next_action_at <= NOW()
      bool isEligibleForReturn(LeadModel l) =>
          l.status == LeadStatus.caixaPostal &&
          l.nextActionAt != null &&
          l.nextActionAt!.isBefore(now);

      expect(isEligibleForReturn(expiredLead), isTrue);
      expect(isEligibleForReturn(activeVoicemailLead), isFalse);
    });
  });
}
