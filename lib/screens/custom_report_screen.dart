import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import '../services/pdf_report_service.dart';

class CustomReportScreen extends StatefulWidget {
  const CustomReportScreen({super.key});

  @override
  State<CustomReportScreen> createState() => _CustomReportScreenState();
}

class _CustomReportScreenState extends State<CustomReportScreen> {
  final _titleController = TextEditingController(text: 'Relatório Executivo Financeiro');
  final _subtitleController = TextEditingController(text: 'Gestão Inteligente');
  
  bool _showKpis = true;
  bool _showAging = true;
  bool _showTaxes = true;
  bool _showNotes = true;
  bool _showTopExpenses = true;
  bool _showScore = true;
  bool _showTopClientsSuppliers = true;
  bool _showMoMComparison = true;
  bool _showBankBalances = true;
  bool _showSentinelaReport = true;
  bool _showRunwayStats = true;
  bool _showSparkline = true;
  
  String _selectedColorHex = '#2563EB';
  final _consultantNotesController = TextEditingController();
  
  String? _logoBase64;
  String? _logoName;
  bool _isGenerating = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        _logoBase64 = base64String;
        _logoName = image.name;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo carregada com sucesso! 💼'),
            backgroundColor: AppTheme.income,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar imagem: $e'),
            backgroundColor: AppTheme.expense,
          ),
        );
      }
    }
  }

  void _removeLogo() {
    setState(() {
      _logoBase64 = null;
      _logoName = null;
    });
  }

  Future<void> _generateReport() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, defina um título para o relatório.'),
          backgroundColor: AppTheme.expense,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final provider = Provider.of<TransactionsProvider>(context, listen: false);
      await PdfReportService.generateCustomExecutiveReport(
        provider,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        showKpis: _showKpis,
        showAging: _showAging,
        showTaxes: _showTaxes,
        showNotes: _showNotes,
        showTopExpenses: _showTopExpenses,
        showScore: _showScore,
        showTopClientsSuppliers: _showTopClientsSuppliers,
        showMoMComparison: _showMoMComparison,
        showBankBalances: _showBankBalances,
        showSentinelaReport: _showSentinelaReport,
        showRunwayStats: _showRunwayStats,
        showSparkline: _showSparkline,
        primaryColorHex: _selectedColorHex,
        consultantNotes: _consultantNotesController.text.trim(),
        logoBase64: _logoBase64,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: AppTheme.expense,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _consultantNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Relatório White-Label', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cartão informativo BPO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business_center, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Gerador de PDF Personalizado',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Adicione a sua própria identidade visual e a marca da sua contabilidade ou BPO Financeiro. Escolha quais seções farão parte do documento antes de gerar o PDF para seus clientes.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dados de Personalização
                const Text(
                  'IDENTIDADE DO RELATÓRIO',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: AppTheme.inputDecoration('Título do Relatório', Icons.title),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _subtitleController,
                          decoration: AppTheme.inputDecoration('Nome do Escritório / Subtítulo', Icons.edit_note),
                        ),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'COR DE DESTAQUE DA MARCA',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildColorOption('#2563EB', const Color(0xFF2563EB), 'Azul'),
                            _buildColorOption('#10B981', const Color(0xFF10B981), 'Verde'),
                            _buildColorOption('#F59E0B', const Color(0xFFF59E0B), 'Laranja'),
                            _buildColorOption('#1E293B', const Color(0xFF1E293B), 'Grafite'),
                            _buildColorOption('#EF4444', const Color(0xFFEF4444), 'Vermelho'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Parecer Técnico
                const Text(
                  'PARECER E ANÁLISE DO CONSULTOR',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: TextField(
                      controller: _consultantNotesController,
                      maxLines: 3,
                      decoration: AppTheme.inputDecoration(
                        'Recomendações e análises estratégicas para o cliente final...',
                        Icons.comment_bank_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Seleção de Seções
                const Text(
                  'SEÇÕES DO DOCUMENTO',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Sumário de Performance (KPIs)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Receita, Despesa e Lucro Líquido do DRE', style: TextStyle(fontSize: 12)),
                          value: _showKpis,
                          onChanged: (val) => setState(() => _showKpis = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Dívida por Idade (Aging)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Visão de atrasos de faturas de clientes', style: TextStyle(fontSize: 12)),
                          value: _showAging,
                          onChanged: (val) => setState(() => _showAging = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Impostos & Recorrência (MRR)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Cálculo de retenções e contratos ativos', style: TextStyle(fontSize: 12)),
                          value: _showTaxes,
                          onChanged: (val) => setState(() => _showTaxes = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Nota Estratégica Automática', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Análise rápida e percentual de lucratividade', style: TextStyle(fontSize: 12)),
                          value: _showNotes,
                          onChanged: (val) => setState(() => _showNotes = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Maiores Despesas do Período', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Tabela com as 5 principais categorias de custos', style: TextStyle(fontSize: 12)),
                          value: _showTopExpenses,
                          onChanged: (val) => setState(() => _showTopExpenses = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Score de Saúde Financeira', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Exibir nota geral e status de caixa do consultor', style: TextStyle(fontSize: 12)),
                          value: _showScore,
                          onChanged: (val) => setState(() => _showScore = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Ranking de Clientes e Fornecedores', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Tabelas com maiores volumes de entradas e saídas', style: TextStyle(fontSize: 12)),
                          value: _showTopClientsSuppliers,
                          onChanged: (val) => setState(() => _showTopClientsSuppliers = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Comparativo Mês a Mês', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Diferença de DRE contra o mês anterior', style: TextStyle(fontSize: 12)),
                          value: _showMoMComparison,
                          onChanged: (val) => setState(() => _showMoMComparison = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Saldos e Contas Bancárias', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Listagem consolidada das contas ativas', style: TextStyle(fontSize: 12)),
                          value: _showBankBalances,
                          onChanged: (val) => setState(() => _showBankBalances = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Varredura Sentinela Guard', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Exibir relatório de desvios e conformidade do caixa', style: TextStyle(fontSize: 12)),
                          value: _showSentinelaReport,
                          onChanged: (val) => setState(() => _showSentinelaReport = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Fôlego Financeiro & Runway', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Meses de sobrevivência estimada da empresa', style: TextStyle(fontSize: 12)),
                          value: _showRunwayStats,
                          onChanged: (val) => setState(() => _showRunwayStats = val),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          activeColor: AppTheme.primary,
                          title: const Text('Gráfico de Tendência (Sparkline)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Linha visual do saldo ao longo dos últimos 7 dias', style: TextStyle(fontSize: 12)),
                          value: _showSparkline,
                          onChanged: (val) => setState(() => _showSparkline = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Upload da Logomarca
                const Text(
                  'LOGOMARCA DO ESCRITÓRIO',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _logoBase64 != null
                        ? Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.memory(
                                    base64Decode(_logoBase64!),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Logomarca ativa',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Arquivo: ${_logoName ?? "Imagem"}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.expense),
                                onPressed: _removeLogo,
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: _pickLogo,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  style: BorderStyle.none, // We can use custom dashed border via custom shape
                                ),
                                borderRadius: BorderRadius.circular(16),
                                color: AppTheme.primary.withValues(alpha: 0.02),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 40, color: AppTheme.primary.withValues(alpha: 0.8)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Carregar Logomarca Corporativa',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Dimensão ideal: PNG/JPG quadrado ou retangular',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 36),

                // Botão de Geração
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateReport,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                    label: Text(
                      _isGenerating ? 'GERANDO RELATÓRIO...' : 'GERAR PDF WHITE-LABEL 📄',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(String hex, Color color, String name) {
    final bool isSelected = _selectedColorHex == hex;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Tooltip(
        message: name,
        child: InkWell(
          onTap: () => setState(() => _selectedColorHex = hex),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected ? [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)
              ] : null,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
          ),
        ),
      ),
    );
  }
}
