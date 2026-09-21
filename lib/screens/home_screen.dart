import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/financial_health_bar.dart';
import '../widgets/spending_donut_chart.dart';
import '../widgets/radial_menu.dart';
import '../widgets/dashboard/os_kanban_board.dart';
import '../widgets/dashboard/premium_income_dashboard.dart';
import '../widgets/dashboard/premium_expense_dashboard.dart';
import '../widgets/dashboard/premium_card.dart';
import '../widgets/dynamic_background.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import '../models/transaction_model.dart';
import 'package:share_plus/share_plus.dart';
import '../services/voice_service.dart';
import '../services/budget_service.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';
import 'goals_screen.dart';
import 'business_dashboard_screen.dart';
import 'ai_chat_screen.dart';
import 'scanner_screen.dart';
import 'login_screen.dart';
import 'zen_investments_screen.dart';
import 'anomaly_alert_screen.dart';
import 'family_setup_screen.dart';
import 'admin_dashboard_screen.dart';
import 'whatsapp_cobranca_screen.dart';
import 'bpo_tower_screen.dart';
import 'contador_portal_screen.dart';
import '../services/realtime_db_service.dart';
import '../services/realtime_db_service.dart';
import '../providers/user_stats_provider.dart';
import '../services/pdf_service.dart';
import '../services/coach_service.dart';
import '../services/recurrence_service.dart';
import '../services/pdf_report_service.dart';
import '../services/document_ai_service.dart';
import '../widgets/command_palette.dart';
import '../widgets/sync_center_dialog.dart';
import '../widgets/budget_dashboard_view.dart';
import '../services/ai_insight_service.dart';
import '../services/bio_auth_service.dart';
import '../screens/document_vault_screen.dart';
import '../services/realtime_db_service.dart';
import '../providers/subscription_provider.dart';
import '../services/proactive_insight_service.dart';

import '../services/bank_import_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/bank_sync_service.dart';
import 'simulation_screen.dart';
import 'war_room_screen.dart';
import 'bank_reconciliation_screen.dart';
import '../widgets/dre_tree_view.dart';
import '../widgets/challenges_section.dart';
import 'my_subscriptions_screen.dart';
import '../widgets/installments_projection_view.dart';
import 'wallets_screen.dart';
import 'credit_cards_screen.dart';
import '../widgets/user_header.dart';
import '../widgets/spending_limits_card.dart';
import '../widgets/dashboard/app_sidebar.dart';
import '../widgets/dashboard/app_bottom_nav_bar.dart';
import '../widgets/dashboard/personal_dashboard.dart';
import '../widgets/dashboard/omie/omie_forecasting_chart.dart';
import '../widgets/dashboard/omie/omie_crm_widget.dart';
import '../widgets/dashboard/omie/omie_business_dashboard.dart';
import '../widgets/dashboard/omie/omie_business_widgets.dart';
import '../widgets/daily_spending_radar.dart';
import '../widgets/premium_period_selector.dart';
import '../widgets/dashboard/omie/omie_team_performance.dart';
import '../widgets/dashboard/omie/omie_cash_flow_heatmap.dart';
import '../widgets/dashboard/omie/omie_health_panel.dart';
import '../widgets/dashboard/omie/omie_goal_banner.dart';
import '../widgets/dashboard/omie/omie_yearly_comparison_chart.dart';
import '../widgets/dashboard/omie/omie_ai_consultant_card.dart';
import '../widgets/dashboard/omie/omie_expense_donut.dart';
import '../widgets/dashboard/omie/omie_project_widget.dart';
import '../widgets/dashboard/omie/omie_dre_block.dart';
import '../widgets/dashboard/omie/omie_kpis.dart';
import '../widgets/dashboard/omie/omie_aging_chart.dart';
import '../widgets/dashboard/omie/omie_productivity_chart.dart';
import '../widgets/dashboard/omie/omie_abc_ranking.dart';
import '../widgets/dashboard/omie/business_agenda.dart';
import '../widgets/dashboard/omie/app_header.dart';
import '../widgets/dashboard/premium_summary_dashboard.dart';
import '../widgets/dashboard/dre_matrix_dashboard.dart';
import '../widgets/dashboard/comparison_dashboard.dart';
import '../widgets/dashboard/geographic_dashboard.dart';
import '../widgets/dashboard/daily_forecast_dashboard.dart';

enum DashboardType { summary, income, expense, dre, comparison, map, os, forecast, budget, subscriptions, installments, creditCards, wallets, bpoTower }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  DashboardType _currentDashboard = DashboardType.summary;
  final FocusNode _keyboardFocusNode = FocusNode();
  String? _bpoActiveClientUid;
  String? _bpoActiveClientName;
  bool _isDragging = false;
  final AiInsightService _insightService = AiInsightService();
  final RealtimeDbService _realtimeService = RealtimeDbService();
  final BioAuthService _bioAuth = BioAuthService();
  final VoiceService _voiceService = VoiceService();
  AiInsightResult? _currentInsight;
  bool _isListening = false;
  bool _isAuthenticated = true;
  bool _needsAuth = false;
  bool _showConfetti = false;
  late AnimationController _confettiController;
  final List<ConfettiParticle> _confettiParticles = List.generate(80, (index) => ConfettiParticle());

  String? _userNiche;
  bool _loadingNiche = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometrics();
    _refreshInsight();
    _voiceService.init();
    _loadUserNiche();
    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..addListener(() {
      if (_showConfetti) setState(() {});
    });
    _confettiController.repeat();
    // Iniciar foco para capturar atalhos globais, registrar login diário e inicializar sincronização bancária
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _keyboardFocusNode.requestFocus();
      try {
        final statsProvider = Provider.of<UserStatsProvider>(context, listen: false);
        statsProvider.recordDailyLogin();
      } catch (e) {
        debugPrint('Erro ao registrar login diário no initState: $e');
      }
      await BankSyncService.init();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyboardFocusNode.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      BankSyncService.init();
    }
  }

  Future<void> _loadUserNiche() async {
    try {
      final profile = await _realtimeService.getUserProfile();
      if (mounted) {
        setState(() {
          _userNiche = profile?['niche']?.toString();
          _loadingNiche = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingNiche = false);
      }
    }
  }

  Future<void> _checkBiometrics() async {
    final enabled = await _bioAuth.isEnabled();
    if (enabled) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _needsAuth = true;
        });
      }
      final authenticated = await _bioAuth.authenticate();
      if (authenticated && mounted) {
        setState(() => _isAuthenticated = true);
      }
    } else {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _needsAuth = false;
        });
      }
    }
  }

  void _showCommandPalette() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => const CommandPalette(),
    );
    
    if (result != null && mounted) {
      setState(() => _currentDashboard = _getDashboardTypeFromIndex(result));
      _refreshInsight();
    }
  }

  Future<void> _refreshInsight() async {
    final provider = Provider.of<TransactionsProvider>(context, listen: false);
    if (!provider.isBusinessMode) return;
    
    final insight = await _insightService.getSmartAlert(provider);
    if (mounted) {
      setState(() => _currentInsight = insight);
    }
  }

  Future<void> _handleFileDrop(DropDoneDetails details) async {
    if (details.files.isEmpty) return;
    
    final file = details.files.first;
    final bytes = await file.readAsBytes();
    
    
    if (!mounted) return;

    // Salvar na Pasta Digital
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/vault');
    if (!await vaultDir.exists()) await vaultDir.create(recursive: true);
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final savePath = '${vaultDir.path}/${timestamp}_${file.name}';
    await File(file.path).copy(savePath);

    _showProcessingOverlay();
    
    try {
      final ext = file.name.toLowerCase().split('.').last;
      
      if (ext == 'ofx' || ext == 'csv') {
        final service = BankImportService();
        final content = utf8.decode(bytes);
        final rawItems = ext == 'ofx' ? service.parseOFX(content) : service.parseCSV(content);
        
        if (rawItems.isNotEmpty) {
          final enriched = await service.enrichWithAI(rawItems);
          if (mounted) {
            Navigator.pop(context); // Fecha overlay
            _showBankImportDialog(enriched);
          }
          return;
        }
      }

      final ai = DocumentAiService();
      
      // Se for PDF, tenta ler como extrato de múltiplas transações
      if (ext == 'pdf') {
        final extracted = await ai.processBankStatement(bytes, 'application/pdf');
        if (extracted.isNotEmpty && mounted) {
          Navigator.pop(context); // Fecha overlay
          final service = BankImportService();
          final transactions = service.processExtractedDocuments(extracted);
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => BankReconciliationScreen(extractedTransactions: transactions)
          ));
          return;
        }
      }

      final result = await ai.processDocument(bytes, _getMimeType(file.name));
      
      if (result != null && mounted) {
        Navigator.pop(context); // Fecha overlay de processamento
        _showExtractedDataDialog(result);
      }
    } catch (e) {
       if (mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao processar: $e')));
       }
    }
  }

  void _triggerConfetti() {
    if (mounted) {
      setState(() => _showConfetti = true);
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showConfetti = false);
      });
    }
  }

  String _getMimeType(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) return 'application/pdf';
    if (fileName.toLowerCase().endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  void _showProcessingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 24),
              const Text('A GerePag está lendo seu documento...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('Usando Inteligência Artificial (Gemini)', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _showExtractedDataDialog(ExtractedDocument doc) {
      final amountController = TextEditingController(text: doc.amount.toStringAsFixed(2));
      final descController = TextEditingController(text: doc.description);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Confirmar Leitura IA 🤖'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixText: 'R\$ '),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<TransactionsProvider>(context, listen: false);
                provider.addTransaction(TransactionModel(
                  id: '',
                  description: descController.text,
                  amount: double.tryParse(amountController.text) ?? 0.0,
                  date: doc.date,
                  category: doc.category,
                  type: doc.type == 'income' ? TransactionType.income : TransactionType.expense,
                ));
                Navigator.pop(context);
              },
              child: const Text('SALVAR AGORA'),
            ),
          ],
        ),
      );
  }

  void _startVoiceReconciliation(String uniqueKey, Map<String, dynamic> log) async {
    final provider = Provider.of<TransactionsProvider>(context, listen: false);
    final double amount = double.tryParse(log['amount']?.toString() ?? '0') ?? 0.0;
    final bool isIncome = log['isIncome'] == true;

    setState(() => _isListening = true);

    _voiceService.startListening((text) async {
      if (!mounted) return;
      setState(() => _isListening = false);

      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Glauber: Não ouvi nada. Tente falar mais perto do microfone.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      _showGlauberProcessingDialog();
      final result = await _voiceService.processCommandWithAi(text);
      if (mounted) Navigator.pop(context); // Fechar overlay de processamento

      if (result != null) {
        final List<dynamic> commands = result['commands'] is List ? result['commands'] : [result];
        if (commands.isNotEmpty) {
          final cmd = Map<String, dynamic>.from(commands.first);
          final desc = cmd['description']?.toString() ?? text;
          final category = cmd['category']?.toString() ?? (isIncome ? 'Receitas' : 'Outros');

          // Quitar transação no banco com os dados da voz!
          await provider.addTransaction(TransactionModel(
            id: '',
            description: desc,
            amount: amount,
            category: category,
            date: DateTime.now(),
            type: isIncome ? TransactionType.income : TransactionType.expense,
          ));

          // Atualizar o log da notificação para "confirmed"
          await RealtimeDbService().updateNotificationLogStatus(uniqueKey, 'confirmed');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚡ Glauber: Lançamento de R\$ ${amount.toStringAsFixed(2)} classificado em "$category" com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Glauber: Não entendi muito bem. Tente dizer algo como "foi a mensalidade de design".')),
        );
      }
    });
  }

  Widget _buildVoiceReconciliationPrompt(TransactionsProvider provider) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: RealtimeDbService().getNotificationLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // Encontrar a primeira sugestão pendente
        final pendingLogs = snapshot.data!.where((log) => log['status'] == 'suggested').toList();
        if (pendingLogs.isEmpty) {
          return const SizedBox.shrink();
        }

        final pendingLog = pendingLogs.first;
        final String uniqueKey = pendingLog['id'] ?? pendingLog['key'] ?? '';
        final double amount = double.tryParse(pendingLog['amount']?.toString() ?? '0') ?? 0.0;
        
        // Obter nome amigável do banco
        String bankName = 'Banco';
        final pkg = pendingLog['packageName']?.toString();
        if (pkg != null) {
          if (pkg.contains('nu.production')) bankName = 'Nubank';
          else if (pkg.contains('inter')) bankName = 'Banco Inter';
          else if (pkg.contains('next')) bankName = 'Next';
          else if (pkg.contains('bb.android')) bankName = 'Banco do Brasil';
          else if (pkg.contains('itau')) bankName = 'Itaú';
          else if (pkg.contains('bradesco')) bankName = 'Bradesco';
          else if (pkg.contains('santander')) bankName = 'Santander';
          else if (pkg.contains('c6bank')) bankName = 'C6 Bank';
          else if (pkg.contains('caixa')) bankName = 'Caixa Econômica';
          else if (pkg.contains('mercadopago')) bankName = 'Mercado Pago';
          else if (pkg.contains('pagbank')) bankName = 'PagBank';
          else if (pkg.contains('picpay')) bankName = 'PicPay';
        }

        return Positioned(
          bottom: 100,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: Colors.blueAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Transação Pix Detectada 💸',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Recebemos uma notificação do $bankName de R\$ ${amount.toStringAsFixed(2)}. O que foi esse lançamento?',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Botão de microfone de quitação por voz
                GestureDetector(
                  onTap: () => _startVoiceReconciliation(uniqueKey, pendingLog),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botão de fechar/ignorar
                GestureDetector(
                  onTap: () async {
                    if (uniqueKey.isNotEmpty) {
                      await RealtimeDbService().updateNotificationLogStatus(uniqueKey, 'ignored');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
      },
    );
  }

  void _startGlauber() async {
    if (_isListening) {
      _voiceService.stopListening();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    
    _voiceService.startListening((text) async {
      if (!mounted) return;
      setState(() => _isListening = false);
      
      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Glauber: Não consegui ouvir sua voz. Certifique-se de falar perto do microfone.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Mostrar overlay de processamento
      _showGlauberProcessingDialog();
      
      final result = await _voiceService.processCommandWithAi(text);
      
      if (mounted) Navigator.pop(context); // Fechar processamento

      if (result != null && mounted) {
        // Obter a lista de comandos
        final List<dynamic> commands = result['commands'] is List 
            ? result['commands'] 
            : [result]; // fallback para comando único antigo

        final provider = Provider.of<TransactionsProvider>(context, listen: false);
        final List<Map<String, dynamic>> accumulatedTransactions = [];
        String? queryText;
        Map<String, dynamic>? lastInvoiceCmd;

        for (var cmdMap in commands) {
          if (cmdMap is! Map) continue;
          final Map<String, dynamic> cmd = Map<String, dynamic>.from(cmdMap);
          final String action = cmd['action']?.toString() ?? '';

          if (action == 'query') {
            queryText = cmd['query']?.toString() ?? text;
          } else if (action == 'add_client') {
            final String name = cmd['client_name']?.toString() ?? '';
            final String phone = cmd['phone']?.toString() ?? '';
            final String email = cmd['email']?.toString() ?? '';
            if (name.isNotEmpty) {
              final String id = DateTime.now().millisecondsSinceEpoch.toString();
              await RealtimeDbService().saveLocalClient(id, {
                'name': name,
                'phone': phone.replaceAll(RegExp(r'\D'), ''),
                'email': email,
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('👤 Glauber: Cliente "$name" cadastrado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Glauber: Não entendi o nome do cliente a cadastrar.')),
              );
            }
          } else if (action == 'add_project') {
            final String clientName = cmd['client_name']?.toString() ?? '';
            final String desc = cmd['description']?.toString() ?? '';
            final double amount = double.tryParse(cmd['amount']?.toString() ?? '0') ?? 0.0;
            final String dateStr = cmd['due_date']?.toString() ?? '';

            if (desc.isNotEmpty) {
              final String id = DateTime.now().millisecondsSinceEpoch.toString();
              String clientId = '';
              String matchedClientName = clientName;

              try {
                final clients = await RealtimeDbService().getLocalClients().first;
                if (clientName.isNotEmpty && clients.isNotEmpty) {
                  final match = clients.firstWhere(
                    (c) => (c['name'] ?? '').toString().toLowerCase().contains(clientName.toLowerCase()),
                    orElse: () => {},
                  );
                  if (match.isNotEmpty) {
                    clientId = match['id'] ?? '';
                    matchedClientName = match['name'] ?? clientName;
                  }
                }
              } catch (_) {}

              await RealtimeDbService().saveLocalService(id, {
                'clientId': clientId,
                'clientName': matchedClientName,
                'description': desc,
                'amount': amount,
                'dueDate': dateStr.isNotEmpty ? dateStr : DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 5))),
                'status': 'todo',
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📋 Glauber: Projeto "$desc" cadastrado para "$matchedClientName"!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Glauber: Não entendi a descrição do projeto a criar.')),
              );
            }
          } else if (action == 'create_invoice') {
            lastInvoiceCmd = cmd;
          } else if (action == 'add_memory') {
            final String memoryText = cmd['memory']?.toString() ?? '';
            if (memoryText.isNotEmpty) {
              await RealtimeDbService().addGlauberMemory(memoryText);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🧠 Glauber: Lembrado: "$memoryText"!'),
                  backgroundColor: Colors.blueAccent,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Glauber: Não entendi o que você queria que eu lembrasse.')),
              );
            }
          } else if (action == 'add_subscription') {
            final String name = cmd['name']?.toString() ?? 'Mensalidade';
            final double price = double.tryParse(cmd['price']?.toString() ?? '0') ?? 0.0;
            final int billingDay = int.tryParse(cmd['billing_day']?.toString() ?? '1') ?? 1;

            if (price > 0) {
              await RealtimeDbService().addSubscription({
                'name': name,
                'price': price,
                'billingDay': billingDay,
                'iconCodePoint': Icons.subscriptions.codePoint,
                'colorValue': Colors.blueAccent.value,
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🔁 Glauber: Assinatura/Mensalidade "$name" de R\$ ${price.toStringAsFixed(2)} criada!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else if (action == 'save_goal_money') {
            final String goalName = cmd['goal_name']?.toString() ?? '';
            final double amount = double.tryParse(cmd['amount']?.toString() ?? '0') ?? 0.0;

            if (goalName.isNotEmpty && amount != 0) {
              try {
                final goals = await RealtimeDbService().getSavingGoals().first;
                final match = goals.firstWhere(
                  (g) => (g['name'] ?? '').toString().toLowerCase().contains(goalName.toLowerCase()),
                  orElse: () => {},
                );

                if (match.isNotEmpty) {
                  final String goalId = match['id'];
                  final double current = double.tryParse(match['currentAmount']?.toString() ?? '0') ?? 0.0;
                  final double target = double.tryParse(match['targetAmount']?.toString() ?? '0') ?? 0.0;
                  final double updated = current + amount;
                  final String name = match['name'] ?? 'Meta';

                  await RealtimeDbService().updateGoalAmount(goalId, updated);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(amount > 0 
                          ? '🎯 Glauber: Guardado R\$ ${amount.toStringAsFixed(2)} no cofrinho "$name"! (Total: R\$ ${updated.toStringAsFixed(2)} / R\$ ${target.toStringAsFixed(2)})'
                          : '🎯 Glauber: Retirado R\$ ${(-amount).toStringAsFixed(2)} do cofrinho "$name"! (Total: R\$ ${updated.toStringAsFixed(2)} / R\$ ${target.toStringAsFixed(2)})'
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Glauber: Não encontrei nenhum cofrinho ou meta chamada "$goalName".'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Glauber: Erro ao gerenciar cofrinho: $e')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Glauber: Não entendi qual cofrinho ou quanto você queria guardar.')),
              );
            }
          } else if (action == 'create_goal') {
            final String goalName = cmd['goal_name']?.toString() ?? 'Nova Meta';
            final double target = double.tryParse(cmd['target_amount']?.toString() ?? '0') ?? 0.0;

            if (target > 0) {
              await RealtimeDbService().addSavingGoal({
                'name': goalName,
                'targetAmount': target,
                'currentAmount': 0.0,
                'iconCodePoint': Icons.savings.codePoint,
                'colorValue': Colors.blueAccent.value,
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎯 Glauber: Cofrinho "$goalName" de R\$ ${target.toStringAsFixed(2)} criado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Glauber: Não entendi o valor alvo da meta.')),
              );
            }
          } else if (action == 'delete_item') {
            final String itemType = cmd['item_type']?.toString() ?? 'transaction';
            final String name = cmd['name']?.toString().toLowerCase() ?? '';

            if (name.isNotEmpty) {
              try {
                if (itemType == 'transaction') {
                  TransactionModel? targetTx;
                  for (var t in provider.transactions) {
                    if (t.description.toLowerCase().contains(name) || t.category.toLowerCase().contains(name)) {
                      targetTx = t;
                      break;
                    }
                  }
                  if (targetTx != null) {
                    await provider.deleteTransaction(targetTx.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🗑️ Glauber: Lançamento "${targetTx.description}" de R\$ ${targetTx.amount.toStringAsFixed(2)} excluído!'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Glauber: Não encontrei nenhum lançamento com o termo "$name".')),
                    );
                  }
                } else if (itemType == 'subscription') {
                  final subs = await RealtimeDbService().getSubscriptions().first;
                  Map<String, dynamic>? targetSub;
                  for (var s in subs) {
                    if (s['name']?.toString().toLowerCase().contains(name) == true) {
                      targetSub = s;
                      break;
                    }
                  }
                  if (targetSub != null) {
                    await RealtimeDbService().deleteSubscription(targetSub['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🗑️ Glauber: Assinatura "${targetSub['name']}" excluída!'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Glauber: Não encontrei nenhuma assinatura chamada "$name".')),
                    );
                  }
                } else if (itemType == 'goal') {
                  final goals = await RealtimeDbService().getSavingGoals().first;
                  Map<String, dynamic>? targetGoal;
                  for (var g in goals) {
                    if (g['name']?.toString().toLowerCase().contains(name) == true) {
                      targetGoal = g;
                      break;
                    }
                  }
                  if (targetGoal != null) {
                    await RealtimeDbService().deleteSavingGoal(targetGoal['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🗑️ Glauber: Cofrinho "${targetGoal['name']}" excluído!'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Glauber: Não encontrei nenhum cofrinho chamado "$name".')),
                    );
                  }
                } else if (itemType == 'project') {
                  final services = await RealtimeDbService().getLocalServices().first;
                  Map<String, dynamic>? targetProj;
                  for (var p in services) {
                    if (p['title']?.toString().toLowerCase().contains(name) == true) {
                      targetProj = p;
                      break;
                    }
                  }
                  if (targetProj != null) {
                    await RealtimeDbService().deleteLocalService(targetProj['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🗑️ Glauber: Projeto "${targetProj['title']}" excluído!'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Glauber: Não encontrei nenhum projeto no Kanban chamado "$name".')),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Glauber: Erro ao apagar item: $e')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Glauber: Diga o nome do item que você deseja que eu apague.')),
              );
            }
          } else if (action == 'add_transaction') {
            accumulatedTransactions.add(cmd);
          }
        }

        // Executar roteamentos de tela únicos
        if (queryText != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AiChatScreen(initialMessage: queryText!),
            ),
          );
        } else if (lastInvoiceCmd != null && mounted) {
          final String clientName = lastInvoiceCmd['client_name']?.toString() ?? '';
          final double amount = double.tryParse(lastInvoiceCmd['amount']?.toString() ?? '0') ?? 0.0;
          final String desc = lastInvoiceCmd['description']?.toString() ?? '';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WhatsAppCobrancaScreen(
                initialClientName: clientName,
                initialAmount: amount > 0 ? amount : null,
                initialDescription: desc,
              ),
            ),
          );
        }

        // Se houver transações acumuladas, abrir diálogo múltiplo
        if (accumulatedTransactions.isNotEmpty && mounted) {
          _showGlauberMultipleTransactionsConfirmation(accumulatedTransactions);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Glauber: Não consegui entender o comando. Tente algo como "Gastei 50 reais com pizza"'))
        );
      }
    });

    // Timeout de segurança caso ele pare de ouvir sozinho
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isListening && !_voiceService.isListening) {
        setState(() => _isListening = false);
      }
    });
  }

  void _showGlauberProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 24),
              Text('Glauber processando...', style: TextStyle(color: AppTheme.textBody, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  void _showGlauberMultipleTransactionsConfirmation(List<Map<String, dynamic>> list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: const [
            Icon(Icons.psychology, color: Colors.blueAccent),
            SizedBox(width: 12),
            Expanded(
              child: Text('Glauber Entendeu 🤖'),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deseja registrar os seguintes lançamentos no seu fluxo de caixa?',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final cmd = list[index];
                    final double amount = double.tryParse(cmd['amount']?.toString() ?? '') ?? 0.0;
                    final String desc = cmd['description']?.toString() ?? 'Gasto por voz';
                    final String category = cmd['category']?.toString() ?? 'Outros';
                    final bool isIncome = cmd['type']?.toString().toLowerCase() == 'income';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isIncome ? Icons.arrow_circle_up_rounded : Icons.arrow_circle_down_rounded,
                            color: isIncome ? Colors.green : Colors.redAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  desc,
                                  style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  category + (cmd['date'] != null ? ' • ${cmd['date']}' : ''),
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'R\$ ${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isIncome ? Colors.green : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<TransactionsProvider>(context, listen: false);
              for (var cmd in list) {
                final double amount = double.tryParse(cmd['amount']?.toString() ?? '') ?? 0.0;
                final String desc = cmd['description']?.toString() ?? 'Lançamento';
                final String category = cmd['category']?.toString() ?? 'Outros';
                final bool isIncome = cmd['type']?.toString().toLowerCase() == 'income';

                DateTime transactionDate = DateTime.now();
                if (cmd['date'] != null) {
                  try {
                    transactionDate = DateTime.parse(cmd['date'].toString());
                  } catch (_) {}
                }

                provider.addTransaction(TransactionModel(
                  id: '',
                  description: desc,
                  amount: amount,
                  category: category,
                  date: transactionDate,
                  type: isIncome ? TransactionType.income : TransactionType.expense,
                ));
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('💰 ${list.length} lançamentos registrados com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('CONFIRMAR TUDO'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    if (_needsAuth && !_isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Stack(
          children: [
            const Positioned.fill(
              child: Center(
                child: Icon(Icons.lock_outline, size: 120, color: Colors.blueAccent),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fingerprint_rounded, size: 80, color: AppTheme.primary),
                      const SizedBox(height: 32),
                      const Text(
                        'Acesso Protegido',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Autentique-se para ver suas finanças.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        width: 240,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _checkBiometrics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('DESBLOQUEAR AGORA', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final provider = Provider.of<TransactionsProvider>(context);
    final statsProvider = Provider.of<UserStatsProvider>(context);

    if (_loadingNiche) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF7C3AED),
            ),
          ),
        ),
      );
    }

    if (_userNiche == 'bpo') {
      return const BpoTowerScreen(isHomeScreen: true);
    }

    if (_userNiche == 'contador') {
      return const ContadorPortalScreen();
    }
 
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 650;
        final bool isDesktop = constraints.maxWidth >= 900;

        return KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent && 
                HardwareKeyboard.instance.isControlPressed && 
                event.logicalKey == LogicalKeyboardKey.keyK) {
              _showCommandPalette();
            } else if (event is KeyDownEvent && 
                HardwareKeyboard.instance.isControlPressed && 
                event.logicalKey == LogicalKeyboardKey.keyJ) {
              _startGlauber();
            }
          },
          child: DropTarget(
            onDragDone: _handleFileDrop,
            onDragEntered: (details) => setState(() => _isDragging = true),
            onDragExited: (details) => setState(() => _isDragging = false),
            child: DynamicBackground(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                drawer: isMobile ? Drawer(
                  backgroundColor: Colors.white,
                  child: AppSidebar(
                    provider: provider,
                    currentDashboard: _currentDashboard,
                    onDashboardChanged: (type) => setState(() => _currentDashboard = type),
                    extended: true,
                  ),
                ) : null,
                body: Stack(
                  children: [
                    _buildDotGrid(),
                    SafeArea(
                      child: Row(
                        children: [
                          if (!isMobile) AppSidebar(
                            provider: provider,
                            currentDashboard: _currentDashboard,
                            onDashboardChanged: (type) => setState(() => _currentDashboard = type),
                            extended: isDesktop,
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 16.0 : 40.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppHeader(
                                      onShowSyncCenter: _showSyncCenter,
                                      onStartVoice: _startGlauber,
                                      isVoiceListening: _isListening,
                                    ),
                                    const SizedBox(height: 32),
                                    if (_currentInsight != null) ...[
                                      _buildAiInsightBanner(_currentInsight!),
                                      const SizedBox(height: 32),
                                    ],
                                    // ── BPO Audit Banner ─────────────────────────────
                                    if (_bpoActiveClientUid != null)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.person_pin_rounded, color: Color(0xFF7C3AED), size: 18),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Visualizando: ${_bpoActiveClientName ?? _bpoActiveClientUid}',
                                                style: GoogleFonts.inter(color: const Color(0xFF7C3AED), fontSize: 13, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _bpoActiveClientUid = null;
                                                  _bpoActiveClientName = null;
                                                });
                                                RealtimeDbService().setBpoActiveClient(null);
                                              },
                                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                              child: const Text('SAIR', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ).animate().fadeIn().slideY(begin: -0.1),
                                    // ── Dashboard Content ────────────────────────────
                                    if (provider.isBusinessMode) ...[
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 400),
                                        child: KeyedSubtree(
                                          key: ValueKey(_currentDashboard),
                                          child: OmieBusinessDashboard(
                                            provider: provider,
                                            currentDashboard: _currentDashboard,
                                            onShowSyncCenter: _showSyncCenter,
                                            onDashboardChanged: (type) => setState(() => _currentDashboard = type),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 400),
                                        child: KeyedSubtree(
                                          key: ValueKey(_currentDashboard),
                                          child: PersonalDashboard(
                                            provider: provider,
                                            currentDashboard: _currentDashboard,
                                            buildCoachBanner: _buildCoachBanner,
                                            buildRecurrenceSuggestions: _buildRecurrenceSuggestions,
                                            buildBalanceCard: _buildBalanceCard,
                                            buildProactiveInsights: _buildProactiveInsights,
                                            buildActivityFeed: _buildActivityFeed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildVoiceReconciliationPrompt(provider),
                  ],
                ),
                bottomNavigationBar: isMobile ? AppBottomNavBar(
                  provider: provider,
                  currentDashboard: _currentDashboard,
                  onDashboardChanged: (type) => setState(() => _currentDashboard = type),
                ) : null,
                floatingActionButton: RadialMenu(
                  onActionSelected: (index) {
                    if (index == 0) _showQuickAdd(context, provider, type: TransactionType.expense);
                    if (index == 1) _showQuickAdd(context, provider, type: TransactionType.income);
                    if (index == 2) _showTransferModal(context, provider);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBankImportDialog(List<dynamic> items) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Conciliação Bancária 🏦'),
        content: SizedBox(
          width: double.maxFinite,
          child: BankReconciliationScreen(extractedTransactions: List<TransactionModel>.from(items)),
        ),
      ),
    );
  }

  void _showSyncCenter() {
    showDialog(
      context: context,
      builder: (context) => const SyncCenterDialog(),
    );
  }

  Widget _buildAiInsightBanner(AiInsightResult insight) {
    Color severityColor;
    IconData severityIcon;

    switch (insight.severity) {
      case 'critical':
        severityColor = AppTheme.expense;
        severityIcon = Icons.error_outline;
        break;
      case 'warning':
        severityColor = Colors.orangeAccent;
        severityIcon = Icons.warning_amber_rounded;
        break;
      default:
        severityColor = AppTheme.primary;
        severityIcon = Icons.auto_awesome;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(severityIcon, color: severityColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: TextStyle(color: severityColor, fontWeight: FontWeight.bold)),
                Text(insight.message, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(TransactionsProvider provider) {
    if (provider.transactions.isEmpty) {
      return const Center(child: Text('Nenhuma atividade recente.', style: TextStyle(color: AppTheme.textMuted)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.transactions.length.clamp(0, 10),
      itemBuilder: (context, index) {
        final t = provider.transactions[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: t.type == TransactionType.income ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            child: Icon(t.type == TransactionType.income ? Icons.arrow_upward : Icons.arrow_downward, color: t.type == TransactionType.income ? Colors.green : Colors.red, size: 18),
          ),
          title: Text(t.description, style: const TextStyle(color: AppTheme.textBody, fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          trailing: Text(
            NumberFormat.simpleCurrency(locale: 'pt_BR').format(t.amount),
            style: TextStyle(color: t.type == TransactionType.income ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(TransactionsProvider provider) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1E40AF)]),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SALDO TOTAL', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(currency.format(provider.totalBalance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProactiveInsights(TransactionsProvider provider) => const SizedBox.shrink();
  Widget _buildRecurrenceSuggestions(TransactionsProvider provider) => const SizedBox.shrink();
  Widget _buildCoachBanner(TransactionsProvider provider) => const SizedBox.shrink();

  Widget _buildDotGrid() {
    return Opacity(
      opacity: 0.3,
      child: CustomPaint(
        size: Size.infinite,
        painter: DotGridPainter(color: Colors.grey.withValues(alpha: 0.1)),
      ),
    );
  }

  void _showQuickAdd(BuildContext context, TransactionsProvider provider, {required TransactionType type}) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    
    String? selectedCategory;
    String? selectedAccountId = provider.wallets.isNotEmpty ? provider.wallets.first.id : null;

    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<List<String>>(
          stream: RealtimeDbService().getCategories(),
          builder: (context, snapshot) {
            final customCategories = snapshot.data ?? [];
            final defaultCatNames = ['Comida', 'Transporte', 'Lazer', 'Saúde'];
            
            final List<String> categories = [];
            if (provider.isBusinessMode) {
              categories.addAll(
                provider.omieCategories.values.map((v) => v.toString()).toSet().toList()
              );
            } else {
              categories.addAll(
                {...defaultCatNames, ...customCategories}.toList()
              );
            }
            if (categories.isEmpty) {
              categories.addAll(defaultCatNames);
            }

            return StatefulBuilder(
              builder: (context, setDialogState) {
                // Garantir que a categoria selecionada é válida e pertence à lista
                if (selectedCategory == null || !categories.contains(selectedCategory)) {
                  selectedCategory = categories.first;
                }

                return AlertDialog(
                  backgroundColor: AppTheme.surface,
                  title: Text(
                    type == TransactionType.expense ? 'Nova Despesa 🔴' : 'Nova Receita 🟢',
                    style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: descController,
                          style: const TextStyle(color: AppTheme.textBody),
                          decoration: const InputDecoration(
                            labelText: 'Descrição / Título',
                            labelStyle: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: AppTheme.textBody),
                          decoration: const InputDecoration(
                            labelText: 'Valor (R\$)',
                            prefixText: 'R\$ ',
                            labelStyle: TextStyle(color: AppTheme.textMuted),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          dropdownColor: AppTheme.surface,
                          style: const TextStyle(color: AppTheme.textBody),
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            labelStyle: TextStyle(color: AppTheme.textMuted),
                          ),
                          items: categories.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedCategory = val);
                            }
                          },
                        ),
                        if (provider.wallets.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedAccountId,
                            dropdownColor: AppTheme.surface,
                            style: const TextStyle(color: AppTheme.textBody),
                            decoration: const InputDecoration(
                              labelText: 'Conta / Carteira',
                              labelStyle: TextStyle(color: AppTheme.textMuted),
                            ),
                            items: provider.wallets.map((w) {
                              return DropdownMenuItem(
                                value: w.id,
                                child: Text(w.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedAccountId = val);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final double? val = double.tryParse(amountController.text.replaceAll(',', '.'));
                        if (val == null || val <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, insira um valor válido.')),
                          );
                          return;
                        }
                        if (descController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, insira uma descrição.')),
                          );
                          return;
                        }
                        
                        provider.addTransaction(TransactionModel(
                          id: '',
                          amount: val,
                          category: selectedCategory!,
                          description: descController.text,
                          date: DateTime.now(),
                          type: type,
                          accountId: selectedAccountId,
                        ));
                        
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${type == TransactionType.expense ? 'Despesa' : 'Receita'} adicionada com sucesso!')),
                        );
                      },
                      child: const Text('SALVAR'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showTransferModal(BuildContext context, TransactionsProvider provider) {
    if (provider.wallets.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa cadastrar pelo menos duas carteiras/contas para fazer transferências.'),
          backgroundColor: AppTheme.expense,
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    final descController = TextEditingController();

    String fromAccountId = provider.wallets.first.id;
    String toAccountId = provider.wallets[1].id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text(
                'Transferência entre Contas 🔄',
                style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: fromAccountId,
                      dropdownColor: AppTheme.surface,
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(
                        labelText: 'Origem',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                      items: provider.wallets.map((w) {
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text(w.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            fromAccountId = val;
                            if (fromAccountId == toAccountId) {
                              toAccountId = provider.wallets.firstWhere((w) => w.id != fromAccountId).id;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: toAccountId,
                      dropdownColor: AppTheme.surface,
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(
                        labelText: 'Destino',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                      items: provider.wallets.where((w) => w.id != fromAccountId).map((w) {
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text(w.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => toAccountId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(
                        labelText: 'Valor (R\$)',
                        prefixText: 'R\$ ',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: AppTheme.textBody),
                      decoration: const InputDecoration(
                        labelText: 'Observação (Opcional)',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
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
                ElevatedButton(
                  onPressed: () {
                    final double? val = double.tryParse(amountController.text.replaceAll(',', '.'));
                    if (val == null || val <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, insira um valor válido.')),
                      );
                      return;
                    }
                    
                    provider.transferBetweenWallets(
                      fromAccountId,
                      toAccountId,
                      val,
                      descController.text.trim().isEmpty ? 'Transferência' : descController.text.trim(),
                    );
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transferência realizada com sucesso!')),
                    );
                  },
                  child: const Text('TRANSFERIR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  DashboardType _getDashboardTypeFromIndex(int index) {
    switch (index) {
      case 0: return DashboardType.summary;
      case 1: return DashboardType.forecast;
      case 2: return DashboardType.dre;
      case 3: return DashboardType.os;
      case 4: return DashboardType.map;
      default: return DashboardType.summary;
    }
  }
}

class DotGridPainter extends CustomPainter {
  final Color color;
  DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const double spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ConfettiParticle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble() * -1;
  double size = math.Random().nextDouble() * 8 + 4;
  Color color = [
    Colors.blueAccent,
    Colors.cyanAccent,
    Colors.white,
    Colors.greenAccent,
    Colors.orangeAccent
  ][math.Random().nextInt(5)];
  double speed = math.Random().nextDouble() * 0.02 + 0.01;
  double angle = math.Random().nextDouble() * math.pi * 2;

  void update() {
    y += speed;
    x += math.sin(y * 10) * 0.002;
    if (y > 1.2) {
      y = -0.1;
      x = math.Random().nextDouble();
    }
  }
}
