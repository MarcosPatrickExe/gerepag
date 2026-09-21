import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_theme.dart';
import '../models/transaction_model.dart';
import '../services/ocr_service.dart';
import '../providers/transactions_provider.dart';
import '../providers/subscription_provider.dart';
import 'upgrade_screen.dart';
import 'batch_scanner_screen.dart';
import 'package:provider/provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  String _processingMessage = 'A Inteligência Artificial está lendo sua nota...';

  Future<void> _scanBatch() async {
    final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);

    if (!subProvider.isPro) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Iniciando leitura em lote de ${images.length} nota(s)... 🤖';
    });

    final List<MapEntry<String, OcrResult>> processed = [];

    try {
      for (int i = 0; i < images.length; i++) {
        if (!mounted) break;
        setState(() {
          _processingMessage = 'Lendo nota ${i + 1} de ${images.length}... 🤖';
        });
        final result = await _ocrService.processImage(images[i].path);
        processed.add(MapEntry(images[i].path, result));
      }

      if (mounted && processed.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BatchScannerScreen(processedItems: processed),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar lote: $e'), backgroundColor: AppTheme.expense),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _scanFromSource(ImageSource source) async {
    final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    if (!subProvider.canUseOCR) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
      return;
    }

    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _ocrService.processImage(image.path);
      if (mounted) {
        _showConfirmationDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ler nota: $e'), backgroundColor: AppTheme.expense),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showConfirmationDialog(OcrResult result) {
    final titleController = TextEditingController(text: result.restaurant ?? 'Gasto via Scanner');
    final amountController = TextEditingController(text: result.amount?.toStringAsFixed(2) ?? '');
    String selectedCategory = 'Geral';

    final provider = Provider.of<TransactionsProvider>(context, listen: false);
    final double ocrAmount = result.amount ?? 0.0;

    // Buscar títulos não pagos com valor aproximado (+- R$ 1,00)
    final unpaidBills = provider.omieAccountsPayable.where((x) {
      final status = x['status_titulo'] ?? (x['cStatus'] == 'P' ? 'PAGO' : 'ABERTO');
      if (status == 'PAGO') return false;
      final val = double.tryParse(x['valor_documento']?.toString() ?? x['vValor']?.toString() ?? '0') ?? 0.0;
      return (val - ocrAmount).abs() <= 1.00;
    }).toList();

    bool shouldReconcile = unpaidBills.isNotEmpty;
    dynamic selectedBill = unpaidBills.isNotEmpty ? unpaidBills.first : null;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Confirmar Dados 🧾'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: AppTheme.inputDecoration('Estabelecimento', Icons.store),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: AppTheme.inputDecoration('Valor (R\$)', Icons.attach_money),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: ['Geral', 'Comida', 'Transporte', 'Lazer', 'Saúde']
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) => selectedCategory = val!,
                    decoration: AppTheme.inputDecoration('Categoria', Icons.category),
                  ),
                  if (unpaidBills.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
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
                              const Icon(Icons.check_circle_outline, color: AppTheme.income, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Título Omie Encontrado!',
                                  style: TextStyle(
                                    color: AppTheme.income,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Deseja realizar a conciliação inteligente e dar baixa automática deste cupom no Omie ERP?',
                            style: TextStyle(fontSize: 12, color: AppTheme.textBody),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Conciliar com Omie',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            value: shouldReconcile,
                            activeColor: AppTheme.income,
                            onChanged: (val) {
                              setStateDialog(() {
                                shouldReconcile = val;
                              });
                            },
                          ),
                          if (shouldReconcile) ...[
                            const SizedBox(height: 8),
                            if (unpaidBills.length == 1)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedBill['descricao'] ?? selectedBill['cDescr'] ?? 'Sem descrição',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Vencimento: ${selectedBill['data_vencimento'] ?? selectedBill['dDtVenc'] ?? ''}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                        ),
                                        Text(
                                          'Valor: R\$ ${(double.tryParse(selectedBill['valor_documento']?.toString() ?? selectedBill['vValor']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.expense),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              )
                            else
                              DropdownButtonFormField<dynamic>(
                                value: selectedBill,
                                decoration: const InputDecoration(
                                  labelText: 'Escolha o Título Omie',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: unpaidBills.map((x) {
                                  final desc = x['descricao'] ?? x['cDescr'] ?? 'Sem descrição';
                                  final date = x['data_vencimento'] ?? x['dDtVenc'] ?? '';
                                  final val = double.tryParse(x['valor_documento']?.toString() ?? x['vValor']?.toString() ?? '0.0') ?? 0.0;
                                  return DropdownMenuItem<dynamic>(
                                    value: x,
                                    child: SizedBox(
                                      width: 200,
                                      child: Text(
                                        '$date - $desc (R\$ ${val.toStringAsFixed(2)})',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setStateDialog(() {
                                    selectedBill = val;
                                  });
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (isSaving) ...[
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        SizedBox(width: 16),
                        Text('Sincronizando com Omie...', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final amount = double.tryParse(amountController.text) ?? 0.0;
                        if (amount <= 0) return;

                        setStateDialog(() {
                          isSaving = true;
                        });

                        final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);

                        if (shouldReconcile && selectedBill != null) {
                          // Conciliação Omie
                          final int? nCodLanc = int.tryParse(selectedBill['codigo_lancamento_omie']?.toString() ??
                              selectedBill['codigo_lancamento_integracao']?.toString() ??
                              '');
                          if (nCodLanc != null) {
                            try {
                              final success = await provider.payOmieBill(nCodLanc, amount);
                              if (success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Título liquidado e conciliado no Omie ERP com sucesso! 🎉'),
                                      backgroundColor: AppTheme.income,
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Erro ao conciliar título no Omie ERP. Lançamento local não efetuado.'),
                                      backgroundColor: AppTheme.expense,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro na conciliação Omie: $e'),
                                    backgroundColor: AppTheme.expense,
                                  ),
                                );
                              }
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Código de lançamento inválido.'),
                                  backgroundColor: AppTheme.expense,
                                ),
                              );
                            }
                          }
                        } else {
                          // Lançamento Local Normal
                          provider.addTransaction(TransactionModel(
                            id: '',
                            description: titleController.text,
                            amount: amount,
                            date: result.date ?? DateTime.now(),
                            category: selectedCategory,
                            type: TransactionType.expense,
                          ));
                        }

                        subProvider.incrementOCRUsage();
                        if (context.mounted) {
                          Navigator.pop(context); // Fecha dialog
                          Navigator.pop(context); // Volta para Home
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('SALVAR GASTO', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner de Notas'), elevation: 0),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const CircularProgressIndicator(color: AppTheme.primary),
                   const SizedBox(height: 24),
                   Text(_processingMessage, style: const TextStyle(color: AppTheme.textMuted)),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 80, color: AppTheme.primary.withValues(alpha: 0.2)),
                    const SizedBox(height: 32),
                    const Text(
                      'Economize tempo!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aponte a câmera para o cupom fiscal ou escolha fotos da galeria.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 48),
                    _ScannerButton(
                      icon: Icons.camera_alt,
                      label: 'USAR CÂMERA',
                      onPressed: () => _scanFromSource(ImageSource.camera),
                    ),
                    const SizedBox(height: 16),
                    _ScannerButton(
                      icon: Icons.photo_library,
                      label: 'ESCOLHER DA GALERIA',
                      onPressed: () => _scanFromSource(ImageSource.gallery),
                      isSecondary: true,
                    ),
                    const SizedBox(height: 16),
                    _ScannerButton(
                      icon: Icons.auto_awesome_motion_rounded,
                      label: 'ESCANEAR EM LOTE',
                      onPressed: _scanBatch,
                      isSecondary: true,
                      trailing: subProvider.isPro ? null : const Icon(Icons.lock, size: 16, color: Colors.orange),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ScannerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;
  final Widget? trailing;

  const _ScannerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? AppTheme.surface : AppTheme.primary,
          foregroundColor: isSecondary ? AppTheme.primary : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: isSecondary ? const BorderSide(color: AppTheme.primary) : null,
        ),
      ),
    );
  }
}
