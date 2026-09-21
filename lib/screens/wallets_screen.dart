import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/wallet_model.dart';
import '../providers/transactions_provider.dart';
import '../services/realtime_db_service.dart';
import 'package:intl/intl.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final _db = RealtimeDbService();
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  void _showAddWalletModal() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedColor = '#1E3A8A';

    final colors = ['#1E3A8A', '#8B0000', '#006400', '#4B0082', '#FF8C00', '#000000'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nova Conta / Carteira', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textBody)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController, 
                    style: const TextStyle(color: AppTheme.textBody),
                    decoration: const InputDecoration(labelText: 'Nome (ex: Nubank, Itaú)', labelStyle: TextStyle(color: AppTheme.textMuted))
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: balanceController, 
                    style: const TextStyle(color: AppTheme.textBody),
                    decoration: const InputDecoration(labelText: 'Saldo Inicial (R\$)', labelStyle: TextStyle(color: AppTheme.textMuted)), 
                    keyboardType: TextInputType.number
                  ),
                  const SizedBox(height: 24),
                  const Text('Cor da Conta', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: colors.map((c) {
                      final isSelected = selectedColor == c;
                      final colorObj = Color(int.parse(c.replaceAll('#', '0xFF')));
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = c),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: colorObj,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final balance = double.tryParse(balanceController.text.replaceAll(',', '.')) ?? 0.0;
                        if (name.isNotEmpty) {
                          await _db.addWallet(WalletModel(
                            id: '',
                            name: name,
                            initialBalance: balance,
                            colorHex: selectedColor,
                          ));
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary, 
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      child: const Text('SALVAR CONTA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showAdjustBalanceDialog(WalletModel wallet, double currentBalance) {
    final controller = TextEditingController(text: currentBalance.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Ajustar Saldo: ${wallet.name}', style: const TextStyle(color: AppTheme.textBody, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o saldo real que aparece no banco agora:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textBody),
              decoration: const InputDecoration(labelText: 'Saldo Real (R\$)', labelStyle: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              final newBalance = double.tryParse(controller.text.replaceAll(',', '.')) ?? currentBalance;
              await Provider.of<TransactionsProvider>(context, listen: false).adjustWalletBalance(wallet.id, newBalance);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('AJUSTAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionsProvider>(
      builder: (context, provider, child) {
        final wallets = provider.wallets;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  const Text('Saldo Consolidado', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    currency.format(provider.totalBalance),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Contas Cadastradas', style: TextStyle(color: AppTheme.textBody, fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _showAddWalletModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('NOVA CONTA'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (wallets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Nenhuma conta cadastrada. Suas transações usarão o saldo geral.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            else
              ...wallets.map((w) {
                final colorObj = Color(int.parse(w.colorHex.replaceAll('#', '0xFF')));
                final currentBalance = provider.getWalletBalance(w.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: colorObj.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(w.name.toLowerCase().contains('banco') ? Icons.account_balance : Icons.account_balance_wallet, color: colorObj),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _showAdjustBalanceDialog(w, currentBalance),
                              child: Row(
                                children: [
                                  Text(currency.format(currentBalance), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.edit_note, color: AppTheme.primary, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.surface,
                              title: const Text('Excluir Conta?', style: TextStyle(color: AppTheme.textBody)),
                              content: const Text('As transações desta conta não serão apagadas, mas ficarão sem conta definida.', style: TextStyle(color: AppTheme.textMuted)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('EXCLUIR', style: TextStyle(color: Colors.redAccent))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _db.deleteWallet(w.id);
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
