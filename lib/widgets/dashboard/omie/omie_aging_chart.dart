import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';

class OmieAgingChart extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieAgingChart({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final aging = provider.omieAgingData;
    if (aging.values.every((v) => v == 0)) return const SizedBox.shrink();

    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final totalAtrasado = aging.values.reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RADAR DE INADIMPLÊNCIA (AGING) ⏳', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...aging.entries.map((e) {
            final double percent = totalAtrasado > 0 ? (e.value / totalAtrasado) : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      Text(currency.format(e.value), style: const TextStyle(color: AppTheme.textBody, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent.clamp(0.01, 1.0),
                      backgroundColor: Colors.white10,
                      color: percent > 0.4 ? Colors.redAccent : Colors.orangeAccent,
                      minHeight: 4,
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
}
