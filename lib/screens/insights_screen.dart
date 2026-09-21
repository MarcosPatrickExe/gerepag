import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import '../models/transaction_model.dart';
import '../services/anomaly_service.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'ai_chat_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final categoricalData = provider.categoricalExpenses;
    final balanceHistory = provider.dailyBalanceHistory;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    final double totalExpenses = categoricalData.values.fold(0.0, (sum, val) => sum + val);

    // Scanner de Anomalias (Sentinela Guard) nos lançamentos recentes
    final List<Map<String, dynamic>> suspectedTransactions = [];
    final allPersonal = provider.transactions;
    if (allPersonal.length >= 10) {
      for (var t in allPersonal.take(20)) {
        final checkResult = AnomalyService.check(t, allPersonal);
        if (checkResult.isSuspect) {
          suspectedTransactions.add({
            'transaction': t,
            'reason': checkResult.reason,
            'score': checkResult.score,
          });
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Gradient e Dot Grid
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF020617)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                painter: _DotGridPainter(),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Premium AppBar
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                    title: Text(
                      'INSIGHTS FINANCEIROS',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF2563EB).withValues(alpha: 0.15), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),

                // Conteúdo
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Health Score Ring
                      Text(
                        'PONTUAÇÃO DE SAÚDE FINANCEIRA 🏆',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFinancialHealthCard(provider, currency),

                      const SizedBox(height: 36),

                      // 2. Evolução de Saldo
                      Text(
                        'EVOLUÇÃO DO SALDO (7 DIAS) 📈',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLineChartCard(balanceHistory),
                      
                      const SizedBox(height: 36),

                      // 3. Sentinela Guard (Alerta de Anomalias)
                      Text(
                        'SENTINELA GUARD (SCAN DE ANOMALIAS) 🛡️',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSentinelaGuardCard(suspectedTransactions, currency),

                      const SizedBox(height: 36),

                      // 4. Distribuição de Despesas
                      Text(
                        'DISTRIBUIÇÃO DE DESPESAS 🍕',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPieChartCard(categoricalData, totalExpenses, currency),

                      const SizedBox(height: 36),

                      // 5. Glauber AI Proactive Advisor Card
                      Text(
                        'CONSELHO DO GLAUBER 🤖',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlauberAdvisorCard(provider, totalExpenses, currency),

                      const SizedBox(height: 48),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthCard(TransactionsProvider provider, NumberFormat currency) {
    double income = 0;
    double expense = 0;
    
    if (provider.isBusinessMode) {
      income = provider.monthIncome;
      expense = provider.monthExpense;
    } else {
      income = provider.transactions.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
      expense = provider.transactions.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
    }
    
    double marginPercent = income > 0 ? ((income - expense) / income) * 100 : 0.0;
    
    double rawScore = 50.0;
    if (income > 0) {
      if (marginPercent > 30) {
        rawScore = 80 + (marginPercent - 30) * 0.28;
      } else if (marginPercent > 0) {
        rawScore = 60 + marginPercent * 0.66;
      } else {
        rawScore = 30 + (100 + marginPercent).clamp(0.0, 30.0);
      }
    } else if (expense > 0) {
      rawScore = 25.0;
    }
    
    final double finalScore = rawScore.clamp(10.0, 100.0);
    
    Color scoreColor = const Color(0xFFEF4444);
    String scoreStatus = 'CRÍTICO';
    IconData scoreIcon = Icons.error_outline_rounded;
    
    if (finalScore >= 80) {
      scoreColor = const Color(0xFF10B981);
      scoreStatus = 'EXCELENTE';
      scoreIcon = Icons.stars_rounded;
    } else if (finalScore >= 60) {
      scoreColor = const Color(0xFF3B82F6);
      scoreStatus = 'SAUDÁVEL';
      scoreIcon = Icons.check_circle_outline_rounded;
    } else if (finalScore >= 40) {
      scoreColor = const Color(0xFFF59E0B);
      scoreStatus = 'ATENÇÃO';
      scoreIcon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: -5),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _ScoreGaugePainter(score: finalScore, color: scoreColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    finalScore.toStringAsFixed(0),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '/100',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(scoreIcon, color: scoreColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        scoreStatus,
                        style: GoogleFonts.inter(
                          color: scoreColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  provider.isBusinessMode ? 'Saúde da Empresa' : 'Saúde Pessoal',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  marginPercent >= 0 
                      ? 'Sua margem de sobra está em ${marginPercent.toStringAsFixed(0)}% este mês.'
                      : 'Suas despesas superaram suas receitas em ${marginPercent.abs().toStringAsFixed(0)}% este mês.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartCard(List<MapEntry<DateTime, double>> data) {
    if (data.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Text('Nenhum dado de saldo para os últimos 7 dias.', style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: -5),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF1E293B).withValues(alpha: 0.9),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
                  return LineTooltipItem(
                    currency.format(spot.y),
                    GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  if (data.length > 5 && idx % 2 != 0) return const SizedBox();
                  
                  final date = data[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
              isCurved: true,
              barWidth: 4,
              isStrokeCapRound: true,
              color: const Color(0xFF3B82F6),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF3B82F6),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    const Color(0xFF3B82F6).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentinelaGuardCard(List<Map<String, dynamic>> suspectedList, NumberFormat currency) {
    final bool hasAnomalies = suspectedList.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: hasAnomalies 
              ? const Color(0xFFEF4444).withValues(alpha: 0.15) 
              : const Color(0xFF10B981).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: -5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Sentinela
          Row(
            children: [
              Icon(
                hasAnomalies ? Icons.shield_rounded : Icons.verified_user_rounded,
                color: hasAnomalies ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sentinela Guard Scanner',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasAnomalies 
                      ? const Color(0xFFEF4444).withValues(alpha: 0.1) 
                      : const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasAnomalies ? 'ALERTA' : 'NORMAL',
                  style: GoogleFonts.inter(
                    color: hasAnomalies ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (!hasAnomalies)
            Text(
              'Nenhum desvio estatístico ou anomalia foi detectado nos lançamentos analisados. Sua atividade de gastos recente segue o padrão histórico habitual.',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
                height: 1.5,
              ),
            )
          else ...[
            Text(
              'Foram detectadas transações com comportamento atípico estatisticamente. Verifique as atividades abaixo:',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: suspectedList.map((item) {
                final TransactionModel t = item['transaction'];
                final String reason = item['reason'];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.description.isEmpty ? 'Transação Sem Título' : t.description,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reason,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currency.format(t.amount),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd/MM').format(t.date),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPieChartCard(Map<String, double> data, double totalExpenses, NumberFormat currency) {
    if (data.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Text('Nenhuma despesa registrada ainda.', style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
    ];

    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: -5),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: sortedEntries.asMap().entries.map((e) {
                  final index = e.key;
                  final entry = e.value;
                  final isTouched = index == _touchedIndex;
                  final radius = isTouched ? 28.0 : 20.0;
                  final percentage = totalExpenses > 0 ? (entry.value / totalExpenses) * 100 : 0.0;

                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: entry.value,
                    title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
                    radius: radius,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Despesas Totais',
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  currency.format(totalExpenses),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          Column(
            children: sortedEntries.asMap().entries.map((e) {
              final index = e.key;
              final entry = e.value;
              final color = colors[index % colors.length];
              final percentage = totalExpenses > 0 ? (entry.value / totalExpenses) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          currency.format(entry.value),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage.clamp(0.0, 1.0),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildGlauberAdvisorCard(TransactionsProvider provider, double totalExpenses, NumberFormat currency) {
    String adviceText = '';
    String suggestionQuery = '';
    
    if (provider.isBusinessMode) {
      final double profit = provider.monthIncome - provider.monthExpense;
      if (profit > 0) {
        adviceText = 'Parabéns! Sua empresa está com saldo operacional positivo de ${currency.format(profit)} este mês. Recomendo analisar se vale antecipar algum pagamento para ganhar desconto.';
        suggestionQuery = 'Como posso investir a sobra de caixa da minha empresa?';
      } else {
        adviceText = 'Atenção: O saldo da sua empresa ficou negativo em ${currency.format(profit.abs())} este mês. Vamos analisar quais faturas estão vencidas ou clientes inadimplentes?';
        suggestionQuery = 'Como posso recuperar o caixa da minha empresa que está negativo?';
      }
    } else {
      final double balance = provider.totalBalance;
      if (balance > 1000) {
        adviceText = 'Muito bom! Seu saldo pessoal está confortável. Que tal definir um objetivo de investimento (caixinha) para render esses recursos parados na conta?';
        suggestionQuery = 'Qual a melhor caixinha para render meu dinheiro de reserva?';
      } else {
        adviceText = 'Seu saldo pessoal está um pouco apertado. Notei que suas maiores despesas estão concentradas nas categorias listadas acima. Vamos traçar um plano de redução?';
        suggestionQuery = 'Me dê um plano para cortar gastos no orçamento pessoal.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E3A8A).withValues(alpha: 0.15), const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.05), blurRadius: 30, spreadRadius: -5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Colors.blueAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consultor Glauber',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'Análise em tempo real',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            adviceText,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AiChatScreen(initialMessage: suggestionQuery),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              label: const Text('DISCUTIR COM GLAUBER POR IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreGaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _ScoreGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.8,
      math.pi * 1.4,
      false,
      bgPaint,
    );
    
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.8,
      math.pi * 1.4 * (score / 100),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    const double spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
