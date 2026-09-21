import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BpoArchiveHistory extends StatelessWidget {
  const BpoArchiveHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HISTÓRICO DE LANÇAMENTOS ARCHIVE 🗄️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text('Auditoria fiscal completa e consulta histórica de comprovantes e documentos vinculados', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('EXPORTAR RELATÓRIO (CSV)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabela do Histórico
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auditoria dos Últimos Lançamentos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                _buildRow('NFe #28471', 'TechSolutions Brasil', '15/08/2026', currency.format(8500.00), 'Sincronizado Omie', Colors.green),
                const Divider(height: 1),
                _buildRow('Boleto #1092', 'Imobiliária Central', '10/08/2026', currency.format(12400.00), 'Auditado BPO', Colors.blue),
                const Divider(height: 1),
                _buildRow('Cupom #8831', 'Posto Shell BR', '02/08/2026', currency.format(350.00), 'Aprovado IA', Colors.green),
                const Divider(height: 1),
                _buildRow('NFSe #9920', 'Grupo Varejo Global', '01/08/2026', currency.format(45000.00), 'Sincronizado Omie', Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String code, String client, String date, String amount, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.archive_outlined, color: Color(0xFF64748B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$code • $client', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                Text('Data Vencimento: $date', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
