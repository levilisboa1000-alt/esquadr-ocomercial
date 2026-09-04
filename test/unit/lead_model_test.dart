import 'package:flutter_test/flutter_test.dart';
import 'package:esquadrao_comercial/core/constants/app_enums.dart';
import 'package:esquadrao_comercial/models/lead_model.dart';

void main() {
  group('LeadModel & Enums Tests', () {
    test('LeadModel serializes to and from JSON accurately', () {
      final lead = LeadModel(
        id: 'uuid-lead-001',
        name: 'Maria Oliveira',
        phone: '(61) 98765-4321',
        city: 'Brasília',
        state: 'DF',
        interest: 'Apartamento 3 Quartos',
        propertyValue: 450000.0,
        source: 'Google Ads',
        status: LeadStatus.novo,
        priority: LeadPriority.alta,
        attemptCount: 2,
      );

      final json = lead.toJson();
      expect(json['id'], equals('uuid-lead-001'));
      expect(json['name'], equals('Maria Oliveira'));
      expect(json['status'], equals('NOVO'));
      expect(json['priority'], equals('alta'));
      expect(json['property_value'], equals(450000.0));

      final restored = LeadModel.fromJson(json);
      expect(restored.id, equals(lead.id));
      expect(restored.name, equals(lead.name));
      expect(restored.status, equals(LeadStatus.novo));
      expect(restored.priority, equals(LeadPriority.alta));
      expect(restored.propertyValue, equals(450000.0));
    });

    test('LeadStatus parses all 12 operational statuses correctly', () {
      expect(LeadStatus.fromString('NOVO'), equals(LeadStatus.novo));
      expect(LeadStatus.fromString('DISTRIBUIDO'), equals(LeadStatus.distribuido));
      expect(LeadStatus.fromString('EM_ATENDIMENTO'), equals(LeadStatus.emAtendimento));
      expect(LeadStatus.fromString('LIGACAO_REALIZADA'), equals(LeadStatus.ligacaoRealizada));
      expect(LeadStatus.fromString('CAIXA_POSTAL'), equals(LeadStatus.caixaPostal));
      expect(LeadStatus.fromString('AGENDADO'), equals(LeadStatus.agendado));
      expect(LeadStatus.fromString('CONFIRMADO'), equals(LeadStatus.confirmado));
      expect(LeadStatus.fromString('ATENDIDO'), equals(LeadStatus.atendido));
      expect(LeadStatus.fromString('NAO_INTERESSADO'), equals(LeadStatus.naoInteressado));
      expect(LeadStatus.fromString('RETORNAR_PARA_FILA'), equals(LeadStatus.retornarParaFila));
      expect(LeadStatus.fromString('FINALIZADO'), equals(LeadStatus.finalizado));
      expect(LeadStatus.fromString('CANCELADO'), equals(LeadStatus.cancelado));
    });

    test('LeadModel copyWith properly updates targeted fields', () {
      final initial = LeadModel(
        id: 'lead-test',
        name: 'João Carlos',
        phone: '11988887777',
        status: LeadStatus.novo,
        assignedOperatorId: 'op-1',
      );

      final modified = initial.copyWith(
        status: LeadStatus.agendado,
        clearAssignedOperator: true,
      );

      expect(modified.status, equals(LeadStatus.agendado));
      expect(modified.assignedOperatorId, isNull);
      expect(modified.name, equals('João Carlos'));
    });
  });
}
