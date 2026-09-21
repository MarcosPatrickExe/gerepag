import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/transactions_provider.dart';
import '../core/app_theme.dart';
import '../services/ai_chat_service.dart';
import '../widgets/dashboard/premium_bi_header.dart';

class CrystalBallScreen extends StatefulWidget {
  final TransactionsProvider provider;

  const CrystalBallScreen({super.key, required this.provider});

  @override
  State<CrystalBallScreen> createState() => _CrystalBallScreenState();
}

class _CrystalBallScreenState extends State<CrystalBallScreen> {
  // Ajustes de simulação
  double _revenueAdjustmentPercent = 0.0;
  double _burnRateAdjustmentPercent = 0.0;
  double _manualCashInjection = 0.0;
  double _manualInjectionDay = 15.0;

  // IA
  final AiChatService _aiChat = AiChatService();
  String? _aiAdviceText;
  bool _isLoadingAiAdvice = false;

  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final baseForecast = provider.omieDailyForecast;
    final simulatedForecast = _getSimulatedForecast(baseForecast);

    // Encontrar primeiro buraco no caixa simulado
    final firstNegativeDay = simulatedForecast.firstWhere(
      (d) => (d['balance'] as double) < 0,
      orElse: () => {},
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumBIHeader(provider: provider),
          const SizedBox(height: 24),
          
          // 🧠 CARD HEADER CRYSTAL BALL
          _buildHeroHeader(),
          const SizedBox(height: 24),

          // 🚨 ALERTA PREDITIVO DE LIQUIDEZ (DINÂMICO)
          _buildPredictiveAlert(firstNegativeDay),
          const SizedBox(height: 24),

          // 📊 GRÁFICO INTERATIVO DE PROJEÇÃO
          _buildInteractiveChart(simulatedForecast),
          const SizedBox(height: 24),

          // 🎛️ PAINEL DE CONTROLE DE SIMULAÇÃO (WHAT-IF FORECAST)
          _buildSimulationPanel(),
          const SizedBox(height: 24),

          // 🤖 DIAGNÓSTICO DO CFO VIRTUAL (GLAUBER AI)
          _buildAiConsultationSection(provider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 1. Math engine para simular projeção
  List<Map<String, dynamic>> _getSimulatedForecast(List<Map<String, dynamic>> baseForecast) {
    if (baseForecast.isEmpty) return [];

    final List<Map<String, dynamic>> simulated = [];
    double cumulativeAdjustment = 0.0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final injectionDate = today.add(Duration(days: _manualInjectionDay.toInt()));

    final double avgDailyBurn = (widget.provider.monthExpense) / 30;

    for (int i = 0; i < baseForecast.length; i++) {
      final f = baseForecast[i];
      final DateTime date = f['date'] as DateTime;
      final double baseBalance = f['balance'] as double;
      final bool isReal = f['isReal'] as bool;

      double balance = baseBalance + cumulativeAdjustment;

      if (i > 0) {
        final double prevBalance = baseForecast[i - 1]['balance'] as double;
        final double baseDelta = baseBalance - prevBalance;

        double simulatedDelta = baseDelta;
        if (baseDelta > 0) {
          simulatedDelta = baseDelta * (1 + _revenueAdjustmentPercent / 100);
        } else if (baseDelta < 0) {
          simulatedDelta = baseDelta * (1 + _burnRateAdjustmentPercent / 100);
        } else {
          final double adjustedBurn = -avgDailyBurn * (1 + _burnRateAdjustmentPercent / 100);
          simulatedDelta = adjustedBurn;
        }

        final double diff = simulatedDelta - baseDelta;
        cumulativeAdjustment += diff;
        balance += diff;
      }

      if (date.year == injectionDate.year && date.month == injectionDate.month && date.day == injectionDate.day) {
        cumulativeAdjustment += _manualCashInjection;
        balance += _manualCashInjection;
      } else if (date.isAfter(injectionDate)) {
        balance += _manualCashInjection;
      }

      simulated.add({
        'date': date,
        'balance': balance,
        'isReal': isReal,
      });
    }

    return simulated;
  }

  // 2. Hero Header com gradiente futurista
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF818CF8), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'PREVISÃO E INTELIGÊNCIA ARTIFICIAL',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFC7D2FE),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'GerePag Crystal Ball 🔮',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simule receitas, reduções de custos e aportes na linha do tempo para prever o saldo futuro da sua empresa.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.online_prediction_rounded, size: 70, color: Color(0xFF818CF8))
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 0.9, end: 1.1, duration: 1800.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }

  // 3. Banner dinâmico de Alerta Preditivo
  Widget _buildPredictiveAlert(Map<String, dynamic> firstNegativeDay) {
    final bool isNegative = firstNegativeDay.isNotEmpty;

    if (isNegative) {
      final DateTime date = firstNegativeDay['date'] as DateTime;
      final double value = (firstNegativeDay['balance'] as double).abs();
      final String formattedDate = DateFormat('dd/MM/yyyy').format(date);

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALERTA: Risco de Caixa Negativo ⚠️',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF991B1B),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sua empresa projeta saldo negativo de ${currency.format(value)} no dia $formattedDate.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF7F1D1D),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💡 Tente simular um corte de despesas (OPEX) abaixo ou adicione um faturamento extra para ver a curva se recuperar.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB91C1C),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().shake(duration: 500.ms);
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saúde Financeira Saudável! ✅',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF065F46),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seu caixa simulado projeta saldo positivo durante todos os próximos 30 dias.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF047857),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  // 4. Gráfico LineChart elegante e interativo
  Widget _buildInteractiveChart(List<Map<String, dynamic>> forecast) {
    if (forecast.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('Sem dados preditivos disponíveis.')),
        ),
      );
    }

    final spots = forecast.indexed.map((e) => FlSpot(e.$1.toDouble(), e.$2['balance'] as double)).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            spreadRadius: 1,
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
              Text(
                'CURVA DE PROJEÇÃO DINÂMICA (30 DIAS)',
                style: GoogleFonts.outfit(
                  color: AppTheme.textBody,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.insights, color: Colors.blueAccent, size: 18),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => const Color(0xFF1E293B),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = forecast[spot.x.toInt()]['date'] as DateTime;
                        final formattedDate = DateFormat('dd/MM').format(date);
                        return LineTooltipItem(
                          '$formattedDate\n${currency.format(spot.y)}',
                          GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (val, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            currency.format(val).replaceAll(RegExp(r'\s|R\$'), ''),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 8),
                            textAlign: TextAlign.end,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 6,
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() >= forecast.length) return const SizedBox.shrink();
                        final date = forecast[val.toInt()]['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('dd/MM').format(date),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                    ),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2563EB).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
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

  // 5. Painel de controles de simulação financeira
  Widget _buildSimulationPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎛️ SIMULADOR DE CENÁRIOS RÁPIDO',
            style: GoogleFonts.outfit(
              color: AppTheme.textBody,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          
          // Slider 1: Receitas
          _buildSlider(
            label: 'Ajuste de Receitas/Vendas (%)',
            value: _revenueAdjustmentPercent,
            min: -50,
            max: 50,
            displayVal: '${_revenueAdjustmentPercent >= 0 ? '+' : ''}${_revenueAdjustmentPercent.toInt()}%',
            color: const Color(0xFF10B981),
            onChanged: (v) => setState(() => _revenueAdjustmentPercent = v),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // Slider 2: Despesas
          _buildSlider(
            label: 'Ajuste de Despesas/Corte Opex (%)',
            value: _burnRateAdjustmentPercent,
            min: -50,
            max: 50,
            displayVal: '${_burnRateAdjustmentPercent >= 0 ? '+' : ''}${_burnRateAdjustmentPercent.toInt()}%',
            color: const Color(0xFFEF4444),
            onChanged: (v) => setState(() => _burnRateAdjustmentPercent = v),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // Slider 3: Entrada Extra de Caixa (Aporte)
          _buildSlider(
            label: 'Aporte Extra de Caixa Pontual',
            value: _manualCashInjection,
            min: 0,
            max: 100000,
            displayVal: currency.format(_manualCashInjection),
            color: const Color(0xFF6366F1),
            onChanged: (v) => setState(() => _manualCashInjection = v),
          ),

          if (_manualCashInjection > 0) ...[
            const SizedBox(height: 12),
            _buildSlider(
              label: 'Dia do Aporte (daqui a quantos dias)',
              value: _manualInjectionDay,
              min: 1,
              max: 30,
              displayVal: 'Dia ${_manualInjectionDay.toInt()}',
              color: const Color(0xFF818CF8),
              onChanged: (v) => setState(() => _manualInjectionDay = v),
            ),
          ],
        ],
      ),
    );
  }

  // Widget utilitário de Slider customizado
  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayVal,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textBody)),
            Text(
              displayVal,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: color,
          inactiveColor: const Color(0xFFE2E8F0),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // 6. Sessão de consulta com Glauber AI
  Widget _buildAiConsultationSection(TransactionsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DIAGNÓSTICO DO FLUXO DE CAIXA',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textBody,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Assessoria automatizada com Glauber AI', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoadingAiAdvice)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent),
                    SizedBox(height: 16),
                    Text(
                      'Glauber está analisando o ERP e as simulações...',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    )
                  ],
                ),
              ),
            )
          else if (_aiAdviceText != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                _aiAdviceText!,
                style: GoogleFonts.inter(
                  color: AppTheme.textBody,
                  fontSize: 12.5,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _fetchAiAdvice(provider),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('REFAZER DIAGNÓSTICO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: Colors.blueAccent),
                  foregroundColor: Colors.blueAccent,
                ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _fetchAiAdvice(provider),
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text('GERAR ANÁLISE GLAUBER AI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Executa chamada da IA
  Future<void> _fetchAiAdvice(TransactionsProvider provider) async {
    setState(() {
      _isLoadingAiAdvice = true;
      _aiAdviceText = null;
    });

    try {
      final advice = await _aiChat.getCashFlowForecastAdvice(provider);
      if (mounted) {
        setState(() {
          _aiAdviceText = advice;
          _isLoadingAiAdvice = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiAdviceText = 'Erro ao processar diagnóstico: $e';
          _isLoadingAiAdvice = false;
        });
      }
    }
  }
}
