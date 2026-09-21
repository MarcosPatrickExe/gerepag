import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/transactions_provider.dart';
import '../core/app_theme.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  double _employeeCount = 0; // Qtd de contratações
  double _avgSalary = 5000; // Salário médio
  double _revenueMultiplier = 1.0; 
  double _oneTimeInvestment = 0; 
  bool _loseTopClient = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR', decimalDigits: 0);
    final bool isWide = MediaQuery.of(context).size.width > 900;
    
    final additionalMonthlyExpense = _employeeCount * _avgSalary;

    final projection = provider.calculateWhatIfScenario(
      months: 6,
      additionalMonthlyExpense: additionalMonthlyExpense,
      revenueFactor: _revenueMultiplier,
      oneTimeInvestment: _oneTimeInvestment,
      includeLostTopClient: _loseTopClient,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Simulador de Cenários Estratégicos', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody)),
        iconTheme: const IconThemeData(color: AppTheme.textBody),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroCard(),
              const SizedBox(height: 32),
              
              if (isWide) 
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coluna de Controles
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('ESTRESSE DE RECEITA'),
                          const SizedBox(height: 16),
                          _buildCruelToggle(),
                          const SizedBox(height: 16),
                          _buildSliderCard(
                            'Desempenho de Vendas', 
                            _revenueMultiplier, 
                            0.5, 1.5, 
                            (val) => setState(() => _revenueMultiplier = val),
                            '${((_revenueMultiplier - 1) * 100).toStringAsFixed(0)}%',
                            Icons.trending_up_rounded,
                            _revenueMultiplier < 1 ? AppTheme.expense : AppTheme.primary,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle('EXPANSÃO DE EQUIPE'),
                          const SizedBox(height: 16),
                          _buildSliderCard(
                            'Novos Colaboradores', 
                            _employeeCount, 
                            0, 20, 
                            (val) => setState(() => _employeeCount = val.roundToDouble()),
                            _employeeCount.toInt().toString(),
                            Icons.people_alt_rounded,
                            AppTheme.secondary,
                          ),
                          const SizedBox(height: 16),
                          _buildSliderCard(
                            'Salário Médio', 
                            _avgSalary, 
                            2000, 25000, 
                            (val) => setState(() => _avgSalary = val),
                            currency.format(_avgSalary),
                            Icons.payments_rounded,
                            AppTheme.secondary,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle('INVESTIMENTOS FIXOS'),
                          const SizedBox(height: 16),
                          _buildSliderCard(
                            'Investimento em Ativos', 
                            _oneTimeInvestment, 
                            0, 150000, 
                            (val) => setState(() => _oneTimeInvestment = val),
                            currency.format(_oneTimeInvestment),
                            Icons.shopping_cart_checkout_rounded,
                            Colors.orangeAccent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    // Coluna de Resultados
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('PROJEÇÃO DE FLUXO (6 MESES)'),
                          const SizedBox(height: 16),
                          _buildProjectionChart(projection, currency, height: 400),
                          const SizedBox(height: 32),
                          _buildAnalysisResult(projection, currency),
                        ],
                      ),
                    ),
                  ],
                )
              else 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('ESTRESSE DE RECEITA'),
                    const SizedBox(height: 16),
                    _buildCruelToggle(),
                    const SizedBox(height: 16),
                    _buildSliderCard(
                      'Desempenho de Vendas', 
                      _revenueMultiplier, 
                      0.5, 1.5, 
                      (val) => setState(() => _revenueMultiplier = val),
                      '${((_revenueMultiplier - 1) * 100).toStringAsFixed(0)}%',
                      Icons.trending_up_rounded,
                      _revenueMultiplier < 1 ? AppTheme.expense : AppTheme.primary,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('EXPANSÃO DE EQUIPE'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSliderCard(
                            'Vagas', 
                            _employeeCount, 
                            0, 20, 
                            (val) => setState(() => _employeeCount = val.roundToDouble()),
                            _employeeCount.toInt().toString(),
                            Icons.people_alt_rounded,
                            AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSliderCard(
                            'Salário', 
                            _avgSalary, 
                            2000, 25000, 
                            (val) => setState(() => _avgSalary = val),
                            currency.format(_avgSalary),
                            Icons.payments_rounded,
                            AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('INVESTIMENTOS'),
                    const SizedBox(height: 16),
                    _buildSliderCard(
                      'Ativos/Software', 
                      _oneTimeInvestment, 
                      0, 150000, 
                      (val) => setState(() => _oneTimeInvestment = val),
                      currency.format(_oneTimeInvestment),
                      Icons.shopping_cart_checkout_rounded,
                      Colors.orangeAccent,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('PROJEÇÃO DE CAIXA'),
                    const SizedBox(height: 16),
                    _buildProjectionChart(projection, currency),
                    const SizedBox(height: 32),
                    _buildAnalysisResult(projection, currency),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title, 
      style: TextStyle(color: AppTheme.textBody.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)
    );
  }

  Widget _buildCruelToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: const Text('PERDER MAIOR CLIENTE', style: TextStyle(color: AppTheme.expense, fontSize: 10, fontWeight: FontWeight.bold))),
        const SizedBox(width: 4),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _loseTopClient, 
            onChanged: (val) => setState(() => _loseTopClient = val),
            activeColor: AppTheme.expense,
          ),
        ),
      ],
    );
  }


  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.secondary.withValues(alpha: 0.2), Colors.transparent]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.secondary, size: 32),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Visualize o futuro do seu negócio', style: TextStyle(color: AppTheme.textBody, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Ajuste as variáveis e veja como seu caixa se comporta nos próximos 6 meses.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard(String label, double value, double min, double max, Function(double) onChanged, String displayValue, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        label, 
                        style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(displayValue, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: color,
            inactiveColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionChart(Map<String, dynamic> data, NumberFormat currency, {double height = 300}) {
    final List<String> labels = data['labels'];
    final List<double> realValues = data['real'];
    final List<double> simValues = data['simulated'];

    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  if (val.toInt() >= 0 && val.toInt() < labels.length) {
                    return Text(labels[val.toInt()], style: const TextStyle(color: AppTheme.textMuted, fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: realValues.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: AppTheme.textMuted,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: simValues.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.primary.withValues(alpha: 0.3), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult(Map<String, dynamic> data, NumberFormat currency) {
    final List<double> simValues = data['simulated'];
    final finalValue = simValues.last;
    final bool isHealthy = finalValue > 0;
    final String? lostClient = data['topClientName'];

    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isHealthy ? AppTheme.income.withValues(alpha: 0.05) : AppTheme.expense.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isHealthy ? AppTheme.income.withValues(alpha: 0.2) : AppTheme.expense.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            isHealthy ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded, 
            color: isHealthy ? AppTheme.income : AppTheme.expense, 
            size: 40
          ),
          const SizedBox(height: 16),
          Text(
            isHealthy ? 'SAÚDE FINANCEIRA PREVISTA' : 'ALERTA DE INSOLVÊNCIA',
            style: TextStyle(color: isHealthy ? AppTheme.income : AppTheme.expense, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Com base nas variáveis aplicadas, seu saldo projetado para o fim do período é de ${currency.format(finalValue)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textBody, fontSize: 13, height: 1.5),
          ),
          if (lostClient != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_rounded, color: AppTheme.expense, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'Impacto: Perda do cliente "$lostClient"',
                      style: const TextStyle(color: AppTheme.expense, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          if (!isHealthy) 
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                '⚠️ PARE! O cenário simulado leva à quebra do caixa. Considere reduzir investimentos ou aumentar a eficiência de vendas.', 
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.expense.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold)
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

