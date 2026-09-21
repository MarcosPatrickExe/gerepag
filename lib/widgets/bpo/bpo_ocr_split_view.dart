import 'package:flutter/material.dart';

class BpoOcrSplitView extends StatefulWidget {
  const BpoOcrSplitView({super.key});

  @override
  State<BpoOcrSplitView> createState() => _BpoOcrSplitViewState();
}

class _BpoOcrSplitViewState extends State<BpoOcrSplitView> {
  final TextEditingController _supplierController = TextEditingController(text: 'Amazon Web Services Brasil Ltda');
  final TextEditingController _cnpjController = TextEditingController(text: '23.412.879/0001-54');
  final TextEditingController _amountController = TextEditingController(text: '8500.00');
  final TextEditingController _dueDateController = TextEditingController(text: '15/08/2026');
  final TextEditingController _categoryController = TextEditingController(text: '2.01.01 — Infraestrutura & Cloud');
  final TextEditingController _barcodeController = TextEditingController(text: '34191.79001 01043.510047 91020.150008 5 98120000850000');

  bool _isApproved = false;

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
                  Text('VERIFICAÇÃO OCR — SPLIT VIEW 📄', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text('Conferência em tela dividida: documento original vs dados extraídos pela inteligência artificial', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('Documento: Invoice_NF-e_28471.pdf', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Layout Split Screen (Esquerda: PDF / Direita: Formulário)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lado Esquerdo: Simulador de PDF da Nota Fiscal com Bounding Boxes
              Expanded(
                flex: 1,
                child: Container(
                  height: 600,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 20),
                              SizedBox(width: 8),
                              Text('Documento PDF Original', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          IconButton(icon: const Icon(Icons.zoom_in_rounded, size: 18), onPressed: () {}),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Stack(
                            children: [
                              // Layout Simulado da Nota Fiscal
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('DANFE - NOTA FISCAL ELETRÔNICA DE SERVIÇOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  Divider(),
                                  SizedBox(height: 10),
                                  Text('PRESTADOR DE SERVIÇOS:', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                  Text('Amazon Web Services Brasil Ltda - CNPJ 23.412.879/0001-54', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 20),
                                  Text('DISCRIMINAÇÃO DOS SERVIÇOS:', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                  Text('Serviços de Computação em Nuvem AWS - Período Julho/2026\nInstâncias EC2, S3 Storage e RDS Cloud.', style: TextStyle(fontSize: 10)),
                                  Spacer(),
                                  Text('VALOR TOTAL DA NOTA FISCAL: R\$ 8.500,00', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                  Text('VENCIMENTO: 15/08/2026', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),

                              // Bounding Box 1 (Prestador - Verde Neon)
                              Positioned(
                                top: 35,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  ),
                                ),
                              ),

                              // Bounding Box 2 (Valor & Vencimento - Verde Neon)
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 45,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Lado Direito: Formulário Extraído pela IA
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Dados Extraídos pela IA (Glauber OCR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 16),
                              SizedBox(width: 4),
                              Text('99,8% Acurácia', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildField('Razão Social do Fornecedor', _supplierController),
                      _buildField('CNPJ do Fornecedor', _cnpjController),
                      Row(
                        children: [
                          Expanded(child: _buildField('Valor da Nota (R\$)', _amountController)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField('Data de Vencimento', _dueDateController)),
                        ],
                      ),
                      _buildField('Categoria de Lançamento Omie', _categoryController),
                      _buildField('Linha Digitável / Código de Barras', _barcodeController),

                      const SizedBox(height: 20),

                      // Botões de Ação
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _isApproved = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ Lançamento aprovado e sincronizado com o Omie ERP!'), backgroundColor: Colors.green),
                            );
                          },
                          icon: Icon(_isApproved ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, color: Colors.white),
                          label: Text(_isApproved ? 'LANÇADO NO OMIE ERP ✅' : 'CONFIRMAR & SALVAR NO OMIE', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isApproved ? Colors.green : const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
            ),
          ),
        ],
      ),
    );
  }
}
