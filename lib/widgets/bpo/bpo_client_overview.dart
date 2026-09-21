import 'package:flutter/material.dart';

class BpoClientOverview extends StatelessWidget {
  const BpoClientOverview({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Text('GESTÃO DE CLIENTES E INTEGRAÇÕES BPO 🏢', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text('Visão consolidada de todas as carteiras de clientes atendidas pelo escritório de BPO', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_business_rounded, color: Colors.white, size: 18),
                label: const Text('NOVO CLIENTE BPO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Métricas Consolidadas da Carteira
          Row(
            children: [
              Expanded(child: _buildTile('Clientes Ativos', '24 empresas', '100% integrados', Icons.business_rounded, const Color(0xFF2563EB))),
              const SizedBox(width: 16),
              Expanded(child: _buildTile('Volume Mensal', '1.492 notas', 'Média de 62/cliente', Icons.receipt_long_rounded, const Color(0xFF10B981))),
              const SizedBox(width: 16),
              Expanded(child: _buildTile('Automação Global', '88%', 'Processamento via IA', Icons.auto_awesome, const Color(0xFF8B5CF6))),
            ],
          ),

          const SizedBox(height: 24),

          // Tabela da Carteira de Clientes
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
                const Text('Carteira de Clientes BPO (24 Empresas)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                _buildClientRow('TechSolutions Brasil Ltda', 'CNPJ 23.412.879/0001-54', '142 notas/mês', '98% IA', 'Omie Conectado', Colors.green),
                const Divider(height: 1),
                _buildClientRow('Grupo Varejo Global S/A', 'CNPJ 11.902.433/0001-90', '420 notas/mês', '85% IA', 'Omie Conectado', Colors.green),
                const Divider(height: 1),
                _buildClientRow('Imobiliária Central SP', 'CNPJ 04.112.500/0001-12', '95 notas/mês', '76% IA', 'Requer Sincronização', Colors.orange),
                const Divider(height: 1),
                _buildClientRow('Serviços Médicos Integrados', 'CNPJ 48.910.222/0001-08', '210 notas/mês', '92% IA', 'Omie Conectado', Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(String title, String val, String sub, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildClientRow(String name, String cnpj, String volume, String auto, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFFF1F5F9), child: Text(name.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                Text('$cnpj • $volume', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(auto, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(width: 12),
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
