import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';

class OmieGoalBanner extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieGoalBanner({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final current = provider.omieMonthlyFaturamentoTotal;
    final goal = provider.omieGoal;
    final percent = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return GestureDetector(
      onTap: () => _showGoalEditDialog(context, provider),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RUMO AO RECORDE 🚀', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    SizedBox(height: 4),
                    Text('Meta de Faturamento Mensal', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Text('${(percent * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.amberAccent, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
              ],
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(height: 12, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6))),
                LayoutBuilder(
                  builder: (context, constraints) => AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    height: 12,
                    width: constraints.maxWidth * percent,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.amberAccent, Colors.orangeAccent]),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: Colors.amberAccent.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Faturado: ${currency.format(current)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                Text('Falta: ${currency.format(goal - current > 0 ? goal - current : 0)}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalEditDialog(BuildContext context, TransactionsProvider provider) {
    final controller = TextEditingController(text: provider.omieGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Definir Meta Mensal', style: TextStyle(color: AppTheme.textBody)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textBody),
          decoration: const InputDecoration(labelText: 'Valor da Meta (R\$)', labelStyle: TextStyle(color: AppTheme.textMuted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              provider.setOmieGoal(double.tryParse(controller.text) ?? 0.0);
              Navigator.pop(context);
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }
}
