import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import 'package:intl/intl.dart';
import '../services/realtime_db_service.dart';
import '../providers/user_stats_provider.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  
  final RealtimeDbService _db = RealtimeDbService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getSubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final _subscriptions = snapshot.data ?? [];
        final totalMensal = _subscriptions.fold<double>(0.0, (sum, sub) => sum + (sub['price'] ?? 0.0));
        final totalAnual = totalMensal * 12;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONTROLE DE ASSINATURAS',
              style: TextStyle(color: AppTheme.textBody, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Total Mensal', totalMensal, AppTheme.primary)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('Gasto Anual', totalAnual, AppTheme.expense)),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Serviços Ativos',
                  style: TextStyle(color: AppTheme.textBody, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showAddSubscriptionModal(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('NOVA ASSINATURA'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_subscriptions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.subscriptions_outlined, size: 48, color: AppTheme.textBody.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    const Text('Nenhuma assinatura cadastrada', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Clique em "Nova Assinatura" para começar a controlar seus gastos recorrentes (ex: Netflix, Spotify, Academia).', 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12)
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subscriptions.length,
                itemBuilder: (context, index) {
                  final sub = _subscriptions[index];
                  return _buildSubscriptionCard(sub);
                },
              ),
          ],
        );
      }
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            currency.format(amount),
            style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> sub) {
    final double price = (sub['price'] ?? 0.0) is int ? (sub['price'] as int).toDouble() : (sub['price'] ?? 0.0);
    final double precoAnual = price * 12;
    final int billingDay = sub['billingDay'] ?? 1;
    final String name = sub['name'] ?? 'Assinatura';
    final int iconCodePoint = sub['iconCodePoint'] ?? Icons.subscriptions.codePoint;
    final int colorValue = sub['colorValue'] ?? AppTheme.primary.value;
    
    // Verifica se a cobrança está próxima (nos próximos 5 dias)
    final hoje = DateTime.now().day;
    bool isProximo = (billingDay - hoje) >= 0 && (billingDay - hoje) <= 5;
    if (hoje > billingDay && (30 - hoje + billingDay) <= 5) isProximo = true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(colorValue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              name.toLowerCase().contains('netflix') || name.toLowerCase().contains('video') ? Icons.movie_outlined :
              name.toLowerCase().contains('spotify') || name.toLowerCase().contains('music') ? Icons.music_note_outlined :
              Icons.subscriptions_outlined, 
              color: Color(colorValue), 
              size: 28
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Todo dia $billingDay • Anual: ${currency.format(precoAnual)}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(price),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (isProximo) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Vence Logo', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]
            ],
          ),
          IconButton(
             icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted),
             onPressed: () {
               _db.deleteSubscription(sub['id']);
               Provider.of<UserStatsProvider>(context, listen: false).reportSubscriptionDeleted();
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Assinatura removida! +200 XP por economia 🎯'))
               );
             },
          ),
        ],
      ),
    );
  }

  void _showAddSubscriptionModal(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final dayController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nova Assinatura', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome do Serviço (ex: Netflix)')),
            const SizedBox(height: 12),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Valor Mensal (R\$)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: dayController, decoration: const InputDecoration(labelText: 'Dia do Vencimento'), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameController.text;
                  final price = double.tryParse(priceController.text) ?? 0.0;
                  final day = int.tryParse(dayController.text) ?? 1;
                  
                  if (name.isNotEmpty && price > 0) {
                    _db.addSubscription({
                      'name': name,
                      'price': price,
                      'billingDay': day,
                      'iconCodePoint': Icons.subscriptions.codePoint,
                      'colorValue': Colors.blueAccent.value,
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary, 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('SALVAR ASSINATURA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
