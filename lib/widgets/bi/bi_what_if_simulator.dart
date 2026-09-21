import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/business_bi_provider.dart';
import '../../providers/transactions_provider.dart';

class BiWhatIfSimulator extends StatefulWidget {
  const BiWhatIfSimulator({super.key});

  @override
  State<BiWhatIfSimulator> createState() => _BiWhatIfSimulatorState();
}

class _BiWhatIfSimulatorState extends State<BiWhatIfSimulator> {
  double _revenueAdj = 0.0;  // -50% a +50%
  double _costAdj = 0.0;     // -50% a +50%
  double _expenseAdj = 0.0;  // -50% a +50%

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final biProvider = Provider.of<BusinessBiProvider>(context);
    final txProvider = Provider.of<TransactionsProvider>(context);

    final sim = biProvider.simulateResult(
      revenueAdj: _revenueAdj,
      costAdj: _costAdj,
      expenseAdj: _expenseAdj,
      txProvider: txProvider,
    );

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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.tune, color: Colors.teal),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Simulador Financeiro What-If',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _revenueAdj = 0.0;
                    _costAdj = 0.0;
                    _expenseAdj = 0.0;
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Resetar Simulação'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sliders
          _buildSlider(
            label: 'Ajuste de Receita Bruta',
            value: _revenueAdj,
            color: Colors.green,
            onChanged: (val) => setState(() => _revenueAdj = val),
          ),
          const SizedBox(height: 10),
          _buildSlider(
            label: 'Ajuste de Custos Variáveis',
            value: _costAdj,
            color: Colors.orange,
            onChanged: (val) => setState(() => _costAdj = val),
          ),
          const SizedBox(height: 10),
          _buildSlider(
            label: 'Ajuste de Despesas Operacionais',
            value: _expenseAdj,
            color: Colors.redAccent,
            onChanged: (val) => setState(() => _expenseAdj = val),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          // Resultados Simulados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ResultMetric(
                label: 'Receita Projetada',
                value: currency.format(sim['revenue']),
                color: Colors.green,
              ),
              _ResultMetric(
                label: 'EBITDA Simulado',
                value: currency.format(sim['ebitda']),
                color: (sim['ebitda'] ?? 0) >= 0 ? Colors.teal : Colors.red,
              ),
              _ResultMetric(
                label: 'Ponto de Equilíbrio',
                value: currency.format(sim['breakEven']),
                color: Colors.indigo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    final sign = value >= 0 ? '+' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            Text(
              '$sign${value.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        Slider(
          value: value,
          min: -50.0,
          max: 50.0,
          divisions: 100,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
        ),

      ],
    );
  }
}
