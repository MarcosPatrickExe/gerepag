import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SpendingDonutChart extends StatefulWidget {
  const SpendingDonutChart({super.key});

  @override
  State<SpendingDonutChart> createState() => _SpendingDonutChartState();
}

class _SpendingDonutChartState extends State<SpendingDonutChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final expensesByCategory = provider.expenseByCategoryRank;

    if (expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalExpenses = expensesByCategory.values.fold(0.0, (sum, item) => sum + item);
    final List<Color> colors = [
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.greenAccent,
      Colors.cyanAccent,
      Colors.amberAccent,
      Colors.indigoAccent,
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Distribuição de Gastos',
                style: TextStyle(
                  color: AppTheme.textBody,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: _showingSections(expensesByCategory, colors, totalExpenses),
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: expensesByCategory.keys.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final color = colors[index % colors.length];
              final isSelected = touchedIndex == index;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: TextStyle(
                        color: AppTheme.textBody,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections(Map<String, double> data, List<Color> colors, double total) {
    return data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final val = entry.value.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 16.0 : 0.0;
      final radius = isTouched ? 60.0 : 50.0;
      final color = colors[index % colors.length];
      final percentage = (val / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: color,
        value: val,
        title: '$percentage%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: AppTheme.textBody,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        badgeWidget: isTouched ? _buildBadge(entry.value.key, color) : null,
        badgePositionPercentageOffset: .98,
      );
    }).toList();
  }

  Widget _buildBadge(String label, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.textBody,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)
        ],
      ),
      child: const Icon(Icons.touch_app, color: AppTheme.primary, size: 16),
    );
  }
}
