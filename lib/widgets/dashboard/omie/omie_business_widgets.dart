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

class OmieFlashCashBanner extends StatelessWidget {
  final TransactionsProvider provider;
  const OmieFlashCashBanner({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final totalPotencial = provider.omieFlashCash;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.flash_on, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SALDO POTENCIAL ("FLASH CASH") ⚡', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                const Text('Se faturar tudo o que está aberto hoje:', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          Text(currency.format(totalPotencial), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

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
