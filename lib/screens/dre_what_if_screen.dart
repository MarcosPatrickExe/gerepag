import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';

class DreWhatIfScreen extends StatefulWidget {
  const DreWhatIfScreen({super.key});

  @override
  State<DreWhatIfScreen> createState() => _DreWhatIfScreenState();
}

class _DreWhatIfScreenState extends State<DreWhatIfScreen> {
  double _revenueMultiplier = 1.0; // 1.0 = 100% (original)
  double _cogsMultiplier = 1.0;
  double _opexMultiplier = 1.0;
  double _taxMultiplier = 1.0;

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.textBody.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSliderCard({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    required String displayValue,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                displayValue,
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
              ),
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

  Widget _buildComparativeRow(String label, String originalVal, String simulatedVal, bool isPositiveChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          Row(
            children: [
              Text(originalVal, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 8),
              Text(
                simulatedVal,
                style: TextStyle(
                  color: isPositiveChange ? Colors.greenAccent : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR', decimalDigits: 0);

    // 1. Valores Originais
    final double origRevenue = provider.monthIncome;
    final double origCOGS = provider.monthExpense * 0.35; // Estimativa de custo variável (35%)
    final double origOPEX = provider.monthExpense * 0.50; // Estimativa de despesas operacionais (50%)
    final double origTax = provider.omieTaxSummary;
    final double origNetProfit = origRevenue - (origCOGS + origOPEX + origTax);
    final double origEbitda = origRevenue - origOPEX;

    // 2. Valores Simulados
    final double simRevenue = origRevenue * _revenueMultiplier;
    final double simCOGS = origCOGS * _cogsMultiplier;
    final double simOPEX = origOPEX * _opexMultiplier;
    final double simTax = origTax * _taxMultiplier;
    final double simNetProfit = simRevenue - (simCOGS + simOPEX + simTax);
    final double simEbitda = simRevenue - simOPEX;

    final double profitDiff = simNetProfit - origNetProfit;
    final bool isHealthy = simNetProfit > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Simulador DRE "What-If" 📊', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBody),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.15), Colors.transparent]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.psychology, color: AppTheme.primary, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Simule o Impacto nos Resultados', style: TextStyle(color: AppTheme.textBody, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Movimente os controles de receita e custos para prever a saúde operacional líquida.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSectionTitle('VARIÁVEIS OPERACIONAIS'),
            const SizedBox(height: 16),
            
            _buildSliderCard(
              label: 'Performance Comercial (Receitas)',
              value: _revenueMultiplier,
              min: 0.5,
              max: 1.5,
              onChanged: (val) => setState(() => _revenueMultiplier = val),
              displayValue: '${((_revenueMultiplier - 1) * 100).toStringAsFixed(0)}%',
              icon: Icons.trending_up,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            
            _buildSliderCard(
              label: 'Custos de Mercadoria/Serviços (CMV)',
              value: _cogsMultiplier,
              min: 0.5,
              max: 1.5,
              onChanged: (val) => setState(() => _cogsMultiplier = val),
              displayValue: '${((_cogsMultiplier - 1) * 100).toStringAsFixed(0)}%',
              icon: Icons.inventory_2,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 16),
            
            _buildSliderCard(
              label: 'Despesas Gerais (Gastos Fixos)',
              value: _opexMultiplier,
              min: 0.5,
              max: 1.5,
              onChanged: (val) => setState(() => _opexMultiplier = val),
              displayValue: '${((_opexMultiplier - 1) * 100).toStringAsFixed(0)}%',
              icon: Icons.account_balance_wallet,
              color: AppTheme.secondary,
            ),
            const SizedBox(height: 16),
            
            _buildSliderCard(
              label: 'Encargos Tributários (Impostos)',
              value: _taxMultiplier,
              min: 0.5,
              max: 1.5,
              onChanged: (val) => setState(() => _taxMultiplier = val),
              displayValue: '${((_taxMultiplier - 1) * 100).toStringAsFixed(0)}%',
              icon: Icons.receipt_long,
              color: Colors.purpleAccent,
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('RESULTADOS COMPARATIVOS SIMULADOS'),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Column(
                children: [
                  _buildComparativeRow('Faturamento Operacional', currency.format(origRevenue), currency.format(simRevenue), simRevenue >= origRevenue),
                  _buildComparativeRow('Custo Variável (CMV)', currency.format(origCOGS), currency.format(simCOGS), simCOGS <= origCOGS),
                  _buildComparativeRow('Despesas Gerais (Opex)', currency.format(origOPEX), currency.format(simOPEX), simOPEX <= origOPEX),
                  _buildComparativeRow('Impostos / Retenções', currency.format(origTax), currency.format(simTax), simTax <= origTax),
                  
                  const Divider(height: 32, color: Colors.white10),
                  
                  _buildComparativeRow('EBITDA Projetado', currency.format(origEbitda), currency.format(simEbitda), simEbitda >= origEbitda),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isHealthy ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isHealthy ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isHealthy ? 'LUCRO OPERACIONAL LÍQUIDO' : 'PREJUÍZO PROJETADO',
                          style: TextStyle(color: isHealthy ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currency.format(simNetProfit),
                          style: TextStyle(color: isHealthy ? Colors.greenAccent : Colors.redAccent, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Diferença líquida: ${profitDiff >= 0 ? '+' : ''}${currency.format(profitDiff)} no período.',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _revenueMultiplier = 1.0;
                    _cogsMultiplier = 1.0;
                    _opexMultiplier = 1.0;
                    _taxMultiplier = 1.0;
                  });
                },
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: const Text('RESETAR CENÁRIO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
