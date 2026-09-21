import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';
import '../dre_tree_view.dart';
import 'premium_bi_header.dart';

class DREMatrixDashboard extends StatelessWidget {
  final TransactionsProvider provider;

  const DREMatrixDashboard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PremiumBIHeader(provider: provider),
        const SizedBox(height: 24),
        _buildDRETreeView(provider),
        const SizedBox(height: 24),
        _buildDREMatrixTable(provider),
        const SizedBox(height: 24),
        _buildDREFlowCards(provider),
        const SizedBox(height: 24),
        _buildWaterfallProfitChart(provider),
      ],
    );
  }

  Widget _buildDRETreeView(TransactionsProvider provider) {
    final tree = provider.omieDreTree;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ESTRUTURA DRE (NÍVEL 1, 2, 3)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Visão hierárquica por categorias Omie', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
              Icon(Icons.account_tree_outlined, color: Colors.white.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 24),
          // We need to pass white text theme to TreeView or handle it inside
          Theme(
            data: ThemeData.dark().copyWith(
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.white),
              ),
            ),
            child: DreTreeView(nodes: tree),
          ),
        ],
      ),
    );
  }

  Widget _buildDREMatrixTable(TransactionsProvider provider) {
    final matrix = provider.omieDREMatrix;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR', decimalDigits: 0);
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)], // slightly darker blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DRE Matricial por Categoria e Mês', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Theme(
              data: ThemeData.dark(),
              child: DataTable(
                columnSpacing: 20,
                horizontalMargin: 0,
                columns: [
                  const DataColumn(label: Text('Receita/Despesa', style: TextStyle(color: Colors.white, fontSize: 10))),
                  ...months.map((m) => DataColumn(label: Text(m, style: const TextStyle(color: Colors.white70, fontSize: 10)))),
                ],
                rows: [
                  DataRow(cells: [
                    const DataCell(Text('RECEITAS TOTAL', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 10))),
                    ...List.generate(12, (_) => const DataCell(SizedBox.shrink())),
                  ]),
                  ...matrix['Receita']!.entries.map((e) => DataRow(cells: [
                    DataCell(Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 9))),
                    ...e.value.map((v) => DataCell(Text(currency.format(v), style: const TextStyle(color: Colors.white70, fontSize: 9)))),
                  ])),
                  DataRow(cells: [
                    const DataCell(Text('DESPESAS TOTAL', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 10))),
                    ...List.generate(12, (_) => const DataCell(SizedBox.shrink())),
                  ]),
                  ...matrix['Despesa']!.entries.map((e) => DataRow(cells: [
                    DataCell(Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 9))),
                    ...e.value.map((v) => DataCell(Text(v > 0 ? '-${currency.format(v)}' : '0', style: const TextStyle(color: Colors.orangeAccent, fontSize: 9)))),
                  ])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDREFlowCards(TransactionsProvider provider) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _buildFlowCard('Margem de Contribuição', currency.format(provider.omieContributionMargin), '${provider.omieContributionMargin > 0 ? (provider.omieContributionMargin / provider.monthIncome * 100).toStringAsFixed(1) : 0}%', Colors.blueAccent),
        _buildFlowCard('EBITDA', currency.format(provider.omieEBITDA), '${provider.omieEBITDAPercent.toStringAsFixed(1)}%', Colors.blueAccent),
        _buildFlowCard('Impostos', currency.format(provider.omieTaxSummary), '${provider.monthIncome > 0 ? (provider.omieTaxSummary / provider.monthIncome * 100).toStringAsFixed(1) : 0}%', Colors.tealAccent),
        _buildFlowCard('Valor Líquido', currency.format(provider.omieOperationalResult), '${provider.omieNetMargin.toStringAsFixed(1)}%', Colors.orangeAccent),
      ],
    );
  }

  Widget _buildFlowCard(String label, String value, String percent, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Text(percent, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterfallProfitChart(TransactionsProvider provider) {
    final data = provider.omieMonthlyNetProfit;
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Valor Líquido por Mês', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            itemBuilder: (context, i) {
              final val = data[i];
              final bool isPos = val >= 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 40, child: Text(months[i], style: const TextStyle(color: Colors.white60, fontSize: 10))),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(height: 12, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6))),
                          FractionallySizedBox(
                            widthFactor: (val.abs() / (data.map((e) => e.abs()).reduce(math.max) + 1)).clamp(0.05, 1.0),
                            child: Container(height: 12, decoration: BoxDecoration(color: isPos ? Colors.greenAccent : Colors.orangeAccent, borderRadius: BorderRadius.circular(6))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(currency.format(val), style: const TextStyle(color: Colors.white, fontSize: 9)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
