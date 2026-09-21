import 'package:flutter/material.dart';

class BpoSmartBatchUpload extends StatefulWidget {
  const BpoSmartBatchUpload({super.key});

  @override
  State<BpoSmartBatchUpload> createState() => _BpoSmartBatchUploadState();
}

class _BpoSmartBatchUploadState extends State<BpoSmartBatchUpload> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  void _simulateBatchUpload() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _uploadProgress = i / 10.0);
    }

    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Lote de 15 documentos enviado para fila de OCR com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

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
                  Text('CENTRO DE UPLOAD INTELIGENTE EM LOTE 📥', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text('Envie múltiplos arquivos (PDF, PNG, JPG, XML) para o OCR e conciliação automática', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _simulateBatchUpload,
                icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                label: const Text('SELECIONAR ARQUIVOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Drop Zone Grande
          InkWell(
            onTap: _simulateBatchUpload,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.upload_file_rounded, color: Color(0xFF2563EB), size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('Arraste e solte seus lotes de notas fiscais aqui', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  const Text('Suporta arquivos PDF, PNG, JPG e XML (Até 50MB por lote)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  if (_isUploading) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 250,
                      child: Column(
                        children: [
                          LinearProgressIndicator(value: _uploadProgress, backgroundColor: Colors.grey.shade200, color: const Color(0xFF2563EB)),
                          const SizedBox(height: 8),
                          Text('${(_uploadProgress * 100).toInt()}% processado...', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Linha do Tempo dos Lotes Recentes (Batch Timeline)
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
                const Text('Lotes Processados Recentes (Batch Timeline)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                _buildBatchTile('Lote #1048 — TechSolutions Brasil', '120/120 Documentos OCR Aprovados', 'Hoje às 10:42', Colors.green, 1.0),
                const Divider(height: 1),
                _buildBatchTile('Lote #1047 — Grupo Varejo Global', '45/45 Conciliados com Omie ERP', 'Hoje às 09:15', Colors.green, 1.0),
                const Divider(height: 1),
                _buildBatchTile('Lote #1046 — Imobiliária Central', '18/20 Processados (2 requerem validação)', 'Ontem às 17:30', Colors.orange, 0.9),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchTile(String title, String status, String time, Color color, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.folder_zip_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                Text('$status • $time', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text('${(progress * 100).toInt()}% Concluído', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
