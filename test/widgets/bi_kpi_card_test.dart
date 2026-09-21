import 'package:appfinancerio/widgets/bi/bi_kpi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BiKpiCard renders metric, context and positive trend', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BiKpiCard(
            title: 'Receita',
            value: 'R\$ 25.000',
            subtitle: 'Mês atual',
            icon: Icons.payments,
            iconColor: Colors.blue,
            trendColor: Colors.green,
            trendText: '+12%',
          ),
        ),
      ),
    );

    expect(find.text('RECEITA'), findsOneWidget);
    expect(find.text('R\$ 25.000'), findsOneWidget);
    expect(find.text('Mês atual'), findsOneWidget);
    expect(find.text('+12%'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.byIcon(Icons.payments), findsOneWidget);
  });
}
