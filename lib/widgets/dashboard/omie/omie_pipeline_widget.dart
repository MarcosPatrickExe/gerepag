import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';

class OmiePipelineWidget extends StatelessWidget {
  final TransactionsProvider provider;

  const OmiePipelineWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final activeOs = provider.omieOS.where((os) {
      final cab = os['Cabecalho'] ?? os['cabecalho'] ?? {};
      return cab['cEtapa'] != '50';
    }).toList();

    final activeSales = provider.omieOrders.where((p) {
      final cab = p['Cabecalho'] ?? p['cabecalho'] ?? {};
      return cab['cEtapa'] != '50';
    }).toList();
    
    if (activeOs.isEmpty && activeSales.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PIPELINE DE OPERAÇÕES 🚀', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildPipelineRow(context, 'Ordens de Serviço Ativas', activeOs.length, Colors.purpleAccent, Icons.build_circle_outlined, () {
            // Future logic
          }),
          const SizedBox(height: 16),
          _buildPipelineRow(context, 'Pedidos de Venda Abertos', activeSales.length, Colors.cyanAccent, Icons.shopping_cart_outlined, () {
            // Future logic
          }),
        ],
      ),
    );
  }

  Widget _buildPipelineRow(BuildContext context, String label, int count, Color color, IconData icon, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textBody, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
