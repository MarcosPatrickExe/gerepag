import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/transaction_model.dart';
import '../services/ocr_service.dart';
import '../providers/transactions_provider.dart';
import '../providers/subscription_provider.dart';

class BatchScannedItem {
  final String imagePath;
  final OcrResult ocrResult;
  final TextEditingController titleController;
  final TextEditingController amountController;
  String selectedCategory;
  bool shouldReconcile;
  dynamic selectedBill;
  List<dynamic> unpaidBills;

  BatchScannedItem({
    required this.imagePath,
    required this.ocrResult,
    required this.titleController,
    required this.amountController,
    this.selectedCategory = 'Geral',
    this.shouldReconcile = false,
    this.selectedBill,
    this.unpaidBills = const [],
  });
}

class BatchScannerScreen extends StatefulWidget {
  final List<MapEntry<String, OcrResult>> processedItems;

  const BatchScannerScreen({super.key, required this.processedItems});

  @override
  State<BatchScannerScreen> createState() => _BatchScannerScreenState();
}

class _BatchScannerScreenState extends State<BatchScannerScreen> {
  final List<BatchScannedItem> _items = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TransactionsProvider>(context, listen: false);

    for (var entry in widget.processedItems) {
      final imagePath = entry.key;
      final result = entry.value;

      final titleCtrl = TextEditingController(text: result.restaurant ?? 'Gasto via Scanner');
      final amountCtrl = TextEditingController(text: result.amount?.toStringAsFixed(2) ?? '');
      final double ocrAmount = result.amount ?? 0.0;

      // Buscar títulos não pagos com valor aproximado (+- R$ 1,00)
      final matchedBills = provider.omieAccountsPayable.where((x) {
        final status = x['status_titulo'] ?? (x['cStatus'] == 'P' ? 'PAGO' : 'ABERTO');
        if (status == 'PAGO') return false;
        final val = double.tryParse(x['valor_documento']?.toString() ?? x['vValor']?.toString() ?? '0') ?? 0.0;
        return (val - ocrAmount).abs() <= 1.00;
      }).toList();

      _items.add(BatchScannedItem(
        imagePath: imagePath,
        ocrResult: result,
        titleController: titleCtrl,
        amountController: amountCtrl,
        unpaidBills: matchedBills,
        shouldReconcile: matchedBills.isNotEmpty,
        selectedBill: matchedBills.isNotEmpty ? matchedBills.first : null,
      ));
    }
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.titleController.dispose();
      item.amountController.dispose();
    }
    super.dispose();
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].titleController.dispose();
      _items[index].amountController.dispose();
      _items.removeAt(index);
    });

    if (_items.isEmpty) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveAll() async {
    // Validar valores
    for (var item in _items) {
      final amount = double.tryParse(item.amountController.text) ?? 0.0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, defina um valor válido para o item: "${item.titleController.text}"'),
            backgroundColor: AppTheme.expense,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<TransactionsProvider>(context, listen: false);
      final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);

      int successReconciled = 0;
      int successLocal = 0;

      for (var item in _items) {
        final amount = double.tryParse(item.amountController.text) ?? 0.0;

        if (item.shouldReconcile && item.selectedBill != null) {
          final selectedBill = item.selectedBill;
          final int? nCodLanc = int.tryParse(selectedBill['codigo_lancamento_omie']?.toString() ??
              selectedBill['codigo_lancamento_integracao']?.toString() ??
              '');
          if (nCodLanc != null) {
            final success = await provider.payOmieBill(nCodLanc, amount);
            if (success) successReconciled++;
          }
        } else {
          // Salvar local
          provider.addTransaction(TransactionModel(
            id: '',
            description: item.titleController.text,
            amount: amount,
            date: item.ocrResult.date ?? DateTime.now(),
            category: item.selectedCategory,
            type: TransactionType.expense,
          ));
          successLocal++;
        }
        subProvider.incrementOCRUsage();
      }

      if (mounted) {
        String msg = '';
        if (successReconciled > 0 && successLocal > 0) {
          msg = '$successReconciled título(s) conciliado(s) no Omie e $successLocal gasto(s) local(is) salvo(s)! 🎉';
        } else if (successReconciled > 0) {
          msg = '🎉 $successReconciled título(s) liquidado(s) e conciliado(s) no Omie com sucesso!';
        } else {
          msg = '🎉 $successLocal gasto(s) local(is) cadastrado(s) com sucesso!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.income),
        );

        Navigator.pop(context); // Volta da BatchScreen
        Navigator.pop(context); // Volta da ScannerScreen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar gastos: $e'), backgroundColor: AppTheme.expense),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Revisão em Lote (${_items.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 24),
                  Text('Sincronizando com Omie & Salvando Gastos...', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _buildItemCard(item, index);
                    },
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildItemCard(BatchScannedItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      File(item.imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Form Fields
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: item.titleController,
                        decoration: const InputDecoration(
                          labelText: 'Estabelecimento',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: item.amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Valor (R\$)',
                                prefixText: 'R\$ ',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: item.selectedCategory,
                              isDense: true,
                              items: ['Geral', 'Comida', 'Transporte', 'Lazer', 'Saúde']
                                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  item.selectedCategory = val!;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Categoria',
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.expense),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            if (item.unpaidBills.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.income.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.income.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppTheme.income, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Título Omie Encontrado!',
                            style: TextStyle(
                              color: AppTheme.income,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Switch(
                          value: item.shouldReconcile,
                          activeColor: AppTheme.income,
                          onChanged: (val) {
                            setState(() {
                              item.shouldReconcile = val;
                            });
                          },
                        ),
                      ],
                    ),
                    if (item.shouldReconcile) ...[
                      const SizedBox(height: 8),
                      if (item.unpaidBills.length == 1)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.selectedBill['descricao'] ?? item.selectedBill['cDescr'] ?? 'Sem descrição',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Vencimento: ${item.selectedBill['data_vencimento'] ?? item.selectedBill['dDtVenc'] ?? ''}',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  ),
                                  Text(
                                    'Valor: R\$ ${(double.tryParse(item.selectedBill['valor_documento']?.toString() ?? item.selectedBill['vValor']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.expense),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<dynamic>(
                          initialValue: item.selectedBill,
                          decoration: const InputDecoration(
                            labelText: 'Escolha o Título Omie',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          items: item.unpaidBills.map((x) {
                            final desc = x['descricao'] ?? x['cDescr'] ?? 'Sem descrição';
                            final date = x['data_vencimento'] ?? x['dDtVenc'] ?? '';
                            final val = double.tryParse(x['valor_documento']?.toString() ?? x['vValor']?.toString() ?? '0.0') ?? 0.0;
                            return DropdownMenuItem<dynamic>(
                              value: x,
                              child: SizedBox(
                                width: 180,
                                child: Text(
                                  '$date - $desc (R\$ ${val.toStringAsFixed(2)})',
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              item.selectedBill = val;
                            });
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'SALVAR TODOS OS GASTOS (${_items.length}) 📄',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
