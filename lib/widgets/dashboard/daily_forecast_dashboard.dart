import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';
import 'premium_bi_header.dart';

class DailyForecastDashboard extends StatelessWidget {
  final TransactionsProvider provider;

  const DailyForecastDashboard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final forecast = provider.omieCashFlowForecast;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final isYearly = provider.filterMode == OmieFilterMode.yearly;

    // Constrói a lista de exibição agrupada se for visão anual, ou diária se for mensal/outros
    final List<Map<String, dynamic>> displayList = [];
    if (isYearly) {
      // Agrupa a curva diária de 365 dias para mostrar o saldo de fechamento de cada um dos 12 meses do ano
      for (int m = 1; m <= 12; m++) {
        final monthForecast = forecast.where((d) => (d['date'] as DateTime).month == m).toList();
        if (monthForecast.isNotEmpty) {
          final lastDayOfM = monthForecast.last;
          displayList.add({
            'label': DateFormat('MMMM', 'pt_BR').format(lastDayOfM['date'] as DateTime).toUpperCase(),
            'date': lastDayOfM['date'],
            'balance': lastDayOfM['balance'],
          });
        }
      }
    } else {
      // Mostra a listagem diária padrão
      for (var d in forecast) {
        displayList.add({
          'label': DateFormat('dd/MM').format(d['date'] as DateTime),
          'date': d['date'],
          'balance': d['balance'],
        });
      }
    }

    return Column(
      children: [
        PremiumBIHeader(provider: provider),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isYearly 
                    ? 'PROJEÇÃO MENSAL DE CAIXA (ANO ${provider.selectedYear}) 📅'
                    : 'PROJEÇÃO DIÁRIA DE CAIXA (30 DIAS) 📅',
                style: const TextStyle(
                  color: AppTheme.textBody,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              if (displayList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text(
                      'Sem dados de faturamento para esta projeção.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final item = displayList[index];
                    final balance = item['balance'] as double;
                    final isPositive = balance >= 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: isYearly ? 100 : 50,
                            child: Text(
                              item['label'] as String,
                              style: const TextStyle(
                                color: AppTheme.textMuted, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: (balance.abs() / 150000).clamp(0.05, 1.0),
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isPositive ? AppTheme.income : AppTheme.expense,
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: LinearGradient(
                                        colors: isPositive
                                            ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                                            : [const Color(0xFFEF4444), const Color(0xFFF87171)],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            currency.format(balance),
                            style: TextStyle(
                              color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
