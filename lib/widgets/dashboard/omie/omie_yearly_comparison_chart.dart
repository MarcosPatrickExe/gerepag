import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';

class OmieYearlyComparisonChart extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieYearlyComparisonChart({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final years = provider.omieYearlyComparison;
    if (years[2026] == null || years[2026]!.isEmpty) return const SizedBox.shrink();

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final List<FlSpot> spots2025 = months.indexed.map((e) => FlSpot(e.$1.toDouble(), (years[2025] ?? {})[e.$2] ?? 0)).toList();
    final List<FlSpot> spots2026 = months.indexed.map((e) => FlSpot(e.$1.toDouble(), (years[2026] ?? {})[e.$2] ?? 0)).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CRESCIMENTO ANUAL (2025 vs 2026) 📈', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) => LineTooltipItem(
                        NumberFormat.simpleCurrency(locale: 'pt_BR').format(spot.y), 
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      )).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) => Text(months[v.toInt() % 12], style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(spots: spots2025, isCurved: true, color: Colors.white.withValues(alpha: 0.2), barWidth: 2, dotData: const FlDotData(show: false)),
                  LineChartBarData(spots: spots2026, isCurved: true, color: Colors.white, barWidth: 4, belowBarData: BarAreaData(show: true, color: Colors.white.withValues(alpha: 0.1))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('2025', Colors.white24),
              const SizedBox(width: 24),
              _buildLegendItem('2026', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }
}
