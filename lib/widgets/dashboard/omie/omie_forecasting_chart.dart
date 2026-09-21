import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';

class OmieForecastingChart extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieForecastingChart({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final forecast = provider.omieCashFlowProjection;
    if (forecast.isEmpty) return const SizedBox.shrink();

    final List<FlSpot> spots = forecast.indexed.map((e) => FlSpot(e.$1.toDouble(), (e.$2['value'] ?? 0.0).toDouble())).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PROJEÇÃO DE CAIXA PREDITIVA (30 DIAS) 🔮', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('IA & DATAS REAIS', style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.textMuted.withValues(alpha: 0.1), strokeWidth: 1)),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) => LineTooltipItem(
                        '${DateFormat('dd/MM').format(forecast[spot.x.toInt()]['date'] ?? DateTime.now())}\n${NumberFormat.simpleCurrency(locale: 'pt_BR').format(spot.y)}', 
                        const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 11)
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
                      interval: 5,
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() >= forecast.length) return const SizedBox.shrink();
                        return Text(forecast[val.toInt()]['label'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.cyanAccent]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent.withValues(alpha: 0.1), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
