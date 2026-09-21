import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';

class PremiumBIHeader extends StatelessWidget {
  final TransactionsProvider provider;

  const PremiumBIHeader({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final summary = provider.omieSummary;
    final double aReceber = double.tryParse(summary?['contaReceber']?['vTotal']?.toString() ?? '0.0') ?? 0.0;
    final double aPagar = double.tryParse(summary?['contaPagar']?['vTotal']?.toString() ?? '0.0') ?? 0.0;
    final double saldo = double.tryParse(summary?['contaCorrente']?['vTotal']?.toString() ?? '0.0') ?? 0.0;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildMetric('SALDO', currency.format(saldo), Colors.blueAccent)),
          _buildDivider(),
          Expanded(child: _buildMetric('A RECEBER', currency.format(aReceber), Colors.greenAccent)),
          _buildDivider(),
          Expanded(child: _buildMetric('A PAGAR', currency.format(aPagar), Colors.orangeAccent)),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDivider() => Container(width: 1, height: 30, color: AppTheme.textBody.withValues(alpha: 0.05), margin: const EdgeInsets.symmetric(horizontal: 12));
}
