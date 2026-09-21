import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';

class OmieExpenseDonut extends StatelessWidget {
  final TransactionsProvider provider;
  final Function(String) onCategoryTap;

  const OmieExpenseDonut({
    super.key,
    required this.provider,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = provider.omieExpenseDonutData;
    if (data.isEmpty) return const SizedBox.shrink();

    final List<Color> colors = [Colors.blue, Colors.purple, Colors.orange, Colors.cyan, Colors.pink, Colors.amber];
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VAZÃO DE CAIXA POR CATEGORIA 💸', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) return;
                    final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    if (index >= 0 && index < data.length) {
                      final category = data.keys.elementAt(index);
                      onCategoryTap(category);
                    }
                  },
                ),
                sections: data.entries.indexed.map((e) {
                  final index = e.$1;
                  final entry = e.$2;
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: entry.value,
                    title: '',
                    radius: 20,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...data.entries.take(5).indexed.map((e) {
            final index = e.$1;
            final entry = e.$2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(_getCategoryIcon(entry.key), color: colors[index % colors.length], size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(color: AppTheme.textBody, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          currency.format(entry.value),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('pessoal')) return Icons.person;
    if (n.contains('carro') || n.contains('combust')) return Icons.directions_car;
    if (n.contains('alug')) return Icons.home;
    if (n.contains('comida') || n.contains('rest')) return Icons.restaurant;
    if (n.contains('saud')) return Icons.medical_services;
    if (n.contains('lazer')) return Icons.celebration;
    if (n.contains('taxa') || n.contains('impost')) return Icons.receipt_long;
    if (n.contains('invest')) return Icons.trending_up;
    return Icons.category;
  }
}
