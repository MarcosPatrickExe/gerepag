import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../services/ocr_service.dart';

class DocumentVaultScreen extends StatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  final OcrService _ocrService = OcrService();
  List<File> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    final directory = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${directory.path}/vault');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    final List<FileSystemEntity> entities = vaultDir.listSync();
    setState(() {
      _documents = entities.whereType<File>().toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text('Pasta Digital de Notas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _documents.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisExtent: 220,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final file = _documents[index];
                final name = file.path.split('/').last;
                final date = file.lastModifiedSync();
                final isPdf = name.toLowerCase().endsWith('.pdf');

                return GestureDetector(
                  onTap: () => _showDocumentOptions(file),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Icon(
                              isPdf ? Icons.picture_as_pdf : Icons.image,
                              size: 64,
                              color: isPdf ? Colors.redAccent : Colors.blueAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textBody, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(date),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: AppTheme.textBody.withValues(alpha: 0.1)),
          const SizedBox(height: 24),
          const Text('Sua pasta está vazia', style: TextStyle(color: AppTheme.textBody, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Arraste notas fiscais para a Home para salvá-las aqui.', style: TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  void _showDocumentOptions(File file) async {
    final name = file.path.split('/').last;
    final isPdf = name.toLowerCase().endsWith('.pdf');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return FutureBuilder<OcrResult?>(
                  future: isPdf ? Future.value(null) : _ocrService.processImage(file.path),
                  builder: (context, snapshot) {
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;
                    final ocrResult = snapshot.data;
                    
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: isPdf ? Colors.redAccent : Colors.blueAccent, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textBody), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(DateFormat('dd/MM/yyyy HH:mm').format(file.lastModifiedSync()), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppTheme.expense),
                                onPressed: () async {
                                  await file.delete();
                                  Navigator.pop(context);
                                  _loadDocuments();
                                },
                              )
                            ],
                          ),
                          const Divider(height: 40, color: Colors.white10),
                          
                          if (isLoading)
                            const Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(color: AppTheme.primary),
                                  SizedBox(height: 16),
                                  Text('Processando OCR...', style: TextStyle(color: AppTheme.textMuted)),
                                ],
                              ),
                            )
                          else if (isPdf)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text('Visualização de PDF (OCR indisponível offline)', style: TextStyle(color: AppTheme.textMuted)),
                              ),
                            )
                          else if (ocrResult != null) ...[
                            if (ocrResult.isBoleto) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.payment, color: Colors.orangeAccent, size: 20),
                                        SizedBox(width: 8),
                                        Text('BOLETO DETECTADO', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SelectableText(
                                      ocrResult.boletoKey ?? '',
                                      style: const TextStyle(color: AppTheme.textBody, fontFamily: 'monospace', fontSize: 13),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: ocrResult.boletoKey ?? ''));
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Linha digitável copiada! 📋')));
                                            },
                                            icon: const Icon(Icons.copy, size: 16, color: Colors.black),
                                            label: const Text('COPIAR CÓDIGO', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, elevation: 0),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (ocrResult.isDanfe) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.purpleAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.receipt_long, color: Colors.purpleAccent, size: 20),
                                        SizedBox(width: 8),
                                        Text('NOTA FISCAL (DANFE)', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text('Emissor: ${ocrResult.danfeIssuer ?? "Desconhecido"}', style: const TextStyle(color: AppTheme.textBody, fontSize: 13)),
                                    if (ocrResult.amount != null)
                                      Text('Valor Total: R\$ ${ocrResult.amount!.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            const Text('CONTEÚDO EXTRAÍDO', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 12),
                            Text('Estabelecimento: ${ocrResult.restaurant ?? "Desconhecido"}', style: const TextStyle(color: AppTheme.textBody)),
                            if (ocrResult.amount != null)
                              Text('Valor Detectado: R\$ ${ocrResult.amount!.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
                            Text('Data Detectada: ${DateFormat('dd/MM/yyyy').format(ocrResult.date ?? DateTime.now())}', style: const TextStyle(color: AppTheme.textBody)),
                          ] else
                            const Center(child: Text('Nenhum dado extraído do documento.', style: TextStyle(color: AppTheme.textMuted))),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
