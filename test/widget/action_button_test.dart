import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esquadrao_comercial/core/constants/app_colors.dart';
import 'package:esquadrao_comercial/shared/widgets/action_button.dart';

void main() {
  group('ActionButton Widget Tests', () {
    testWidgets('Renders label and executes onTap callback upon user tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ActionButton(
                icon: Icons.phone,
                color: AppColors.actionRight,
                label: 'LIGAR',
                semanticDescription: 'Acionar discador nativo',
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verifica exibição do label
      expect(find.text('LIGAR'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);

      // Toca no botão
      await tester.tap(find.byType(ActionButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('Has accessibility semantics enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ActionButton(
                icon: Icons.calendar_month,
                color: AppColors.actionUp,
                label: 'AGENDAR',
                semanticDescription: 'Abrir fluxo de agendamento Google Calendar',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(ActionButton));
      expect(semantics.label, contains('Abrir fluxo de agendamento'));
    });
  });
}
