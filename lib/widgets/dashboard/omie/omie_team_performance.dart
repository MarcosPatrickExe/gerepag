import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';

class OmieTeamPerformance extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieTeamPerformance({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final perf = provider.omieTeamPerformance;
    final sales = perf['sales'] ?? {};
    final tech = perf['tech'] ?? {};
    
    if (sales.isEmpty && tech.isEmpty) return const SizedBox.shrink();

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
          const Text('PERFORMANCE DA EQUIPE 🤝', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (sales.isNotEmpty) ...[
            const Text('VENDAS (POR VALOR)', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...sales.entries.take(3).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(radius: 12, backgroundColor: Colors.white.withValues(alpha: 0.2), child: const Icon(Icons.star, color: Colors.white, size: 10)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 11))),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(NumberFormat.simpleCurrency(locale: 'pt_BR').format(e.value['value'] ?? 0.0), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('${e.value['count']} pedidos', style: const TextStyle(color: Colors.white60, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            )),
          ],
          const Divider(height: 32, color: Colors.white12),
          if (tech.isNotEmpty) ...[
            const Text('TÉCNICOS (POR QTD OS)', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...tech.entries.take(3).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(radius: 12, backgroundColor: Colors.white.withValues(alpha: 0.2), child: const Icon(Icons.build, color: Colors.white, size: 10)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 11))),
                  Text('${e.value['count']} OS', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}
