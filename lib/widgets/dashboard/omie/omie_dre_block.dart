import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';

class OmieDREBlock extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieDREBlock({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final dre = provider.omieDRE;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DRE GERENCIAL (MÊS) 📊', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          _buildDRERow('Receita Bruta', currency.format(dre['revenue']), Colors.white),
          const SizedBox(height: 12),
          _buildDRERow('Despesas Totais', currency.format(dre['expenses']), Colors.white.withValues(alpha: 0.7)),
          const Divider(height: 24, color: Colors.white24),
          _buildDRERow('Lucro/Prejuízo', currency.format(dre['profit']), Colors.white, isBold: true),
        ],
      ),
    );
  }

  Widget _buildDRERow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
