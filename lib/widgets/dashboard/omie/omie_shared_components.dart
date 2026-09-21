import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/app_theme.dart';
import '../../../providers/transactions_provider.dart';

class RankingCard extends StatelessWidget {
  final String title;
  final dynamic data; // Can be List<dynamic> or Map<String, double>
  final Color color;

  const RankingCard({
    super.key,
    required this.title,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    List<Map<String, dynamic>> items = [];
    if (data is Map) {
      (data as Map).forEach((k, v) => items.add({'label': k.toString(), 'value': v}));
    } else if (data is List) {
      items = List<Map<String, dynamic>>.from(data);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const Center(child: Text('Nenhum dado disponível', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)))
          else
            ...items.take(5).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item['label'] ?? 'Outros', style: const TextStyle(color: AppTheme.textBody, fontSize: 13), overflow: TextOverflow.ellipsis),
                  ),
                  Text(currency.format(item['value']), style: const TextStyle(color: AppTheme.textBody, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

class ExtratoTable extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final Color color;

  const ExtratoTable({
    super.key,
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const Center(child: Text('Nenhum registro encontrado', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length.clamp(0, 10),
              separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05)),
              itemBuilder: (context, index) {
                final item = items[index];
                final date = DateFormat('dd/MM/yyyy').parse(item['data_vencimento'] ?? item['dDtVenc']);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(dateFormat.format(date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item['descricao'] ?? 'Sem descrição', style: const TextStyle(color: AppTheme.textBody, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      Text(currency.format(double.tryParse(item['valor_documento'].toString()) ?? 0.0), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
