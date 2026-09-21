import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/credit_card_model.dart';
import '../providers/transactions_provider.dart';
import '../services/realtime_db_service.dart';
import 'package:intl/intl.dart';

class CreditCardsScreen extends StatefulWidget {
  const CreditCardsScreen({super.key});

  @override
  State<CreditCardsScreen> createState() => _CreditCardsScreenState();
}

class _CreditCardsScreenState extends State<CreditCardsScreen> {
  final _db = RealtimeDbService();
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  void _showAddCardModal() {
    final nameController = TextEditingController();
    final limitController = TextEditingController();
    final closingDayController = TextEditingController();
    final dueDayController = TextEditingController();
    String selectedColor = '#8B0000';

    final colors = ['#8B0000', '#1E3A8A', '#006400', '#DAA520', '#4B0082', '#333333'];

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Novo Cartão de Crédito', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController, 
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(labelText: 'Nome (ex: Nubank, Visa Black)')
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: limitController, 
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(labelText: 'Limite Total (R\$)'), 
                      keyboardType: TextInputType.number
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: closingDayController, 
                            style: const TextStyle(color: AppTheme.textBody),
                            decoration: const InputDecoration(labelText: 'Dia de Fechamento', labelStyle: TextStyle(color: AppTheme.textMuted)), 
                            keyboardType: TextInputType.number
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: dueDayController, 
                            style: const TextStyle(color: AppTheme.textBody),
                            decoration: const InputDecoration(labelText: 'Dia de Vencimento', labelStyle: TextStyle(color: AppTheme.textMuted)), 
                            keyboardType: TextInputType.number
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Cor do Cartão', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
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
                          final limit = double.tryParse(limitController.text.replaceAll(',', '.')) ?? 0.0;
                          final closing = int.tryParse(closingDayController.text) ?? 1;
                          final due = int.tryParse(dueDayController.text) ?? 10;
                          
                          if (name.isNotEmpty) {
                            await _db.addCreditCard(CreditCardModel(
                              id: '',
                              name: name,
                              limit: limit,
                              closingDay: closing,
                              dueDay: due,
                              colorHex: selectedColor,
                            ));
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent, 
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        child: const Text('SALVAR CARTÃO', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showEditCardModal(CreditCardModel card) {
    final nameController = TextEditingController(text: card.name);
    final limitController = TextEditingController(text: card.limit.toString());
    final closingDayController = TextEditingController(text: card.closingDay.toString());
    final dueDayController = TextEditingController(text: card.dueDay.toString());
    String selectedColor = card.colorHex;

    final colors = ['#8B0000', '#1E3A8A', '#006400', '#DAA520', '#4B0082', '#333333'];

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Editar Cartão', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController, 
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(labelText: 'Nome', labelStyle: TextStyle(color: AppTheme.textMuted))
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: limitController, 
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(labelText: 'Limite (R\$)', labelStyle: TextStyle(color: AppTheme.textMuted)), 
                      keyboardType: TextInputType.number
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: closingDayController, 
                            style: const TextStyle(color: AppTheme.textBody),
                            decoration: const InputDecoration(labelText: 'Dia Fechamento', labelStyle: TextStyle(color: AppTheme.textMuted)), 
                            keyboardType: TextInputType.number
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: dueDayController, 
                            style: const TextStyle(color: AppTheme.textBody),
                            decoration: const InputDecoration(labelText: 'Dia Vencimento', labelStyle: TextStyle(color: AppTheme.textMuted)), 
                            keyboardType: TextInputType.number
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Cor do Cartão', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
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
                          final limit = double.tryParse(limitController.text.replaceAll(',', '.')) ?? 0.0;
                          final closing = int.tryParse(closingDayController.text) ?? 1;
                          final due = int.tryParse(dueDayController.text) ?? 10;
                          
                          if (name.isNotEmpty) {
                            await _db.updateCreditCard(card.id, CreditCardModel(
                              id: card.id,
                              name: name,
                              limit: limit,
                              closingDay: closing,
                              dueDay: due,
                              colorHex: selectedColor,
                            ).toMap());
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent, 
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        child: const Text('ATUALIZAR CARTÃO', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showPayInvoiceModal(CreditCardModel card, double amount) {
    final provider = Provider.of<TransactionsProvider>(context, listen: false);
    final wallets = provider.wallets;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pagar Fatura', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textBody)),
              const SizedBox(height: 8),
              Text('Valor: ${currency.format(amount)}', style: const TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 24),
              const Text('Selecione a conta para débito:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              if (wallets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nenhuma conta cadastrada para pagar.', style: TextStyle(color: Colors.redAccent)),
                )
              else
                ...wallets.map((w) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Color(int.parse(w.colorHex.replaceAll('#', '0xFF'))).withValues(alpha: 0.2),
                    child: const Icon(Icons.account_balance_wallet, color: AppTheme.textBody, size: 18),
                  ),
                  title: Text(w.name, style: const TextStyle(color: AppTheme.textBody)),
                  subtitle: Text('Saldo: ${currency.format(provider.getWalletBalance(w.id))}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  onTap: () async {
                    await provider.payCreditCardInvoice(card.id, w.id, amount);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fatura do ${card.name} paga com sucesso!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                )),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionsProvider>(
      builder: (context, provider, child) {
        final cards = provider.creditCards;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Resumo de Crédito', style: TextStyle(color: AppTheme.textBody, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _showAddCardModal,
                  icon: const Icon(Icons.add_card, color: Colors.blueAccent),
                  tooltip: 'Adicionar Cartão',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (cards.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Nenhum cartão cadastrado.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            else
              ...cards.map((card) {
                final colorObj = Color(int.parse(card.colorHex.replaceAll('#', '0xFF')));
                
                final now = DateTime.now();
                final invoiceTotal = provider.transactions
                    .where((t) => t.creditCardId == card.id && t.date.month == now.month && t.date.year == now.year)
                    .fold(0.0, (sum, t) => sum + t.amount);
                
                final availableLimit = card.limit - invoiceTotal;
                
                // Lógica de Alerta de Vencimento
                final today = now.day;
                final isOverdue = today > card.dueDay;
                final isNearDue = (card.dueDay - today >= 0) && (card.dueDay - today <= 3);
                final alertColor = isOverdue ? Colors.redAccent : (isNearDue ? Colors.amberAccent : Colors.white70);

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorObj, colorObj.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: colorObj.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(card.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const Icon(Icons.credit_card, color: Colors.white70),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Fatura Atual', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(currency.format(invoiceTotal), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Limite Disponível', style: TextStyle(color: Colors.white70, fontSize: 10)),
                              Text(currency.format(availableLimit), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(isOverdue ? 'Venceu dia' : (isNearDue ? 'Vence em breve' : 'Vence dia'), 
                                style: TextStyle(color: alertColor, fontSize: 10, fontWeight: isNearDue || isOverdue ? FontWeight.bold : FontWeight.normal)),
                              Text(card.dueDay.toString(), style: TextStyle(color: isOverdue || isNearDue ? alertColor : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (invoiceTotal / (card.limit == 0 ? 1 : card.limit)).clamp(0.0, 1.0),
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(invoiceTotal > card.limit * 0.9 ? Colors.redAccent : Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (invoiceTotal > 0)
                            ElevatedButton(
                              onPressed: () => _showPayInvoiceModal(card, invoiceTotal),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('PAGAR FATURA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.textMuted, size: 20),
                            onPressed: () => _showEditCardModal(card),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppTheme.surface,
                                  title: const Text('Excluir Cartão?', style: TextStyle(color: AppTheme.textBody)),
                                  content: const Text('Isso não excluirá as transações já realizadas com ele.', style: TextStyle(color: AppTheme.textMuted)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('EXCLUIR', style: TextStyle(color: Colors.redAccent))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _db.deleteCreditCard(card.id);
                              }
                            },
                          ),
                        ],
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
