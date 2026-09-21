import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BpoAutomationDashboard extends StatelessWidget {
  const BpoAutomationDashboard({super.key});

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
                  Text(
                    'DASHBOARD DE AUTOMAÇÃO BPO ⚡',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Visão geral do processamento inteligente de documentos fiscais e conciliações',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    SizedBox(width: 6),
                    Text('SISTEMA OCR OPERACIONAL', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cards Superiores com Medidor e Métricas
          Row(
            children: [
              // Gauge / Medidor de Documentos Pendentes
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      const Text('Fila de Processamento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: 0.78,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey.shade200,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const Column(
                            children: [
                              Text('142', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              Text('docs hoje', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('78% concluído', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Volume Processado
              Expanded(
                flex: 1,
                child: _buildMetricTile(
                  title: 'Volume Processado (Mês)',
                  value: '8.459 docs',
                  subtitle: '+14.2% vs mês anterior',
                  icon: Icons.description_outlined,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 16),

              // Acurácia IA
              Expanded(
                flex: 1,
                child: _buildMetricTile(
                  title: 'Acurácia do OCR IA',
                  value: '99,8%',
                  subtitle: 'Sem erros de digitação',
                  icon: Icons.auto_awesome,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),

              // Economia de Tempo
              Expanded(
                flex: 1,
                child: _buildMetricTile(
                  title: 'Economia Estimada',
                  value: '184 horas',
                  subtitle: 'Redução de trabalho manual',
                  icon: Icons.access_time_filled_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Fila Recente de Documentos Lido por OCR IA
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Fila de Lançamentos Recentes pelo OCR IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                    Text('Ver todos (142)', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildQueueRow(
                  filename: 'NFe_20260803_AWS.pdf',
                  company: 'TechSolutions Brasil',
                  amount: currency.format(8500.00),
                  category: 'Infraestrutura TI',
                  status: 'Aprovado IA',
                  statusColor: Colors.green,
                ),
                const Divider(height: 1),
                _buildQueueRow(
                  filename: 'Boleto_Aluguel_Matriz.pdf',
                  company: 'Imobiliária Central',
                  amount: currency.format(12400.00),
                  category: 'Aluguel & Condomínio',
                  status: 'Requer Validação',
                  statusColor: Colors.orange,
                ),
                const Divider(height: 1),
                _buildQueueRow(
                  filename: 'Cupom_Combustivel_Frota.png',
                  company: 'Posto Shell BR',
                  amount: currency.format(350.00),
                  category: 'Frota & Transportes',
                  status: 'Aprovado IA',
                  statusColor: Colors.green,
                ),
                const Divider(height: 1),
                _buildQueueRow(
                  filename: 'NFSe_Consultoria_BPO.pdf',
                  company: 'Grupo Varejo Global',
                  amount: currency.format(45000.00),
                  category: 'Vendas de Serviço',
                  status: 'Enviado ao Omie',
                  statusColor: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.arrow_upward_rounded, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  static Widget _buildQueueRow({
    required String filename,
    required String company,
    required String amount,
    required String category,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF64748B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(filename, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                Text('$company • $category', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
