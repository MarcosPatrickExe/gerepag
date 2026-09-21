import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/business_bi_provider.dart';

class BiAgingTable extends StatelessWidget {
  final String title;
  final AgingBucket bucket;
  final bool isReceivables;

  const BiAgingTable({
    super.key,
    required this.title,
    required this.bucket,
    required this.isReceivables,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final total = bucket.total > 0 ? bucket.total : 1.0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isReceivables ? Icons.arrow_circle_down : Icons.arrow_circle_up,
                      color: isReceivables ? Colors.green : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total: ${currency.format(bucket.total)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRow('A vencer / Até 30 dias', bucket.current, (bucket.current / total) * 100, Colors.blue),
          const SizedBox(height: 10),
          _buildRow('De 31 a 60 dias', bucket.days31to60, (bucket.days31to60 / total) * 100, Colors.amber),
          const SizedBox(height: 10),
          _buildRow('De 61 a 90 dias', bucket.days61to90, (bucket.days61to90 / total) * 100, Colors.orange),
          const SizedBox(height: 10),
          _buildRow('Acima de 90 dias (Crítico)', bucket.days90Plus, (bucket.days90Plus / total) * 100, Colors.red),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double amount, double percentage, Color color) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            Text(
              '${currency.format(amount)} (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class BiAgingDonutChart extends StatelessWidget {
  final String title;
  final AgingBucket bucket;
  final bool isReceivables;

  const BiAgingDonutChart({
    super.key,
    required this.title,
    required this.bucket,
    required this.isReceivables,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final total = bucket.total > 0 ? bucket.total : 1.0;

    final double pCurrent = (bucket.current / total) * 100;
    final double p31to60 = (bucket.days31to60 / total) * 100;
    final double p61Plus = ((bucket.days61to90 + bucket.days90Plus) / total) * 100;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.0),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 36,
                        startDegreeOffset: 270,
                        sections: [
                          PieChartSectionData(
                            color: Colors.redAccent,
                            value: p61Plus > 0 ? p61Plus : 0.1,
                            radius: 14,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: Colors.amber,
                            value: p31to60 > 0 ? p31to60 : 0.1,
                            radius: 14,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: isReceivables ? const Color(0xFF10B981) : const Color(0xFF06B6D4),
                            value: pCurrent > 0 ? pCurrent : 99.8,
                            radius: 14,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currency.format(bucket.total),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Vencido (${p61Plus.toStringAsFixed(1)}%)', currency.format(bucket.days61to90 + bucket.days90Plus), Colors.redAccent),
                    const SizedBox(height: 8),
                    _buildLegendItem('A vencer (${p31to60.toStringAsFixed(1)}%)', currency.format(bucket.days31to60), Colors.amber),
                    const SizedBox(height: 8),
                    _buildLegendItem('Recebido/Pago (${pCurrent.toStringAsFixed(1)}%)', currency.format(bucket.current), isReceivables ? const Color(0xFF10B981) : const Color(0xFF06B6D4)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
