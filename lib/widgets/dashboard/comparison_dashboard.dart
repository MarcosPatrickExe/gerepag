import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';
import 'premium_bi_header.dart';

class ComparisonDashboard extends StatelessWidget {
  final TransactionsProvider provider;

  const ComparisonDashboard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final comparisonData = provider.omieDREComparison;
    return Column(
      children: [
        PremiumBIHeader(provider: provider),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Categoria', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ano Atual', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ano Anterior', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Var %', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
              ],
              rows: comparisonData.entries.map((e) {
                final current = e.value['current'] ?? 0.0;
                final previous = e.value['previous'] ?? 0.0;
                final varPercent = previous > 0 ? (current - previous) / previous * 100 : 0.0;
                final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

                return DataRow(cells: [
                  DataCell(Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 11))),
                  DataCell(Text(currency.format(current), style: const TextStyle(color: Colors.white, fontSize: 11))),
                  DataCell(Text(currency.format(previous), style: const TextStyle(color: Colors.white70, fontSize: 11))),
                  DataCell(Text('${varPercent.toStringAsFixed(1)}%', style: TextStyle(color: varPercent >= 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold))),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
