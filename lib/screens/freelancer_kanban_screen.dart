import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../services/realtime_db_service.dart';
import '../services/ai_chat_service.dart';
import '../providers/transactions_provider.dart';
import '../models/transaction_model.dart';
import 'whatsapp_cobranca_screen.dart';
import 'proposal_generator_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FreelancerKanbanScreen extends StatefulWidget {
  const FreelancerKanbanScreen({super.key});

  @override
  State<FreelancerKanbanScreen> createState() => _FreelancerKanbanScreenState();
}

class _FreelancerKanbanScreenState extends State<FreelancerKanbanScreen> with SingleTickerProviderStateMixin {
  final _realtimeService = RealtimeDbService();
  final _aiChatService = AiChatService();
  late TabController _tabController;
  int _selectedColumnIndex = 0;
  String _pixKey = '';

  final List<Map<String, String>> _stages = [
    {'id': 'todo', 'name': 'Pendente 📝', 'color': '0xFF3B82F6'},
    {'id': 'in_progress', 'name': 'Em Andamento ⚙️', 'color': '0xFFF59E0B'},
    {'id': 'billed', 'name': 'Cobrado 💬', 'color': '0xFF10B981'},
    {'id': 'paid', 'name': 'Pago ✅', 'color': '0xFF8B5CF6'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _stages.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedColumnIndex = _tabController.index;
      });
    });
    _loadPixKey();
  }

  void _loadPixKey() async {
    try {
      _realtimeService.getPixKey().listen((key) {
        if (mounted) {
          setState(() {
            _pixKey = key;
          });
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Auxiliar para calcular dias em atraso
  String? _calculateOverdueDays(String dueDateStr) {
    try {
      final DateFormat format = DateFormat('dd/MM/yyyy');
      final DateTime dueDate = format.parse(dueDateStr);
      final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (dueDate.isBefore(today)) {
        final difference = today.difference(dueDate).inDays;
        return 'Atrasado há $difference ${difference == 1 ? 'dia' : 'dias'}';
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool isMobile = mediaQuery.size.width < 750;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _realtimeService.getLocalServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        final allServices = snapshot.data ?? [];

        // Agrupar serviços por status e calcular "Dinheiro na Mesa"
        final Map<String, List<Map<String, dynamic>>> servicesByStage = {
          'todo': [],
          'in_progress': [],
          'billed': [],
          'paid': [],
        };

        final Map<String, double> stageTotals = {
          'todo': 0.0,
          'in_progress': 0.0,
          'billed': 0.0,
          'paid': 0.0,
        };

        for (var item in allServices) {
          final status = item['status'] ?? 'todo';
          if (servicesByStage.containsKey(status)) {
            servicesByStage[status]!.add(item);
            final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
            stageTotals[status] = stageTotals[status]! + amount;
          }
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text(
              'Pipeline & Kanban 📋',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textBody),
            actions: [
              IconButton(
                icon: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF10B981)),
                tooltip: 'Gerador de Orçamento ⚡',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProposalGeneratorScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
                tooltip: 'Simulador de Impostos MEI',
                onPressed: () => _showMEITaxCalculatorDialog(context, allServices),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primary),
                tooltip: 'Exportar Extrato PDF',
                onPressed: () => _exportPipelineToPdf(allServices),
              ),
              IconButton(
                icon: const Icon(Icons.vpn_key_rounded, color: AppTheme.primary),
                tooltip: 'Configurar Chave Pix',
                onPressed: () => _showPixConfigDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary),
                tooltip: 'Novo Serviço',
                onPressed: () => _showServiceFormDialog(context),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPipelineHeader(stageTotals),
              const SizedBox(height: 12),
              _buildPipelineFunnel(stageTotals),
              const SizedBox(height: 12),
              _buildBiDashboard(allServices),
              const SizedBox(height: 16),
              Expanded(
                child: isMobile
                    ? _buildMobileKanban(servicesByStage)
                    : _buildDesktopKanban(servicesByStage),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPipelineFunnel(Map<String, double> totals) {
    final double todo = totals['todo'] ?? 0.0;
    final double progress = totals['in_progress'] ?? 0.0;
    final double billed = totals['billed'] ?? 0.0;
    final double paid = totals['paid'] ?? 0.0;
    final double total = todo + progress + billed + paid;

    final double conversionRate = total > 0 ? (paid / total) * 100 : 0.0;

    // Frações para a barra de progresso
    final double todoShare = total > 0 ? todo / total : 0.0;
    final double progressShare = total > 0 ? progress / total : 0.0;
    final double billedShare = total > 0 ? billed / total : 0.0;
    final double paidShare = total > 0 ? paid / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Taxa de Conversão Comercial 📈',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${conversionRate.toStringAsFixed(1)}% Fechado',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Barra Segmentada
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                width: double.infinity,
                child: total == 0
                    ? Container(color: Colors.white10)
                    : Row(
                        children: [
                          if (todoShare > 0)
                            Expanded(
                              flex: (todoShare * 100).round(),
                              child: Container(color: const Color(0xFF3B82F6)),
                            ),
                          if (progressShare > 0)
                            Expanded(
                              flex: (progressShare * 100).round(),
                              child: Container(color: const Color(0xFFF59E0B)),
                            ),
                          if (billedShare > 0)
                            Expanded(
                              flex: (billedShare * 100).round(),
                              child: Container(color: const Color(0xFF10B981)),
                            ),
                          if (paidShare > 0)
                            Expanded(
                              flex: (paidShare * 100).round(),
                              child: Container(color: const Color(0xFF8B5CF6)),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Legenda compacta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFunnelLegendItem('Pendente', const Color(0xFF3B82F6), todoShare * 100),
                _buildFunnelLegendItem('Progresso', const Color(0xFFF59E0B), progressShare * 100),
                _buildFunnelLegendItem('Cobrado', const Color(0xFF10B981), billedShare * 100),
                _buildFunnelLegendItem('Pago', const Color(0xFF8B5CF6), paidShare * 100),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelLegendItem(String label, Color color, double percent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label (${percent.toStringAsFixed(0)}%)',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
        ),
      ],
    );
  }

  // Cabeçalho Dinheiro na Mesa
  Widget _buildPipelineHeader(Map<String, double> totals) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: _stages.map((stage) {
          final id = stage['id']!;
          final color = Color(int.parse(stage['color']!));
          final double totalValue = totals[id] ?? 0.0;

          return Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage['name']!.toUpperCase(),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(totalValue),
                      style: const TextStyle(color: AppTheme.textBody, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Layout Mobile (TabBar)
  Widget _buildMobileKanban(Map<String, List<Map<String, dynamic>>> servicesByStage) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelColor: AppTheme.textMuted,
            labelColor: AppTheme.primary,
            tabs: _stages.map((stage) {
              final count = servicesByStage[stage['id']]?.length ?? 0;
              return Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('${stage['name']} ($count)'),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _stages.map((stage) {
              final list = servicesByStage[stage['id']!] ?? [];
              return _buildStageColumnContent(stage['id']!, list);
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Layout Desktop (Colunas Lado a Lado)
  Widget _buildDesktopKanban(Map<String, List<Map<String, dynamic>>> servicesByStage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _stages.map((stage) {
          final id = stage['id']!;
          final list = servicesByStage[id] ?? [];
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stage['name']!,
                        style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${list.length}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Colors.white10),
                  Expanded(child: _buildStageColumnContent(id, list)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Conteúdo de uma Coluna do Kanban
  Widget _buildStageColumnContent(String stageId, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_turned_in_outlined, size: 40, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 12),
              Text(
                'Sem itens nesta etapa',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildServiceCard(item);
      },
    );
  }

  // Cartão de Serviço do Kanban
  Widget _buildServiceCard(Map<String, dynamic> item) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final String id = item['id'] ?? '';
    final String clientName = item['clientName'] ?? 'Cliente Avulso';
    final String desc = item['description'] ?? 'Serviço sem descrição';
    final double amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
    final double cost = double.tryParse(item['cost']?.toString() ?? '0') ?? 0.0;
    final double profit = amount - cost;
    final double margin = amount > 0 ? (profit / amount) * 100 : 0.0;
    final String dueDate = item['dueDate'] ?? '';
    final String status = item['status'] ?? 'todo';
    final bool isRecurring = item['isRecurring'] == true;

    final overdueMessage = _calculateOverdueDays(dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: overdueMessage != null && status != 'paid'
              ? Colors.redAccent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showServiceFormDialog(context, service: item),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do Card (Cliente & Data)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          clientName,
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (dueDate.isNotEmpty)
                        Text(
                          dueDate,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Título/Descrição do Serviço
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          desc,
                          style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit_rounded, color: Colors.white30, size: 14),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Alerta de Atraso
                  if (overdueMessage != null && status != 'paid') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            overdueMessage,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Indicador de Recorrência
                  if (isRecurring) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat_rounded, color: AppTheme.primary, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Mensalidade Recorrente',
                            style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Valores de Contrato, Custos e Lucro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PREÇO', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(currency.format(amount), style: const TextStyle(color: AppTheme.textBody, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (cost > 0) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CUSTOS', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(currency.format(cost), style: const TextStyle(color: AppTheme.expense, fontSize: 13)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MARGEM', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('${margin.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 24, color: Colors.white10),

            // Controles de Ação do Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Edit & Delete
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 16),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () => _showServiceFormDialog(context, service: item),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.expense, size: 16),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () => _confirmDeleteService(context, id),
                    ),
                  ],
                ),

                // Botões específicos por etapa
                Row(
                  children: [
                    // Glauber Follow-up IA
                    if (status == 'todo' || status == 'in_progress')
                      ElevatedButton.icon(
                        onPressed: () => _generateFollowUpAi(clientName, amount, desc, item['dueDate'] ?? ''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                          side: const BorderSide(color: Colors.white12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 12, color: AppTheme.primary),
                        label: const Text('FOLLOW-UP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),

                    // Cobrança por WhatsApp
                    if (status == 'billed')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WhatsAppCobrancaScreen(
                                initialClientName: clientName,
                                initialAmount: amount,
                                initialDescription: desc,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Colors.white),
                        label: const Text('COBRAR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),

                    // Emissão de Recibo
                    if (status == 'paid')
                      ElevatedButton.icon(
                        onPressed: () => _generateReceiptDialog(context, clientName, amount, desc),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.article_outlined, size: 12, color: Colors.white),
                        label: const Text('RECIBO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),

                    const SizedBox(width: 8),

                    // Navegadores de Pipeline
                    Row(
                      children: [
                        if (status != 'todo')
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppTheme.textMuted),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: () => _shiftServiceStage(id, status, backward: true),
                          ),
                        if (status != 'paid')
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.primary),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: () => _shiftServiceStage(id, status, backward: false, item: item),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Mudar estágio do card
  void _shiftServiceStage(String id, String currentStatus, {required bool backward, Map<String, dynamic>? item}) async {
    final int index = _stages.indexWhere((s) => s['id'] == currentStatus);
    if (index == -1) return;

    final int targetIndex = backward ? index - 1 : index + 1;
    if (targetIndex >= 0 && targetIndex < _stages.length) {
      final String targetStatus = _stages[targetIndex]['id']!;
      await _realtimeService.updateLocalServiceStatus(id, targetStatus);

      // Tratamento especial de avanços comerciais
      if (!backward && targetStatus == 'paid' && item != null) {
        _triggerPaidComercialAutomation(item);
      }
    }
  }

  // Automações ao mover para Pago: Auto-receita e Auto-renovação
  void _triggerPaidComercialAutomation(Map<String, dynamic> item) {
    final double amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
    final String desc = item['description'] ?? 'Serviço';
    final String clientName = item['clientName'] ?? 'Cliente';
    final bool isRecurring = item['isRecurring'] == true;

    // 1. Lançar receita automática
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Faturamento Concluído! 🎉'),
        content: Text('Deseja registrar o valor de R\$ ${amount.toStringAsFixed(2)} como uma Receita no seu fluxo de caixa do GEREPAGUE?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NÃO', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final transaction = TransactionModel(
                id: '',
                amount: amount,
                category: 'Serviço / Projeto 💼',
                description: 'Faturamento: $desc - $clientName',
                date: DateTime.now(),
                type: TransactionType.income,
              );
              await Provider.of<TransactionsProvider>(context, listen: false).addTransaction(transaction);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receita registrada com sucesso! 💰'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('REGISTRAR RECEITA'),
          ),
        ],
      ),
    ).then((_) {
      if (context.mounted) {
        _showAddToPortfolioDialog(context, item);
      }
    });

    // 2. Renovar recorrência mensal se ativada
    if (isRecurring) {
      try {
        final format = DateFormat('dd/MM/yyyy');
        final currentDueDate = format.parse(item['dueDate'] ?? DateFormat('dd/MM/yyyy').format(DateTime.now()));
        final nextMonthDueDate = DateTime(currentDueDate.year, currentDueDate.month + 1, currentDueDate.day);
        final String newId = DateTime.now().millisecondsSinceEpoch.toString() + '_recurring';

        _realtimeService.saveLocalService(newId, {
          'clientId': item['clientId'] ?? '',
          'clientName': clientName,
          'description': desc,
          'amount': amount,
          'cost': double.tryParse(item['cost']?.toString() ?? '0') ?? 0.0,
          'dueDate': format.format(nextMonthDueDate),
          'status': 'todo', // Volta para Pendente no mês seguinte
          'isRecurring': true,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔁 Recorrência Ativada: Criado novo card de cobrança para ${format.format(nextMonthDueDate)}!'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      } catch (_) {}
    }
  }

  // Glauber AI Follow-up generator
  void _generateFollowUpAi(String clientName, double amount, String projectDesc, String dueDate) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      final text = await _aiChatService.generateNegotiationProposal(
        contactName: clientName,
        amount: amount,
        dueDate: dueDate.isNotEmpty ? dueDate : DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 5))),
        description: '$projectDesc (Diretriz: escreva uma mensagem muito curta, simpática e profissional para WhatsApp acompanhando o projeto e perguntando se o cliente tem alguma dúvida ou se podemos fechar/iniciar)',
        type: 'receber',
      );

      if (mounted) Navigator.pop(context); // Fechar carregamento

      if (mounted) {
        _showFollowUpDialog(context, clientName, text);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar follow-up com IA: $e')),
      );
    }
  }

  void _showFollowUpDialog(BuildContext context, String clientName, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Glauber Follow-up 🤖', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mensagem comercial sugerida para enviar para $clientName:',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  message,
                  style: const TextStyle(color: AppTheme.textBody, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copiado para área de transferência!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('COPIAR TEXTO', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}';
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('ENVIAR NO WHATSAPP'),
          ),
        ],
      ),
    );
  }

  // Diálogo de Emissão de Recibo Digital
  void _generateReceiptDialog(BuildContext context, String clientName, double amount, String desc) {
    final dateStr = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(DateTime.now());
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final String receiptText = '''
DECLARAÇÃO DE RECIBO DE PAGAMENTO

Recebemos de $clientName a importância de ${currency.format(amount)} (${NumberFormat.decimalPattern('pt_BR').format(amount)} reais) correspondente a:
"$desc".

Para clareza e confirmação de quitação, firmamos o presente recibo.

Data: $dateStr
GEREPAGUE Finanças Freelancer
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Recibo de Pagamento 📄', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12)),
            child: Text(
              receiptText,
              style: const TextStyle(color: AppTheme.textBody, fontFamily: 'monospace', fontSize: 12, height: 1.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: receiptText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recibo copiado para área de transferência!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('COPIAR RECIBO', style: TextStyle(color: AppTheme.primary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(receiptText)}';
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            child: const Text('ENVIAR NO WHATSAPP'),
          ),
        ],
      ),
    );
  }

  // Configuração rápida de Chave Pix
  void _showPixConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: _pixKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Configurar Minha Chave Pix 🔑', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insira a sua chave Pix comercial. Ela será anexada automaticamente em todas as mensagens de cobrança geradas pela IA.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.textBody),
              decoration: const InputDecoration(
                labelText: 'Chave Pix (Ex: CNPJ, Telefone, CPF)',
                labelStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _realtimeService.savePixKey(controller.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chave Pix salva com sucesso! 💸'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('SALVAR CHAVE'),
          ),
        ],
      ),
    );
  }

  // Diálogo Formulário de Adicionar/Editar Serviço
  void _showServiceFormDialog(BuildContext context, {Map<String, dynamic>? service}) {
    final clientNameController = TextEditingController(text: service?['clientName'] ?? '');
    final descController = TextEditingController(text: service?['description'] ?? '');
    final amountController = TextEditingController(text: service?['amount']?.toString() ?? '');
    final costController = TextEditingController(text: service?['cost']?.toString() ?? '');
    final dateController = TextEditingController(text: service?['dueDate'] ?? DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 5))));

    bool isRecurring = service?['isRecurring'] == true;
    String? selectedClientId = service?['clientId'];
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text(
                service == null ? 'Novo Projeto / Serviço 💼' : 'Editar Projeto / Serviço 💼',
                style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Carregar clientes locais salvos
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _realtimeService.getLocalClients(),
                        builder: (context, snapshot) {
                          final clients = snapshot.data ?? [];
                          if (clients.isEmpty) {
                            return TextFormField(
                              controller: clientNameController,
                              style: const TextStyle(color: AppTheme.textBody),
                              decoration: const InputDecoration(
                                labelText: 'Nome do Cliente (Preenchimento manual)',
                                labelStyle: TextStyle(color: AppTheme.textMuted),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome do cliente' : null,
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                dropdownColor: AppTheme.surface,
                                value: (selectedClientId != null && clients.any((c) => c['id'] == selectedClientId))
                                    ? selectedClientId
                                    : null,
                                style: const TextStyle(color: AppTheme.textBody),
                                decoration: const InputDecoration(
                                  labelText: 'Vincular Cliente Salvo',
                                  labelStyle: TextStyle(color: AppTheme.textMuted),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Preenchimento manual...')),
                                  ...clients.map((c) {
                                    return DropdownMenuItem(
                                      value: c['id'],
                                      child: Text(c['name'] ?? ''),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  setDialogState(() {
                                    selectedClientId = val;
                                    if (val != null) {
                                      final match = clients.firstWhere((c) => c['id'] == val);
                                      clientNameController.text = match['name'] ?? '';
                                    } else {
                                      clientNameController.clear();
                                    }
                                  });
                                },
                              ),
                              if (selectedClientId == null) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: clientNameController,
                                  style: const TextStyle(color: AppTheme.textBody),
                                  decoration: const InputDecoration(
                                    labelText: 'Nome do Cliente Manual',
                                    labelStyle: TextStyle(color: AppTheme.textMuted),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome do cliente' : null,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        style: const TextStyle(color: AppTheme.textBody),
                        decoration: const InputDecoration(
                          labelText: 'Nome do Serviço / Escopo',
                          labelStyle: TextStyle(color: AppTheme.textMuted),
                          hintText: 'Ex: Design de Logotipo',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Descreva o serviço' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        style: const TextStyle(color: AppTheme.textBody),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Valor Cobrado (R\$)',
                          prefixText: 'R\$ ',
                          labelStyle: TextStyle(color: AppTheme.textMuted),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Informe o valor';
                          if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: costController,
                        style: const TextStyle(color: AppTheme.textBody),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Custos Diretos (R\$) - Opcional',
                          prefixText: 'R\$ ',
                          labelStyle: TextStyle(color: AppTheme.textMuted),
                          hintText: 'Ex: Hospedagem, insumos',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            final double cost = double.tryParse(costController.text.replaceAll(',', '.')) ?? 0.0;
                            if (cost <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Insira um valor de custo direto maior que zero primeiro!')),
                              );
                              return;
                            }
                            _showSuggestedPricingDialog(context, cost, (suggestedPrice) {
                              setDialogState(() {
                                amountController.text = suggestedPrice.toStringAsFixed(2);
                              });
                            });
                          },
                          icon: const Icon(Icons.calculate_rounded, size: 14),
                          label: const Text('Calcular Preço por Margem', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dateController,
                        style: const TextStyle(color: AppTheme.textBody),
                        decoration: const InputDecoration(
                          labelText: 'Data Limite (dd/MM/yyyy)',
                          labelStyle: TextStyle(color: AppTheme.textMuted),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Informe o prazo';
                          try {
                            DateFormat('dd/MM/yyyy').parse(v);
                          } catch (_) {
                            return 'Formato incorreto. Use dd/MM/yyyy';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: isRecurring,
                            activeColor: AppTheme.primary,
                            onChanged: (val) {
                              setDialogState(() {
                                isRecurring = val ?? false;
                              });
                            },
                          ),
                          const Text('Serviço Recorrente (Mensal)', style: TextStyle(color: AppTheme.textBody, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final String serviceId = service?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
                    final Map<String, dynamic> data = {
                      'clientId': selectedClientId ?? '',
                      'clientName': clientNameController.text.trim(),
                      'description': descController.text.trim(),
                      'amount': double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0,
                      'cost': double.tryParse(costController.text.replaceAll(',', '.')) ?? 0.0,
                      'dueDate': dateController.text.trim(),
                      'status': service?['status'] ?? 'todo',
                      'isRecurring': isRecurring,
                    };

                    await _realtimeService.saveLocalService(serviceId, data);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(service == null ? 'Serviço cadastrado com sucesso!' : 'Serviço atualizado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('SALVAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteService(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Remover do Kanban?'),
        content: const Text('Tem certeza que deseja remover este serviço/projeto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NÃO', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              await _realtimeService.deleteLocalService(id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Serviço removido com sucesso.')),
                );
              }
            },
            child: const Text('SIM, REMOVER', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }

  void _showSuggestedPricingDialog(BuildContext context, double cost, Function(double) onCalculated) {
    final marginController = TextEditingController(text: '50');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Calculadora de Margem 🧮', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custo Direto Informado: R\$ ${cost.toStringAsFixed(2)}',
              style: const TextStyle(color: AppTheme.textBody, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Digite a margem de lucro desejada (%):',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: marginController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textBody),
              decoration: const InputDecoration(
                suffixText: '%',
                hintText: 'Ex: 60',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final double margin = double.tryParse(marginController.text) ?? 50.0;
              if (margin >= 100 || margin <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Margem deve ser entre 1% e 99%')),
                );
                return;
              }
              final double price = cost / (1 - (margin / 100));
              onCalculated(price);
              Navigator.pop(context);
            },
            child: const Text('APLICAR PREÇO'),
          ),
        ],
      ),
    );
  }

  void _showMEITaxCalculatorDialog(BuildContext context, List<Map<String, dynamic>> services) {
    double monthlyBilling = 0.0;
    for (var s in services) {
      final status = s['status'] ?? 'todo';
      if (status == 'paid' || status == 'billed') {
        monthlyBilling += double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0;
      }
    }

    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final double meiLimit = 6750.0;
    final double limitPct = monthlyBilling > 0 ? (monthlyBilling / meiLimit) : 0.0;
    final double limitPercent = limitPct > 1.0 ? 1.0 : limitPct;

    final double dasMei = 83.60;
    final double simplesNacionalEst = monthlyBilling * 0.06;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Simulador de Impostos MEI / ME 🧾', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulação com base no faturamento ativo do seu Kanban (Billed + Paid):',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Faturamento no Mês:', style: TextStyle(color: AppTheme.textBody)),
                  Text(currency.format(monthlyBilling), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              const Text(
                'CONTRIBUIÇÃO MENSAL MEI (DAS)',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DAS MEI (Prest. Serviços):', style: TextStyle(color: AppTheme.textBody, fontSize: 13)),
                  Text(currency.format(dasMei), style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Limite Mensal Proporcional MEI:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  Text('${(limitPct * 100).toStringAsFixed(0)}% do Limite', style: TextStyle(color: limitPct > 1.0 ? Colors.redAccent : AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (limitPercent * 100).round(),
                        child: Container(color: limitPct > 1.0 ? Colors.redAccent : AppTheme.primary),
                      ),
                      Expanded(
                        flex: ((1 - limitPercent) * 100).round(),
                        child: Container(color: Colors.white10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Limite Proporcional: ${currency.format(meiLimit)} / mês',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              const Text(
                'SE VOCÊ DESENQUADRAR DO MEI (SIMPLES NACIONAL - ME)',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Simples Nac. Est. (Anexo III - 6%):', style: TextStyle(color: AppTheme.textBody, fontSize: 13)),
                  Text(currency.format(simplesNacionalEst), style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Nota: A alíquota do Simples Nacional inicia em 6% para serviços de até R\$ 180.000 anuais.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 9, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _exportPipelineToPdf(List<Map<String, dynamic>> services) async {
    final pdf = pw.Document();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    double totalPendente = 0.0;
    double totalProgresso = 0.0;
    double totalCobrado = 0.0;
    double totalPago = 0.0;

    for (var s in services) {
      final status = s['status'] ?? 'todo';
      final double amount = double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0;
      if (status == 'todo') totalPendente += amount;
      if (status == 'in_progress') totalProgresso += amount;
      if (status == 'billed') totalCobrado += amount;
      if (status == 'paid') totalPago += amount;
    }

    final double totalGeral = totalPendente + totalProgresso + totalCobrado + totalPago;
    final double conversionRate = totalGeral > 0 ? (totalPago / totalGeral) * 100 : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GEREPAGUE - Relatorio de Pipeline Comercial', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            pw.Text('RESUMO DO PIPELINE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              data: [
                ['Etapa', 'Valor Total'],
                ['Pendente', currency.format(totalPendente)],
                ['Em Andamento', currency.format(totalProgresso)],
                ['Cobrado', currency.format(totalCobrado)],
                ['Pago (Faturado)', currency.format(totalPago)],
                ['Volume Total Comercial', currency.format(totalGeral)],
                ['Taxa de Conversao', '${conversionRate.toStringAsFixed(1)}%'],
              ],
            ),
            pw.SizedBox(height: 24),

            pw.Text('DETALHAMENTO DE PROJETOS & SERVICOS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              data: [
                ['Cliente', 'Descricao', 'Valor (R\$)', 'Custos (R\$)', 'Margem (%)', 'Vencimento', 'Status'],
                ...services.map((s) {
                  final double amt = double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0;
                  final double cst = double.tryParse(s['cost']?.toString() ?? '0') ?? 0.0;
                  final double profit = amt - cst;
                  final double margin = amt > 0 ? (profit / amt) * 100 : 0.0;

                  return [
                    s['clientName'] ?? 'Avulso',
                    s['description'] ?? 'Sem descricao',
                    currency.format(amt),
                    currency.format(cst),
                    '${margin.toStringAsFixed(0)}%',
                    s['dueDate'] ?? '',
                    (s['status'] ?? 'todo').toString().toUpperCase(),
                  ];
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'extrato_comercial_gerepague.pdf',
    );
  }

  Widget _buildBiDashboard(List<Map<String, dynamic>> allServices) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    final activeServices = allServices.where((s) => s['status'] != 'paid').toList();
    final paidServices = allServices.where((s) => s['status'] == 'paid').toList();
    
    final double projectedRevenue = activeServices.fold(0.0, (sum, s) => sum + (double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0));
    final double projectedCost = activeServices.fold(0.0, (sum, s) => sum + (double.tryParse(s['cost']?.toString() ?? '0') ?? 0.0));
    final double totalPaid = paidServices.fold(0.0, (sum, s) => sum + (double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0));
    
    final double projectedProfit = projectedRevenue - projectedCost;
    final double averageMargin = projectedRevenue > 0 ? (projectedProfit / projectedRevenue) * 100 : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MÉTRICAS BI & LUCRATIVIDADE 📊',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBiItem(
                    'Lucro Previsto',
                    currency.format(projectedProfit),
                    Colors.greenAccent,
                  ),
                ),
                Expanded(
                  child: _buildBiItem(
                    'Margem Média',
                    '${averageMargin.toStringAsFixed(1)}%',
                    Colors.cyanAccent,
                  ),
                ),
                Expanded(
                  child: _buildBiItem(
                    'Total em Custos',
                    currency.format(projectedCost),
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showAddToPortfolioDialog(BuildContext context, Map<String, dynamic> item) {
    final double amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
    final String desc = item['description'] ?? 'Serviço';
    final String clientName = item['clientName'] ?? 'Cliente';

    double rating = 5.0;
    final TextEditingController titleController = TextEditingController(text: desc);
    final TextEditingController descController = TextEditingController(
      text: 'Projeto concluído com sucesso para $clientName no valor de R\$ ${amount.toStringAsFixed(2)}. Entregue dentro do prazo com excelente nível de qualidade.',
    );
    final TextEditingController resultController = TextEditingController(text: 'Satisfação garantida com entrega de alto padrão.');
    final TextEditingController linkController = TextEditingController();

    List<String> detectedTechs = ['Desenvolvimento', 'Freelance'];
    final lowerDesc = desc.toLowerCase();
    if (lowerDesc.contains('web') || lowerDesc.contains('site') || lowerDesc.contains('landing')) {
      detectedTechs.add('Web');
    }
    if (lowerDesc.contains('app') || lowerDesc.contains('mobile') || lowerDesc.contains('android') || lowerDesc.contains('ios')) {
      detectedTechs.add('Mobile');
    }
    if (lowerDesc.contains('design') || lowerDesc.contains('ux') || lowerDesc.contains('ui') || lowerDesc.contains('arte')) {
      detectedTechs.add('Design');
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.rocket_launch_rounded, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Adicionar ao Portfólio? 📸',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textBody, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deseja converter este serviço concluído em um case de sucesso público no seu portfólio?',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    const Text('SATISFAÇÃO DO CLIENTE:', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: Colors.amberAccent,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() => rating = index + 1.0);
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título do Case',
                        labelStyle: TextStyle(fontSize: 12),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição do Case',
                        labelStyle: TextStyle(fontSize: 12),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: resultController,
                      decoration: const InputDecoration(
                        labelText: 'Resultado Comercial',
                        labelStyle: TextStyle(fontSize: 12),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: linkController,
                      decoration: const InputDecoration(
                        labelText: 'Link ao Vivo (Opcional)',
                        labelStyle: TextStyle(fontSize: 12),
                        hintText: 'https://exemplo.com',
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DEPOIS', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final project = {
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'result': resultController.text.trim(),
                      'liveLink': linkController.text.trim(),
                      'value': amount,
                      'rating': rating,
                      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      'technologies': detectedTechs,
                    };
                    await RealtimeDbService().addPortfolioProject(project);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🚀 Case de faturamento publicado no seu portfólio público!'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('PUBLICAR NO PORTFÓLIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
