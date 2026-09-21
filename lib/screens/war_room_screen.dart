import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/transactions_provider.dart';
import '../core/app_theme.dart';

class WarRoomScreen extends StatefulWidget {
  const WarRoomScreen({super.key});

  @override
  State<WarRoomScreen> createState() => _WarRoomScreenState();
}

class _WarRoomScreenState extends State<WarRoomScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    // Métricas Cruciais
    final saldo = provider.totalBalance;
    final faturamento = provider.monthIncome;
    final despesa = provider.monthExpense;
    final inadimplencia = provider.omieOverdue;
    final mrr = provider.omieMRRStats['MRR'] ?? 0.0;
    
    // Status de Risco
    final bool isLiquidityRisk = saldo < despesa * 0.5;
    final bool isDefaultRisk = inadimplencia > faturamento * 0.2;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Tech
          _buildTechBackground(),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 1.2,
                      children: [
                        _buildWarCard(
                          'LIQUIDEZ TOTAL', 
                          currency.format(saldo), 
                          isLiquidityRisk ? AppTheme.expense : AppTheme.primary,
                          Icons.account_balance_wallet,
                          isCritical: isLiquidityRisk,
                          subtitle: 'Saldo Consolidado',
                        ),
                        _buildWarCard(
                          'RECEITA MÊS', 
                          currency.format(faturamento), 
                          AppTheme.income,
                          Icons.trending_up,
                          subtitle: 'Faturamento Bruto',
                        ),
                        _buildWarCard(
                          'INADIMPLÊNCIA', 
                          currency.format(inadimplencia), 
                          isDefaultRisk ? AppTheme.expense : Colors.orangeAccent,
                          Icons.warning_amber_rounded,
                          isCritical: isDefaultRisk,
                          subtitle: 'Títulos em Atraso',
                        ),
                        _buildWarCard(
                          'PONTUALIDADE (MRR)', 
                          currency.format(mrr), 
                          AppTheme.secondary,
                          Icons.repeat,
                          subtitle: 'Receita Recorrente',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildBottomMonitor(provider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: [
            AppTheme.primary.withValues(alpha: 0.05),
            AppTheme.background,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Grid Lines
          CustomPaint(
            painter: GridPainter(),
            size: Size.infinite,
          ),
          // Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.02),
              ),
            ).animate(onPlay: (c) => c.repeat()).fade(duration: 3.seconds, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms),
                const SizedBox(width: 12),
                Text(
                  'WAR ROOM: MONITORAMENTO EM TEMPO REAL',
                  style: GoogleFonts.orbitron(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'EXECUTIVO DE ALTO NÍVEL',
              style: GoogleFonts.inter(color: AppTheme.textBody, fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildWarCard(String label, String value, Color color, IconData icon, {bool isCritical = false, String? subtitle}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isCritical ? color.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: isCritical ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Scanner Line effect
            if (isCritical)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, color.withValues(alpha: 0.05), Colors.transparent],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).moveY(begin: -200, end: 200, duration: 2.seconds),
              ),
              
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      if (isCritical)
                        const Text('ALERTA', style: TextStyle(color: AppTheme.expense, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)).animate(onPlay: (c) => c.repeat()).fade(duration: 500.ms),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: GoogleFonts.jetBrainsMono(color: AppTheme.textBody, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 9)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMonitor(TransactionsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStat('OS ATIVAS', provider.omieOS.length.toString(), Colors.blueAccent),
          ),
          Container(width: 1, height: 40, color: AppTheme.textMuted),
          Expanded(
            child: _buildMiniStat('PEDIDOS', provider.omieOrders.length.toString(), Colors.greenAccent),
          ),
          Container(width: 1, height: 40, color: AppTheme.textMuted),
          Expanded(
            child: _buildMiniStat('COBRANÇAS', provider.omieUpcomingPayments.length.toString(), Colors.orangeAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.jetBrainsMono(color: AppTheme.textBody, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
