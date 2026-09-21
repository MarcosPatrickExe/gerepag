import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/omie_sales_analysis_model.dart';

class BiAbcCurveChart extends StatelessWidget {
  final List<OmieAbcItem> items;

  const BiAbcCurveChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.purple),
                  SizedBox(width: 8),
                  Text(
                    'Curva ABC',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _Badge(label: 'A (80%)', color: Colors.green),
                  _Badge(label: 'B (15%)', color: Colors.amber),
                  _Badge(label: 'C (5%)', color: Colors.blueGrey),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhum pedido de venda ou item faturado no Omie neste período.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.take(8).length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
              final item = items[index];
              Color color;
              switch (item.category) {
                case AbcCategory.a:
                  color = Colors.green;
                  break;
                case AbcCategory.b:
                  color = Colors.amber;
                  break;
                case AbcCategory.c:
                  color = Colors.blueGrey;
                  break;
              }

              return Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      item.category.name.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          'Acumulado: ${item.cumulativePercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currency.format(item.revenue),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
