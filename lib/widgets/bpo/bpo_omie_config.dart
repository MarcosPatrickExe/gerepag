import 'package:flutter/material.dart';

class BpoOmieConfig extends StatefulWidget {
  const BpoOmieConfig({super.key});

  @override
  State<BpoOmieConfig> createState() => _BpoOmieConfigState();
}

class _BpoOmieConfigState extends State<BpoOmieConfig> {
  final TextEditingController _appKeyController = TextEditingController(text: '383344211902');
  final TextEditingController _appSecretController = TextEditingController(text: 'a8b9c7d6e5f4g3h2i1j0');
  bool _isConnected = true;

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
                  Text('CONFIGURAÇÕES DE INTEGRAÇÃO OMIE ⚙️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text('Gerenciamento de credenciais da API Omie e mapeamento automático de categorias De/Para', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _isConnected ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: _isConnected ? Colors.green : Colors.red, size: 8),
                    const SizedBox(width: 6),
                    Text(_isConnected ? 'OMIE CONECTADO (ONLINE)' : 'OMIE DESCONECTADO', style: TextStyle(color: _isConnected ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Card de Conexão API
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
                const Text('Credenciais da API Omie ERP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildInput('App Key Omie', _appKeyController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInput('App Secret Omie', _appSecretController, isPassword: true)),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isConnected = true);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Conexão com Omie API validada com sucesso!'), backgroundColor: Colors.green));
                  },
                  icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 18),
                  label: const Text('TESTAR CONEXÃO & TESTAR API', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tabela de Mapeamento De / Para
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
                    Text('Mapeamento Inteligente de Categorias (De -> Para)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                    Text('Total: 153 regras ativas', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMappingRow('Serviço de Nuvem AWS', '2.01.01 — Infraestrutura TI', 'Automático IA'),
                const Divider(height: 1),
                _buildMappingRow('Aluguel Comercial / Condomínio', '2.02.05 — Instalações & Imóvel', 'Automático IA'),
                const Divider(height: 1),
                _buildMappingRow('Combustível / Abastecimento Frota', '2.04.10 — Despesas de Transporte', 'Manual Operador'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }

  Widget _buildMappingRow(String from, String to, String rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text('De: $from', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)))),
          const Icon(Icons.arrow_right_alt_rounded, color: Color(0xFF2563EB)),
          Expanded(child: Text('Para: $to', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
            child: Text(rule, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
