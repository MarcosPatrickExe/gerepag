import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';

class OmieHealthPanel extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieHealthPanel({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final runway = provider.omieRunway;
    final overdue = provider.omieOverdue;
    
    return Row(
      children: [
        Expanded(
          child: _buildHealthCard(
            'FÔLEGO ATUAL',
            '${runway.toStringAsFixed(1)} Meses',
            Icons.speed,
            runway > 3 ? Colors.greenAccent : Colors.orangeAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildHealthCard(
            'EM ATRASO',
            NumberFormat.simpleCurrency(locale: 'pt_BR').format(overdue),
            Icons.warning_amber_rounded,
            overdue > 0 ? Colors.redAccent : Colors.white24,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
