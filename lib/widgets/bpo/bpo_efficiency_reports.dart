import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BpoEfficiencyReports extends StatelessWidget {
  const BpoEfficiencyReports({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RELATÓRIOS DE EFICIÊNCIA BPO 📈', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text('Métricas de redução de tempo operacional e ganho de produtividade da equipe', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('+16.4% Produtividade', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cards de Desempenho
          Row(
            children: [
              Expanded(child: _buildKPI('Tempo Médio por Nota', '1.2 min', 'Antes: 8.5 min (-85%)', Icons.timer_outlined, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildKPI('Notas Processadas/Dia', '420 docs', 'Média da equipe BPO', Icons.layers_outlined, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildKPI('Economia Mensal', 'R\$ 14.800', 'Horas reduzidas de digitação', Icons.savings_outlined, Colors.purple)),
            ],
          ),

          const SizedBox(height: 24),

          // Gráfico Comparativo: Análise de Tempo de Processamento (Time Processing Analysis)
          Container(
            height: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Análise de Tempo de Processamento por Documento (Minutos)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: [
                        _LegendDot(label: 'Processamento Manual', color: Colors.redAccent),
                        SizedBox(width: 12),
                        _LegendDot(label: 'Automação OCR IA', color: Colors.green),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text('Sem ${v.toInt() + 1}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))))),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        // Manual
                        LineChartBarData(
                          spots: const [FlSpot(0, 8.5), FlSpot(1, 8.2), FlSpot(2, 7.9), FlSpot(3, 8.0)],
                          color: Colors.redAccent,
                          barWidth: 3,
                          isCurved: true,
                        ),
                        // OCR IA
                        LineChartBarData(
                          spots: const [FlSpot(0, 4.0), FlSpot(1, 2.5), FlSpot(2, 1.5), FlSpot(3, 1.2)],
                          color: Colors.green,
                          barWidth: 3,
                          isCurved: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPI(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }
}
