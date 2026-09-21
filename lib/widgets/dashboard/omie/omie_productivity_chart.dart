import 'package:flutter/material.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';

class OmieProductivityChart extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieProductivityChart({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final stats = provider.omieProductivityStats;
    final created = stats['created']?.toDouble() ?? 0;
    final completed = stats['completed']?.toDouble() ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EFICIÊNCIA OPERACIONAL 🚀', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressCircle('Captado', created, Colors.blueAccent),
              _buildProgressCircle('Entregue', completed, Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Ritmo de Entrega: ${(created > 0 ? (completed / created * 100) : 0).toStringAsFixed(0)}%', 
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: created > 0 ? completed / created : 0,
              backgroundColor: Colors.white10,
              color: Colors.greenAccent,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(String label, double value, Color color) {
    return Column(
      children: [
        Text(value.toInt().toString(), style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
