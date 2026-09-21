import 'package:flutter/material.dart';
import '../../models/omie_sales_analysis_model.dart';

class BiRfvMatrixChart extends StatelessWidget {
  final List<OmieRfvClient> clients;

  const BiRfvMatrixChart({super.key, required this.clients});

  @override
  Widget build(BuildContext context) {
    final list = clients;

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
              Icon(Icons.military_tech_outlined, color: Colors.amber),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Segmentação RFV (Recência, Frequência & Valor)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Sem histórico de recebíveis por cliente no Omie neste período.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Recência', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Freq.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Segmento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...list.map((c) {
                Color color;
                String badgeText;
                switch (c.segment) {
                  case RfvSegment.gold:
                    color = Colors.amber;
                    badgeText = '🥇 VIP Gold';
                    break;
                  case RfvSegment.silver:
                    color = Colors.blueGrey;
                    badgeText = '🥈 Silver';
                    break;
                  case RfvSegment.bronze:
                    color = Colors.brown;
                    badgeText = '🥉 Bronze';
                    break;
                }

                return TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8), child: Text(c.clientName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${c.daysSinceLastPurchase} dias', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${c.purchaseFrequency}x/ano', style: const TextStyle(fontSize: 12))),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text(badgeText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
