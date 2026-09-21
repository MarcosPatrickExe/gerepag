import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';
import '../../../screens/omie_billing_screen.dart';

class OmieKPIs extends StatelessWidget {
  final TransactionsProvider provider;
  final bool isDesktop;

  const OmieKPIs({super.key, required this.provider, required this.isDesktop});

  Widget _buildBillingButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OmieBillingScreen()),
        ),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_card, color: AppTheme.primary, size: 14),
              SizedBox(width: 8),
              Text(
                'NOVA COBRANÇA',
                style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = provider.omieSummary;
    final double aReceber = double.tryParse(summary?['contaReceber']?['vTotal']?.toString() ?? '0.0') ?? 0.0;
    final double aPagar = double.tryParse(summary?['contaPagar']?['vTotal']?.toString() ?? '0.0') ?? 0.0;
    final double saldo = double.tryParse(summary?['contaCorrente']?['vTotal']?.toString() ?? '0.0') ?? 0.0;
    final double impostos = provider.omieTaxSummary;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('INTELIGÊNCIA FINANCEIRA OMIE 🏦', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                Row(
                  children: [
                    _buildBillingButton(context),
                    const SizedBox(width: 12),
                    _buildSyncButton(provider),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildKPICard(
                  provider.isConsolidatedMode ? 'SALDO TOTAL DO GRUPO' : 'BANCÁRIO DISPONÍVEL', 
                  currency.format(saldo), 
                  Colors.blueAccent, 
                  Icons.account_balance
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildKPICard(
                  provider.isConsolidatedMode ? 'FATURAMENTO CONSOLIDADO' : 'A RECEBER (OMIE)', 
                  currency.format(aReceber), 
                  Colors.greenAccent, 
                  Icons.trending_up
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildKPICard(
                  'A PAGAR ACUMULADO', 
                  currency.format(aPagar), 
                  Colors.orangeAccent, 
                  Icons.trending_down
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildKPICard(
                  'IMPOSTOS DO GRUPO', 
                  currency.format(impostos), 
                  Colors.purpleAccent, 
                  Icons.receipt_long
                )),
              ],
            ),
            const SizedBox(height: 16),
            _buildOmieFlashCashBanner(provider),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FLUXO DE CAIXA (OMIE) 🏦', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OmieBillingScreen()),
                    ),
                    icon: const Icon(Icons.add_card, color: Colors.white, size: 18),
                  ),
                  IconButton(onPressed: () => provider.refreshOmieData(fullSync: true), icon: const Icon(Icons.refresh, color: Colors.white, size: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildBusinessMetric('A RECEBER', currency.format(aReceber), Colors.greenAccent)),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(child: _buildBusinessMetric('A PAGAR', currency.format(aPagar), Colors.orangeAccent)),
            ],
          ),
          const Divider(height: 40, color: Colors.white24),
          const Text('SALDO DISPONÍVEL (BANCÁRIO)', style: TextStyle(color: Colors.white70, fontSize: 10)),
          Text(currency.format(saldo), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSyncButton(TransactionsProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => provider.refreshOmieData(fullSync: true),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.isSyncing)
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
              else
                const Icon(Icons.sync, color: Colors.blueAccent, size: 14),
              const SizedBox(width: 8),
              Text(
                provider.isSyncing ? 'SINCRONIZANDO...' : 'SINCRONIZAR AGORA',
                style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOmieFlashCashBanner(TransactionsProvider provider) {
    final saldo = double.tryParse(provider.omieSummary?['contaCorrente']?['vTotal']?.toString() ?? '0.0') ?? 0.0;
    final aPagarHoje = provider.omieBillsDueToday;
    final alert = saldo < aPagarHoje;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert ? Colors.redAccent.withValues(alpha: 0.1) : Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alert ? Colors.redAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(alert ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: alert ? Colors.redAccent : Colors.greenAccent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert 
                ? 'ATENÇÃO: Saldo insuficiente para honrar compromissos de hoje (R\$ ${aPagarHoje.toStringAsFixed(2)}).' 
                : 'EXCELENTE: Saldo cobre todos os compromissos previstos para hoje.',
              style: TextStyle(color: alert ? Colors.redAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
