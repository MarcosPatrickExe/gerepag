import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import '../models/transaction_model.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class FuturePlanningScreen extends StatefulWidget {
  const FuturePlanningScreen({super.key});

  @override
  State<FuturePlanningScreen> createState() => _FuturePlanningScreenState();
}

class _FuturePlanningScreenState extends State<FuturePlanningScreen> {
  double _monthlySavings = 500;
  double _years = 10;
  double _interestRate = 12; // 12% ao ano
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final totalBalance = provider.transactions.fold(0.0, (sum, t) => t.type == TransactionType.income ? sum + t.amount : sum - t.amount);
    
    final points = _calculateProjection(totalBalance);
    final finalAmount = points.last.y;

    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora de Futuro'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Onde você quer estar?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Projete o crescimento do seu patrimônio com juros compostos.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 32),
            
            _buildResultCard(finalAmount),
            
            const SizedBox(height: 32),
            _buildChart(points),
            
            const SizedBox(height: 32),
            _buildSlider(
              label: 'Poupança Mensal',
              value: _monthlySavings,
              min: 0,
              max: 10000,
              displayValue: currency.format(_monthlySavings),
              onChanged: (v) => setState(() => _monthlySavings = v),
            ),
            _buildSlider(
              label: 'Prazo (Anos)',
              value: _years,
              min: 1,
              max: 40,
              displayValue: '${_years.toInt()} anos',
              onChanged: (v) => setState(() => _years = v),
            ),
            _buildSlider(
              label: 'Retorno Anual (%)',
              value: _interestRate,
              min: 1,
              max: 20,
              displayValue: '${_interestRate.toInt()}% a.a.',
              onChanged: (v) => setState(() => _interestRate = v),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _calculateProjection(double initialBalance) {
    List<FlSpot> spots = [];
    double current = initialBalance;
    double monthlyRate = math.pow(1 + (_interestRate / 100), 1 / 12) - 1;

    spots.add(FlSpot(0, current));

    for (int month = 1; month <= _years * 12; month++) {
      current = (current * (1 + monthlyRate)) + _monthlySavings;
      if (month % 12 == 0) {
        spots.add(FlSpot((month / 12).toDouble(), current));
      }
    }
    return spots;
  }

  Widget _buildResultCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Text('PATRIMÔNIO ESTIMADO', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(currency.format(amount), style: const TextStyle(color: AppTheme.textBody, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChart(List<FlSpot> spots) {
    return Container(
      height: 200,
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.only(top: 24, bottom: 12, right: 24, left: 12),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppTheme.primary.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({required String label, required double value, required double min, required double max, required String displayValue, required Function(double) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(displayValue, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
