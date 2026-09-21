import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BiSalesFunnelChart extends StatelessWidget {
  final Map<String, int> funnelStages;
  final Map<String, double> funnelAmounts;

  const BiSalesFunnelChart({
    super.key,
    required this.funnelStages,
    required this.funnelAmounts,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final stages = [
      {'name': 'Leads Capturados', 'key': 'lead', 'color': Colors.blue},
      {'name': 'Em Qualificação', 'key': 'qualification', 'color': Colors.indigo},
      {'name': 'Proposta Enviada', 'key': 'proposal', 'color': Colors.amber},
      {'name': 'Em Negociação', 'key': 'negotiation', 'color': Colors.deepOrange},
      {'name': 'Fechado Ganho', 'key': 'closed_won', 'color': Colors.green},
    ];

    final maxCount = funnelStages.values.fold(1, (prev, curr) => curr > prev ? curr : prev);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.filter_alt_outlined, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                'Funil de Vendas & Oportunidades',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...stages.map((st) {
            final count = funnelStages[st['key']] ?? 0;
            final amount = funnelAmounts[st['key']] ?? 0.0;
            final color = st['color'] as Color;
            final widthPercent = (count / maxCount).clamp(0.15, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        st['name'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                      Text(
                        '$count opport. (${currency.format(amount)})',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widthPercent,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
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
