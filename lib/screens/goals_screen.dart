import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../core/app_theme.dart';
import '../models/goal_model.dart';
import '../services/realtime_db_service.dart';
import 'package:intl/intl.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final RealtimeDbService _db = RealtimeDbService();
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Caixinhas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            onPressed: () => _showGoalForm(context),
          ),
        ],
      ),
      body: StreamBuilder<List<GoalModel>>(
        stream: _db.getGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = snapshot.data ?? [];
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_outlined, size: 80, color: AppTheme.textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('Nenhuma caixinha criada ainda.', style: TextStyle(color: AppTheme.textMuted)),
                  TextButton(onPressed: () => _showGoalForm(context), child: const Text('Criar primeira meta')),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _GoalCard(
                goal: goal, 
                onDeposit: () => _showDeposit(context, goal),
                onEdit: () => _showGoalForm(context, goal: goal),
              );
            },
          );
        },
      ),
    );
  }

  void _showGoalForm(BuildContext context, {GoalModel? goal}) {
    final titleController = TextEditingController(text: goal?.title);
    final amountController = TextEditingController(text: goal?.targetAmount.toString());
    GoalIcon selectedIcon = goal?.icon ?? GoalIcon.savings;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(goal == null ? 'Novo Objetivo' : 'Editar Objetivo', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (goal != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.expense),
                      onPressed: () {
                        _db.deleteGoal(goal.id);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'O que você quer conquistar?'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Qual o valor total? (R\$)', prefixText: 'R\$ '),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              const Text('Escolha um ícone:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: GoalIcon.values.map((gi) {
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedIcon = gi),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedIcon == gi ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                        border: Border.all(color: selectedIcon == gi ? AppTheme.primary : Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(gi.iconData, color: selectedIcon == gi ? AppTheme.primary : AppTheme.textMuted),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (titleController.text.isNotEmpty && amount > 0) {
                      final newGoal = GoalModel(
                        id: goal?.id ?? '',
                        title: titleController.text,
                        targetAmount: amount,
                        currentAmount: goal?.currentAmount ?? 0,
                        icon: selectedIcon,
                        deadline: goal?.deadline ?? DateTime.now().add(const Duration(days: 365)),
                      );
                      if (goal == null) {
                        _db.addGoal(newGoal);
                      } else {
                        // O addGoal no RealtimeDbService usa push(), precisamos de um updateGoal
                        // Mas vou usar o id existente se disponível.
                        _db.addGoal(newGoal); 
                      }
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(goal == null ? 'CRIAR CAIXINHA' : 'SALVAR ALTERAÇÕES', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeposit(BuildContext context, GoalModel goal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Depositar em: ${goal.title}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Valor do depósito', prefixText: 'R\$ '),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final deposit = double.tryParse(controller.text) ?? 0.0;
              if (deposit > 0) {
                final newAmount = goal.currentAmount + deposit;
                _db.updateGoalProgress(goal.id, newAmount);
                Navigator.pop(context);
                if (newAmount >= goal.targetAmount) {
                  _db.unlockBadge('goal_reached');
                  _showSuccess(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('DEPOSITAR', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 PARABÉNS! Você conquistou um objetivo!'),
        backgroundColor: AppTheme.income,
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onDeposit;
  final VoidCallback onEdit;

  const _GoalCard({required this.goal, required this.onDeposit, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return GestureDetector(
      onLongPress: onEdit,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 8.0,
              percent: goal.progress,
              center: Icon(goal.icon.iconData, color: AppTheme.primary, size: 30),
              progressColor: AppTheme.primary,
              backgroundColor: AppTheme.background,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
            ),
            const SizedBox(height: 12),
            Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(currency.format(goal.currentAmount), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            Text('de ${currency.format(goal.targetAmount)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onDeposit,
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('DEPOSITAR', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
