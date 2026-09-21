import 'package:flutter/material.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';

class OmieABCRanking extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieABCRanking({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final abc = provider.omieTopClientsABC;
    if (abc.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURVA ABC (TOP CLIENTES) 🥇', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...abc.take(5).map((client) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: client['class'] == 'A' ? Colors.amber.withValues(alpha: 0.2) : Colors.white10,
                  child: Text(client['class'], style: TextStyle(color: client['class'] == 'A' ? Colors.amber : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(client['client'], style: const TextStyle(color: AppTheme.textBody, fontSize: 12), overflow: TextOverflow.ellipsis)),
                Text('${client['percent'].toStringAsFixed(1)}%', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
