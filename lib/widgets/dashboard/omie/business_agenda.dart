import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/transactions_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../core/app_theme.dart';
import '../../../services/ai_chat_service.dart';
import '../../../screens/upgrade_screen.dart';

class BusinessAgenda extends StatelessWidget {
  final TransactionsProvider provider;

  const BusinessAgenda({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final receiving = provider.omieAccountsReceivable.where((x) => provider.isWithinCurrentFilterDetailed(x)).toList();
    final paying = provider.omieAccountsPayable.where((x) => provider.isWithinCurrentFilterDetailed(x)).toList();

    if (receiving.isEmpty && paying.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AGENDA FINANCEIRA (PRÓXIMOS) 📅',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        ...receiving.take(5).map((item) {
          final client = provider.omieClients[item['codigo_cliente_fornecedor'].toString()] ?? 'Cliente';
          final category = provider.omieCategories[item['codigo_categoria'] ?? item['codigo_categoria_receber'] ?? item['cCodCategor']] ?? 'Receita';
          final uniqueKey = 'receber_${item['codigo_lancamento'] ?? item['nCodLanc'] ?? item['numero_documento'] ?? item['data_vencimento']}_${receiving.indexOf(item)}';

          return Dismissible(
            key: Key(uniqueKey),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              await _quickWhatsAppCobranca(context, item, client);
              return false;
            },
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Cobrança rápida via WhatsApp',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chat_bubble_outline, color: Colors.white),
                ],
              ),
            ),
            child: _buildAgendaTile(
              title: client.split('|').first,
              subtitle: 'DOC: ${item['numero_documento'] ?? '-'} • Vence: ${item['data_vencimento']}',
              category: category,
              amount: double.tryParse(item['valor_documento']?.toString() ?? '0.0') ?? 0.0,
              isIncome: true,
            ),
          );
        }),
        ...paying.take(5).map((item) {
          final supplier = provider.omieClients[item['codigo_cliente_fornecedor'].toString()] ?? 'Fornecedor';
          final category = provider.omieCategories[item['codigo_categoria'] ?? item['cCodCategor']] ?? 'Despesa';
          return _buildAgendaTile(
            title: supplier.split('|').first,
            subtitle: 'DOC: ${item['numero_documento'] ?? '-'} • Vence: ${item['data_vencimento']}',
            category: category,
            amount: double.tryParse(item['valor_documento']?.toString() ?? '0.0') ?? 0.0,
            isIncome: false,
          );
        }),
      ],
    );
  }

  Widget _buildAgendaTile({
    required String title, 
    required String subtitle, 
    required String category,
    required double amount, 
    required bool isIncome
  }) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome ? Icons.keyboard_double_arrow_up : Icons.keyboard_double_arrow_down,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category.toUpperCase(), 
                    style: TextStyle(color: isIncome ? Colors.greenAccent : Colors.amberAccent, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            currency.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _quickWhatsAppCobranca(BuildContext context, dynamic item, String clientName) async {
    final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    if (!subProvider.canUseNegotiation) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Limite de IA Atingido 🚀', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
          content: const Text(
            'Você atingiu o limite de 2 negociações de cobrança gratuitas por mês. Assine o plano Pro para ter IA ilimitada e realizar cobranças com 1 clique!',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ver Planos'),
            ),
          ],
        ),
      );
      return;
    }

    // Mostrar diálogo de progresso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text(
                'Glauber está redigindo...',
                style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Criando mensagem de cobrança inteligente em background.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final aiService = AiChatService();
      final amount = double.tryParse(item['valor_documento']?.toString() ?? '0.0') ?? 0.0;
      final dueDate = item['data_vencimento']?.toString() ?? '--/--/----';
      final description = item['descricao'] ?? item['cDesCategor'] ?? 'Prestação de Serviços';
      final cleanName = clientName.split('|').first;

      final text = await aiService.generateNegotiationProposal(
        contactName: cleanName,
        amount: amount,
        dueDate: dueDate,
        description: description,
        type: 'receber',
      );

      final clientId = item['codigo_cliente_fornecedor']?.toString() ?? '';

      // Salvar registro de cobrança no Firebase
      final txProvider = Provider.of<TransactionsProvider>(context, listen: false);
      await txProvider.saveBillingRecord(
        contactName: cleanName,
        amount: amount,
        dueDate: dueDate,
        description: description,
        whatsappText: text,
        clientId: clientId,
      );

      await subProvider.incrementNegotiationUsage();

      if (context.mounted) {
        Navigator.pop(context); // Fechar diálogo de progresso
      }

      final url = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fechar diálogo de progresso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar cobrança: $e')),
        );
      }
    }
  }
}
