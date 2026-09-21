import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transactions_provider.dart';
import '../core/app_theme.dart';

class BankReconciliationScreen extends StatefulWidget {
  final List<TransactionModel> extractedTransactions;

  const BankReconciliationScreen({
    super.key, 
    required this.extractedTransactions
  });

  @override
  State<BankReconciliationScreen> createState() => _BankReconciliationScreenState();
}

class _BankReconciliationScreenState extends State<BankReconciliationScreen> {
  late List<ReconciliationItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.extractedTransactions.map((t) => ReconciliationItem(transaction: t)).toList();
    _identifyDuplicates();
  }

  void _identifyDuplicates() {
    final provider = Provider.of<TransactionsProvider>(context, listen: false);
    final existing = provider.transactions;

    for (var item in _items) {
      final isDuplicate = existing.any((t) => 
        t.amount == item.transaction.amount && 
        DateFormat('ddMMyy').format(t.date) == DateFormat('ddMMyy').format(item.transaction.date)
      );
      if (isDuplicate) {
        item.isDuplicate = true;
        item.shouldImport = false;
      }
    }
  }

  Future<void> _importSelected() async {
    setState(() => _isSaving = true);
    final provider = Provider.of<TransactionsProvider>(context, listen: false);
    
    int count = 0;
    for (var item in _items) {
      if (item.shouldImport) {
        await provider.addTransaction(item.transaction);
        count++;
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $count lançamentos importados com sucesso!'))
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Conciliação IA 🤖', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton(
                onPressed: _importSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('LANÇAR NA OMIE'),
              ),
            ),
        ],
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.primary.withValues(alpha: 0.1),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primary, size: 16),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A GerePag identificou estes lançamentos no seu PDF. Lançamentos com ícone amarelo já parecem existir no sistema.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final t = item.transaction;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: item.shouldImport ? AppTheme.primary.withValues(alpha: 0.3) : Colors.white10
                        ),
                      ),
                      child: CheckboxListTile(
                        value: item.shouldImport,
                        onChanged: (val) => setState(() => item.shouldImport = val ?? false),
                        activeColor: AppTheme.primary,
                        checkColor: Colors.black,
                        title: Text(
                          t.description,
                          style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('${DateFormat('dd/MM/yyyy').format(t.date)} • ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                Text(t.category, style: const TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (item.isDuplicate)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 14),
                                    SizedBox(width: 4),
                                    Text('PROVÁVEL DUPLICADO', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        secondary: Text(
                          currency.format(t.amount),
                          style: TextStyle(
                            color: t.type == TransactionType.income ? AppTheme.income : AppTheme.expense,
                            fontWeight: FontWeight.w900,
                            fontSize: 16
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}

class ReconciliationItem {
  final TransactionModel transaction;
  bool shouldImport;
  bool isDuplicate;

  ReconciliationItem({
    required this.transaction,
    this.shouldImport = true,
    this.isDuplicate = false,
  });
}
