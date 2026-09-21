import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';

class OmieBillingScreen extends StatefulWidget {
  const OmieBillingScreen({super.key});

  @override
  State<OmieBillingScreen> createState() => _OmieBillingScreenState();
}

class _OmieBillingScreenState extends State<OmieBillingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedClientId;
  String? _selectedCategoryId;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.black,
              surface: AppTheme.surface,
              onSurface: AppTheme.textBody,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm(TransactionsProvider provider) async {
    if (!_formKey.currentState!.validate() || _selectedClientId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos e selecione cliente/categoria.'),
          backgroundColor: AppTheme.expense,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final clientCode = int.tryParse(_selectedClientId!) ?? 0;
    final dueDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final categoryCode = _selectedCategoryId!;
    final description = _descController.text;

    final success = await provider.createOmieReceivable(
      clientCode: clientCode,
      dueDate: dueDate,
      amount: amount,
      categoryCode: categoryCode,
      description: description,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Conta a Receber cadastrada com sucesso na Omie!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Falha ao cadastrar cobrança. Verifique a conexão ou chaves da Omie.'),
            backgroundColor: AppTheme.expense,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final clients = provider.omieClients;
    final categories = provider.omieCategories;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Nova Cobrança Omie 🚀', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBody),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SELECIONE O CLIENTE',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: AppTheme.surface,
                      value: _selectedClientId,
                      items: clients.entries.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(
                            e.value.split('|').first,
                            style: const TextStyle(color: AppTheme.textBody, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _selectedClientId = val),
                      validator: (value) => value == null ? 'Selecione um cliente' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'SELECIONE A CATEGORIA',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: AppTheme.surface,
                      value: _selectedCategoryId,
                      items: categories.entries.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: const TextStyle(color: AppTheme.textBody, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                      validator: (value) => value == null ? 'Selecione uma categoria' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DETALHES DA COBRANÇA',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      style: const TextStyle(color: AppTheme.textBody, fontSize: 24, fontWeight: FontWeight.bold),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Valor Cobrado (R\$)',
                        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        prefixText: 'R\$ ',
                        prefixStyle: const TextStyle(color: AppTheme.textBody, fontSize: 24, fontWeight: FontWeight.bold),
                        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Digite um valor';
                        if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Valor inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _descController,
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: InputDecoration(
                        labelText: 'Descrição / Observação',
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        hintText: 'Ex: Prestação de serviços de consultoria técnica',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_month, color: AppTheme.primary),
                                SizedBox(width: 12),
                                Text('Data de Vencimento', style: TextStyle(color: AppTheme.textBody)),
                              ],
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitForm(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'EMITIR COBRANÇA',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
