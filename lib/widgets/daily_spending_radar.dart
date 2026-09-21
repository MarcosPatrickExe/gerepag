import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import 'package:flutter/services.dart';
import '../providers/user_stats_provider.dart';
import '../services/widget_service.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class DailySpendingRadar extends StatelessWidget {
  const DailySpendingRadar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = lastDayOfMonth - now.day + 1;
    
    final double income = provider.monthIncome;
    final double expense = provider.monthExpense.abs();
    
    // Orçamento Dinâmico: Receita ou piso de 2000.
    final double monthlyBudget = math.max(income, math.max(expense, 2000.0));
        
    final availableTotal = math.max(0.0, monthlyBudget - expense);
    final dailyLimit = availableTotal / daysRemaining;
    
    final todaySpending = provider.transactions
        .where((t) => t.date.day == now.day && t.date.month == now.month && t.date.year == now.year && t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    final todayRemaining = math.max(0.0, dailyLimit - todaySpending);
    final progress = dailyLimit > 0 ? (todaySpending / dailyLimit).clamp(0.0, 1.0) : 1.0;

    // Atualizar Widget e Reportar Sobrevivência (Async)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetService.updateRadar(dailyLimit, todayRemaining);
      Provider.of<UserStatsProvider>(context, listen: false).reportRadarSurvival(todaySpending <= dailyLimit);
    });

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showExplanation(context, monthlyBudget, expense, availableTotal, daysRemaining, dailyLimit, todaySpending, todayRemaining);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withValues(alpha: 0.15),
              AppTheme.secondary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: 1 - progress,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.expense.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.8 ? AppTheme.expense : AppTheme.income,
                    ),
                  ),
                ),
                const Icon(Icons.radar, color: AppTheme.primary, size: 28),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RADAR DE SOBREVIVÊNCIA 🎯',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Limite Diário (Hoje):',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textBody.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    currency.format(todayRemaining),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toque para ver o cálculo 👆',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExplanation(
    BuildContext context, 
    double budget, 
    double spent, 
    double available, 
    int days, 
    double limit, 
    double todaySpent, 
    double todayLeft
  ) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 32,
          right: 32,
          top: 32
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Por que este valor? 🧐', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('O Radar calcula seu limite diário para você nunca fechar o mês no vermelho.', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 24),
              _buildCalcRow('Orçamento Mensal (Base)', currency.format(budget), Icons.account_balance_wallet),
              _buildCalcRow('Já gasto este mês', '- ${currency.format(spent)}', Icons.shopping_bag_outlined, color: AppTheme.expense),
              const Divider(height: 32, color: Colors.white10),
              _buildCalcRow('Disponível para o resto do mês', currency.format(available), Icons.event_available, isBold: true),
              _buildCalcRow('Dias restantes no mês', '$days dias', Icons.calendar_today),
              const Divider(height: 32, color: Colors.white10),
              _buildCalcRow('Limite Ideal por dia', currency.format(limit), Icons.track_changes, color: AppTheme.primary),
              _buildCalcRow('Gasto hoje', '- ${currency.format(todaySpent)}', Icons.today, color: AppTheme.expense),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Você ainda tem ${currency.format(todayLeft)} para gastar hoje com segurança.',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, IconData icon, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))),
          Text(
            value, 
            style: TextStyle(
              color: color ?? AppTheme.textBody, 
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              fontSize: 14,
            )
          ),
        ],
      ),
    );
  }
}
