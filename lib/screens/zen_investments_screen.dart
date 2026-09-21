import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/app_theme.dart';
import 'package:intl/intl.dart';

class ZenInvestmentsScreen extends StatefulWidget {
  const ZenInvestmentsScreen({super.key});

  @override
  State<ZenInvestmentsScreen> createState() => _ZenInvestmentsScreenState();
}

class _ZenInvestmentsScreenState extends State<ZenInvestmentsScreen> {
  double _monthlyInvest = 500;
  double _years = 10;
  final double _interestRate = 0.10; // 10% ao ano (média conservadora)

  double _calculateTotal() {
    // FV = P * [((1 + r)^n - 1) / r]
    double r = _interestRate / 12;
    double n = _years * 12;
    return _monthlyInvest * (math.pow(1 + r, n) - 1) / r;
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    // Calcular quão nítido o sonho está (0 a 1)
    double clarity = math.min(total / 1000000, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Fundo Visual Dinâmico (Sonho)
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1 * clarity),
                    AppTheme.secondary.withValues(alpha: 0.05 * clarity),
                    AppTheme.background,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome, 
                  size: 200, 
                  color: AppTheme.textBody.withValues(alpha: 0.05 + (0.1 * clarity)),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppTheme.textBody),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Modo Zen 🧘‍♂️',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textBody),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Card de Resultado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Text(
                        'SEU PATRIMÔNIO ESTIMADO',
                        style: TextStyle(color: AppTheme.textMuted, letterSpacing: 2, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currency.format(total),
                        style: const TextStyle(
                          color: AppTheme.textBody, 
                          fontSize: 48, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Em ${_years.toInt()} anos de disciplina',
                        style: const TextStyle(color: AppTheme.primary, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Controles (Sliders)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, -10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSlider(
                        label: 'Investimento Mensal',
                        value: _monthlyInvest,
                        min: 50,
                        max: 5000,
                        onChanged: (val) => setState(() => _monthlyInvest = val),
                        format: (v) => currency.format(v),
                      ),
                      const SizedBox(height: 24),
                      _buildSlider(
                        label: 'Prazo (Anos)',
                        value: _years,
                        min: 1,
                        max: 30,
                        onChanged: (val) => setState(() => _years = val),
                        format: (v) => '${v.toInt()} anos',
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Considerando rentabilidade média de 10% a.a.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    required String Function(double) format,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted)),
            Text(format(value), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: Colors.black.withValues(alpha: 0.05),
            thumbColor: AppTheme.primary,
            overlayColor: AppTheme.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
