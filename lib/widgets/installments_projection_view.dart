import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import '../models/transaction_model.dart';

class InstallmentsProjectionView extends StatelessWidget {
  const InstallmentsProjectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    return StatefulBuilder(
      builder: (context, setState) {
        String? selectedFilterCardId;
        final projectionData = _generateRealProjection(provider, cardId: selectedFilterCardId);
        final totalComprometido = projectionData.fold<double>(0, (sum, val) => sum + val);
        final maxVal = projectionData.isNotEmpty ? projectionData.reduce((a, b) => a > b ? a : b) : 0.0;
        final chartMaxY = maxVal == 0 ? 100.0 : maxVal * 1.2;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PROJEÇÃO DE FLUXO',
                    style: TextStyle(color: AppTheme.textBody, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (provider.creditCards.isNotEmpty)
                    DropdownButton<String?>(
                      value: selectedFilterCardId,
                      dropdownColor: AppTheme.surface,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.filter_list, color: AppTheme.primary),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todos os Cartões', style: TextStyle(color: AppTheme.textBody, fontSize: 12))),
                        ...provider.creditCards.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: const TextStyle(color: AppTheme.textBody, fontSize: 12)),
                        )),
                      ],
                      onChanged: (val) => setState(() => selectedFilterCardId = val),
                    ),
                ],
              ),
          const SizedBox(height: 8),
          const Text(
            'Visão real dos seus lançamentos futuros e parcelas de cartão.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Comprometido (Próx 6 meses)', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  currency.format(totalComprometido),
                  style: const TextStyle(color: AppTheme.expense, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => AppTheme.surface,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final date = DateTime.now().add(Duration(days: 30 * group.x.toInt()));
                            final monthTransactions = provider.transactions.where((t) => 
                              t.type == TransactionType.expense &&
                              t.date.year == date.year &&
                              t.date.month == date.month
                            ).toList();

                            String breakdown = '';
                            if (monthTransactions.isNotEmpty) {
                              // Agrupar por categoria para o resumo
                              final map = <String, double>{};
                              for (var t in monthTransactions) {
                                map[t.category] = (map[t.category] ?? 0) + t.amount;
                              }
                              breakdown = '\n' + map.entries.map((e) => '${e.key}: ${currency.format(e.value)}').join('\n');
                            }

                            return BarTooltipItem(
                              '${currency.format(rod.toY)}$breakdown',
                              const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 10),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final date = DateTime.now().add(Duration(days: 30 * value.toInt()));
                              final monthFormat = DateFormat.MMM('pt_BR');
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  monthFormat.format(date).toUpperCase(),
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(6, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: projectionData[index],
                              color: AppTheme.expense.withValues(alpha: 0.8),
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: chartMaxY,
                                color: AppTheme.textBody.withValues(alpha: 0.05),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'POR QUE DESSE VALOR?',
            style: TextStyle(color: AppTheme.textBody, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Resumo por categoria dos próximos 6 meses
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.textBody.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: _generateCategorySummary(provider, currency, cardId: selectedFilterCardId),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'DETALHAMENTO FUTURO',
            style: TextStyle(color: AppTheme.textBody, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Lista de transações futuras (parcelas)
          ...provider.transactions
              .where((t) => 
                t.date.isAfter(DateTime.now()) && 
                t.type == TransactionType.expense &&
                (selectedFilterCardId == null || t.creditCardId == selectedFilterCardId)
              )
              .map((t) => _buildFutureTransactionTile(t, currency)),
        ],
      ),
    );
  },
);
}

  Widget _buildFutureTransactionTile(dynamic t, NumberFormat currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.textBody.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.expense.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today, color: AppTheme.expense, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.category,
                  style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(t.date),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(t.amount),
                style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold),
              ),
              if (t.totalInstallments != null)
                Text(
                  '${t.currentInstallment}/${t.totalInstallments}',
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<double> _generateRealProjection(TransactionsProvider provider, {String? cardId}) {
    final List<double> result = List.filled(6, 0.0);
    final now = DateTime.now();

    for (int i = 0; i < 6; i++) {
      final targetDate = DateTime(now.year, now.month + i, 1);
      
      // Somar todas as despesas (incluindo crédito/parcelas) que caem neste mês
      final monthTotal = provider.transactions
          .where((t) => 
              t.type == TransactionType.expense &&
              t.date.year == targetDate.year &&
              t.date.month == targetDate.month &&
              (cardId == null || t.creditCardId == cardId)
          )
          .fold(0.0, (sum, t) => sum + t.amount);
      
      result[i] = monthTotal;
    }

    return result;
  }

  List<Widget> _generateCategorySummary(TransactionsProvider provider, NumberFormat currency, {String? cardId}) {
    final now = DateTime.now();
    final futureExpenses = provider.transactions.where((t) => 
      t.type == TransactionType.expense && 
      t.date.isAfter(DateTime(now.year, now.month, 0)) &&
      (cardId == null || t.creditCardId == cardId)
    ).toList();

    if (futureExpenses.isEmpty) {
      return [const Text('Nenhuma despesa futura projetada.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12))];
    }

    final categoryTotals = <String, double>{};
    for (var t in futureExpenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(entry.key, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            Text(currency.format(entry.value), style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }).toList();
  }
}
