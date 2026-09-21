import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transactions_provider.dart';
import '../services/budget_service.dart';
import '../services/realtime_db_service.dart';
import '../core/app_theme.dart';
import 'package:intl/intl.dart';

class BudgetDashboardView extends StatelessWidget {
  const BudgetDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final budgetService = Provider.of<BudgetService>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    // Pegar gastos reais por categoria do mês atual do TransactionsProvider
    final Map<String, double> actualExpenses = provider.expenseByCategoryRank;
    final Map<String, double> budgets = budgetService.budgets;

    // Filtrar apenas categorias que possuem orçamento definido
    final categoriesWithBudget = budgets.keys.toList();

    return StreamBuilder<List<String>>(
      stream: RealtimeDbService().getCategories(),
      builder: (context, snapshot) {
        final customCategories = snapshot.data ?? [];
        final defaultCatNames = ['Comida', 'Transporte', 'Lazer', 'Saúde'];
        
        final List<String> allAvailableCategories = [];
        if (provider.isBusinessMode) {
          allAvailableCategories.addAll(
            provider.omieCategories.values.map((v) => v.toString()).toSet().toList()
          );
        } else {
          allAvailableCategories.addAll(
            {...defaultCatNames, ...customCategories}.toList()
          );
        }

        // Se a lista resultante ainda estiver vazia, garantimos as padrões
        if (allAvailableCategories.isEmpty) {
          allAvailableCategories.addAll(defaultCatNames);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'CONTROLE DE ORÇAMENTO',
                    style: TextStyle(color: AppTheme.textBody, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showSetBudgetDialog(context, budgetService, allAvailableCategories),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('DEFINIR META'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (categoriesWithBudget.isEmpty)
              _buildEmptyState()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 500,
                  mainAxisExtent: 140,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categoriesWithBudget.length,
                itemBuilder: (context, index) {
                  final cat = categoriesWithBudget[index];
                  final limit = budgets[cat] ?? 0.0;
                  final spent = actualExpenses[cat] ?? 0.0;
                  final progress = (spent / limit).clamp(0.0, 1.0);
                  final isOver = spent > limit;
                  final color = _getBudgetColor(progress, isOver);

                  return GestureDetector(
                    onTap: () => _showSetBudgetDialog(context, budgetService, [cat], initialAmount: limit),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cat.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(
                                isOver ? 'LIMITE EXCEDIDO' : '${(progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(currency.format(spent), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('de ${currency.format(limit)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(color: AppTheme.textBody.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color]),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Color _getBudgetColor(double progress, bool isOver) {
    if (isOver) return Colors.redAccent;
    if (progress > 0.9) return Colors.orangeAccent;
    if (progress > 0.7) return Colors.amberAccent;
    return Colors.greenAccent;
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
      ),
      child: const Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppTheme.textMuted),
          SizedBox(height: 16),
          Text('Nenhum orçamento definido', style: TextStyle(color: AppTheme.textMuted)),
          Text('Clique em "Definir Meta" para começar o controle.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext context, BudgetService service, List<String> availableCategories, {double? initialAmount}) {
    String? selectedCat = availableCategories.isNotEmpty ? availableCategories.first : null;
    final controller = TextEditingController(text: initialAmount?.toStringAsFixed(2) ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(initialAmount != null ? 'Editar Limite de Gastos' : 'Definir Limite de Gastos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (initialAmount == null)
              DropdownButtonFormField<String>(
                initialValue: selectedCat,
                dropdownColor: AppTheme.surface,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: AppTheme.textBody)))).toList(),
                onChanged: (v) => selectedCat = v,
              )
            else
              Text('Categoria: ${availableCategories.first}', style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor Limite (R\$)', prefixText: 'R\$ '),
              style: const TextStyle(color: AppTheme.textBody),
            ),
          ],
        ),
        actions: [
          if (initialAmount != null)
            TextButton(
              onPressed: () {
                service.deleteBudget(availableCategories.first);
                Navigator.pop(context);
              },
              child: const Text('LIMPAR META', style: TextStyle(color: Colors.redAccent)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final cat = initialAmount != null ? availableCategories.first : selectedCat;
              if (cat != null && controller.text.isNotEmpty) {
                service.setBudget(cat, double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0);
                Navigator.pop(context);
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }
}
