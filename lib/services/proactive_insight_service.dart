import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../providers/transactions_provider.dart';
import '../services/realtime_db_service.dart';

class ProactiveInsight {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String actionLabel;
  final VoidCallback? onAction;

  ProactiveInsight({
    required this.title,
    required this.message,
    required this.icon,
    this.color = Colors.blue,
    this.actionLabel = 'DETALHES',
    this.onAction,
  });
}

class ProactiveInsightService {
  static List<ProactiveInsight> generateInsights(TransactionsProvider provider) {
    List<ProactiveInsight> insights = [];
    final transactions = provider.transactions;
    if (transactions.isEmpty) return insights;

    final now = DateTime.now();
    final thisWeek = transactions.where((t) => t.date.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final lastWeek = transactions.where((t) => 
      t.date.isAfter(now.subtract(const Duration(days: 14))) && 
      t.date.isBefore(now.subtract(const Duration(days: 7)))
    ).toList();

    // 1. Insight de Categoria (ex: Comida/iFood)
    _checkCategorySaving(thisWeek, lastWeek, '🍟 Comida', insights);
    
    // 2. Insight de Saúde Financeira
    final totalIncome = thisWeek.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = thisWeek.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
    
    if (totalIncome > totalExpense && totalExpense > 0) {
      final savingRate = ((totalIncome - totalExpense) / totalIncome) * 100;
      if (savingRate > 20) {
        insights.add(ProactiveInsight(
          title: 'Parabéns pela Economia! 💰',
          message: 'Você guardou ${savingRate.toStringAsFixed(0)}% do que ganhou esta semana. Que tal investir esse valor?',
          icon: Icons.trending_up,
          color: Colors.green,
          actionLabel: 'INVESTIR',
        ));
      }
    }

    // 3. Projeção de Metas (Foco em Metas)
    // (Simulado: Se houver metas cadastradas, calcular projeção)
    // No RealtimeDbService as metas são sincronizadas.
    
    return insights;
  }

  static void _checkCategorySaving(List<TransactionModel> thisWeek, List<TransactionModel> lastWeek, String category, List<ProactiveInsight> insights) {
    final thisWeekCat = thisWeek.where((t) => t.category.contains(category)).fold(0.0, (sum, t) => sum + t.amount);
    final lastWeekCat = lastWeek.where((t) => t.category.contains(category)).fold(0.0, (sum, t) => sum + t.amount);

    if (thisWeekCat < lastWeekCat && lastWeekCat > 0) {
      final saving = ((lastWeekCat - thisWeekCat) / lastWeekCat) * 100;
      if (saving > 10) {
        insights.add(ProactiveInsight(
          title: 'Menos gastos com $category! 🍔',
          message: 'Você gastou ${saving.toStringAsFixed(0)}% menos com $category comparado à semana passada. Mandou bem!',
          icon: Icons.thumb_up_alt_rounded,
          color: Colors.orange,
        ));
      }
    }
  }
}
