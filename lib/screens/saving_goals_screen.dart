import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../services/realtime_db_service.dart';


class SavingGoalsScreen extends StatefulWidget {
  const SavingGoalsScreen({super.key});

  @override
  State<SavingGoalsScreen> createState() => _SavingGoalsScreenState();
}

class _SavingGoalsScreenState extends State<SavingGoalsScreen> {
  final _realtimeService = RealtimeDbService();
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  /// Returns a constant [IconData] based on the provided code point.
  IconData _iconDataFromCode(int code) {
    if (code == Icons.savings.codePoint) {
      return Icons.savings;
    } else if (code == Icons.account_balance_wallet.codePoint) {
      return Icons.account_balance_wallet;
    }
    // Add more mappings as needed.
    return Icons.help_outline;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Metas & Cofrinhos 🎯',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBody),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _realtimeService.getSavingGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final goals = snapshot.data ?? [];

          if (goals.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _buildGoalCard(goal);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showGoalFormDialog(context),
        child: const Icon(Icons.add_task_rounded, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_outlined, size: 64, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhuma meta ativa',
            style: TextStyle(color: AppTheme.textBody, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.0),
            child: Text(
              'Crie metas de poupança (ex: Comprar Computador, Reserva de Emergência) para acompanhar sua evolução.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final String id = goal['id'] ?? '';
    final String name = goal['name'] ?? 'Meta';
    final double target = double.tryParse(goal['targetAmount']?.toString() ?? '0') ?? 0.0;
    final double current = double.tryParse(goal['currentAmount']?.toString() ?? '0') ?? 0.0;
    final int colorVal = goal['colorValue'] ?? Colors.blueAccent.value;
    final int iconCode = goal['iconCodePoint'] ?? Icons.savings.codePoint;

    final double pct = target > 0 ? (current / target) : 0.0;
    final double progressPercent = pct > 1.0 ? 1.0 : (pct < 0.0 ? 0.0 : pct);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(colorVal).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconDataFromCode(iconCode),
                    color: Color(colorVal),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Objetivo: ${currency.format(target)}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.expense, size: 20),
                  onPressed: () => _confirmDeleteGoal(context, id),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currency.format(current),
                  style: TextStyle(color: Color(colorVal), fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Barra de Progresso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      flex: (progressPercent * 100).round(),
                      child: Container(color: Color(colorVal)),
                    ),
                    Expanded(
                      flex: ((1 - progressPercent) * 100).round(),
                      child: Container(color: Colors.white10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddFundsDialog(context, id, name, current, isWithdraw: false),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('DEPOSITAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddFundsDialog(context, id, name, current, isWithdraw: true),
                    icon: const Icon(Icons.remove_rounded, size: 16),
                    label: const Text('RESGATAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFundsDialog(BuildContext context, String id, String name, double current, {required bool isWithdraw}) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          isWithdraw ? 'Resgatar do Cofrinho 💸' : 'Guardar no Cofrinho 💰',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meta: $name\nSaldo Atual: ${currency.format(current)}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textBody),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                prefixText: 'R\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final double amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, informe um valor maior que zero.')),
                );
                return;
              }

              if (isWithdraw && amount > current) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saldo insuficiente no cofrinho para resgatar esse valor!')),
                );
                return;
              }

              final double updated = isWithdraw ? (current - amount) : (current + amount);
              await _realtimeService.updateGoalAmount(id, updated);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isWithdraw 
                        ? 'Resgatado R\$ ${amount.toStringAsFixed(2)} com sucesso!' 
                        : 'Guardado R\$ ${amount.toStringAsFixed(2)} com sucesso!'
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }

  void _showGoalFormDialog(BuildContext context) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    int selectedColorVal = Colors.blueAccent.value;
    int selectedIconCode = Icons.savings.codePoint;

    final List<Color> colors = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.amberAccent,
    ];

    final List<IconData> icons = [
      Icons.savings,
      Icons.computer_rounded,
      Icons.directions_car_filled_rounded,
      Icons.flight_takeoff_rounded,
      Icons.home_work_rounded,
      Icons.favorite_rounded,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Novo Cofrinho / Meta 🎯', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: AppTheme.textBody),
                    decoration: const InputDecoration(labelText: 'Nome da Meta (ex: Notebook)'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome da meta' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: targetController,
                    style: const TextStyle(color: AppTheme.textBody),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor Alvo (R\$)', prefixText: 'R\$ '),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe o valor alvo';
                      if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Seletor de Ícone
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Escolha um Ícone:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: icons.map((icon) {
                      final bool isSel = icon.codePoint == selectedIconCode;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIconCode = icon.codePoint),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSel ? AppTheme.primary : Colors.white10),
                          ),
                          child: Icon(icon, color: isSel ? AppTheme.primary : AppTheme.textMuted, size: 20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Seletor de Cor
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Escolha uma Cor:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: colors.map((col) {
                      final bool isSel = col.value == selectedColorVal;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColorVal = col.value),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await _realtimeService.addSavingGoal({
                  'name': nameController.text.trim(),
                  'targetAmount': double.tryParse(targetController.text.replaceAll(',', '.')) ?? 0.0,
                  'currentAmount': 0.0,
                  'iconCodePoint': selectedIconCode,
                  'colorValue': selectedColorVal,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meta criada com sucesso! 🎯'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('SALVAR META'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGoal(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Excluir Meta?'),
        content: const Text('Tem certeza de que deseja excluir este cofrinho? O progresso acumulado será perdido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NÃO', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              await _realtimeService.deleteSavingGoal(id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meta excluída com sucesso.')),
                );
              }
            },
            child: const Text('SIM, EXCLUIR', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }
}
