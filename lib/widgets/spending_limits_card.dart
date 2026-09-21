import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import '../services/budget_service.dart';
import 'budget_dashboard_view.dart';

class SpendingLimitsCard extends StatelessWidget {
  const SpendingLimitsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final transProvider = Provider.of<TransactionsProvider>(context);
    final budgetService = Provider.of<BudgetService>(context);
    
    final budgets = budgetService.budgets;
    final actualExpenses = transProvider.expenseByCategoryRank;

    // Se não há orçamentos configurados na nuvem
    if (budgets.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Orçamento'),
                    backgroundColor: AppTheme.background,
                    elevation: 0,
                  ),
                  body: const SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: BudgetDashboardView(),
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Limites de Gastos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum limite de gastos definido.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Clique aqui para definir limites e controlar seu orçamento mensal.',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Se temos limites de orçamentos, exibir dinamicamente
    final List<Widget> items = [];
    final List<Color> colors = [
      Colors.orangeAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.greenAccent,
    ];

    int colorIdx = 0;
    budgets.forEach((category, limitAmount) {
      final currentSpent = actualExpenses[category] ?? 0.0;
      final color = colors[colorIdx % colors.length];
      colorIdx++;

      items.add(_buildLimitItem(category, currentSpent, limitAmount, color));
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Limites de Gastos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Orçamento'),
                            backgroundColor: AppTheme.background,
                            elevation: 0,
                          ),
                          body: const SingleChildScrollView(
                            padding: EdgeInsets.all(24),
                            child: BudgetDashboardView(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildLimitItem(String name, double current, double max, Color color) {
    final double progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                'R\$ ${current.toStringAsFixed(2)} / R\$ ${max.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
