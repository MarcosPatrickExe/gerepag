import 'package:flutter/material.dart';
import '../../../providers/transactions_provider.dart';

class OmieCashFlowHeatmap extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieCashFlowHeatmap({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final heatmap = provider.omieCashFlowHeatmap;
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
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MAPA DE TENSÃO DE CAIXA 📅', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: 31,
            itemBuilder: (context, index) {
              final day = index + 1;
              final balance = heatmap[day] ?? 0.0;
              Color color = Colors.white.withValues(alpha: 0.1);
              if (balance > 0) color = Colors.greenAccent.withValues(alpha: 0.6);
              else if (balance < 0) color = Colors.amberAccent.withValues(alpha: 0.6);

              return Container(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('$day', style: const TextStyle(color: Colors.white70, fontSize: 10))),
              );
            },
          ),
        ],
      ),
    );
  }
}
