import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/omie_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/bpo_pdf_service.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'login_screen.dart';
import 'user_profile_screen.dart';
import '../services/realtime_db_service.dart';
import '../core/app_theme.dart';
import '../models/transaction_model.dart';
import '../widgets/bpo/link_client_dialog.dart';
import '../widgets/bpo/edit_client_settings_dialog.dart';
import '../widgets/bpo/send_message_to_client_dialog.dart';
import '../widgets/bpo/send_message_to_all_clients_dialog.dart';

class BpoTowerScreen extends StatefulWidget {
  final bool isHomeScreen;
  const BpoTowerScreen({super.key, this.isHomeScreen = false});

  @override
  State<BpoTowerScreen> createState() => _BpoTowerScreenState();
}

class _BpoTowerScreenState extends State<BpoTowerScreen> with TickerProviderStateMixin {
  final RealtimeDbService _db = RealtimeDbService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late AnimationController _pulseController;
  
  String _searchQuery = '';
  String _selectedRegimeFilter = 'Todos';
  String _selectedTagFilter = 'Todas';
  bool _isLinking = false;
  
  String? _activeClientUid = RealtimeDbService.bpoActiveClientUid;
  String? _activeClientName;
  Map<String, dynamic>? _activeClientMap;
  String? _bpoFilterCategory = 'Todas';
  DateTimeRange? _bpoFilterPeriod;

  final _revenueGoalController = TextEditingController();
  final _bpoMessageController = TextEditingController();

  // Cache para dados de clientes (Health Score)
  final Map<String, _ClientSnap> _clientSnapsCache = {};
  bool _loadingSnaps = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    _loadClientSnaps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    _revenueGoalController.dispose();
    _bpoMessageController.dispose();
    super.dispose();
  }

  // Carregar snapshots financeiros para cálculo do Health Score
  Future<void> _loadClientSnaps() async {
    setState(() => _loadingSnaps = true);
    try {
      final clients = await _db.getBpoClients().first;
      for (var c in clients) {
        final uid = c['id'] ?? '';
        if (uid.isNotEmpty) {
          final snap = await _fetchSnap(uid);
          _clientSnapsCache[uid] = snap;
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados financeiros para Health Score: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingSnaps = false);
      }
    }
  }

  // ── Client Activation ────────────────────────────────────────────────────

  void _setActiveClient(String? uid, String? name, [Map<String, dynamic>? clientMap]) {
    setState(() {
      _activeClientUid = uid;
      _activeClientName = name;
      _activeClientMap = clientMap;
    });
    _db.setBpoActiveClient(uid);
    final msg = uid != null ? '✅ Visualizando: ${name ?? uid}' : '↩️ Voltou para sua visão';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: uid != null ? const Color(0xFF7C3AED) : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void stateSet(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  // ── dialogs ──────────────────────────────────────────────────────────────

  Future<void> _showLinkClientDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const LinkClientDialog(),
    );
    if (result != null) {
      final uid = result['uid']!;
      final name = result['name']!;
      final phone = result['phone']!;
      setState(() => _isLinking = true);
      final ok = await _db.linkClientToBpo(uid, name, phone: phone);
      if (!mounted) return;
      setState(() => _isLinking = false);
      _loadClientSnaps();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ $name vinculado!' : '❌ Cliente não encontrado.'),
        backgroundColor: ok ? AppTheme.income : AppTheme.expense,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Notes Bottom Sheet ───────────────────────────────────────────────────

  void _showNotesSheet(String clientUid, String clientName) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StreamBuilder<String?>(
          stream: _db.getClientNote(clientUid),
          builder: (ctx2, snap) {
            if (ctrl.text.isEmpty && snap.hasData && snap.data != null) {
              ctrl.text = snap.data!;
            }
            return Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(children: [
                  const Icon(Icons.sticky_note_2_rounded, color: Color(0xFF7C3AED), size: 22),
                  const SizedBox(width: 10),
                  Text('Notas: $clientName', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textBody)),
                ]),
                const SizedBox(height: 4),
                Text('Anotações internas visíveis apenas para você.', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl, maxLines: 6, autofocus: true,
                  style: const TextStyle(color: AppTheme.textBody, fontSize: 14, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Ex: Verificar DAS de abril. Reunião em 15/07...',
                    hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.3), fontSize: 13),
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.07))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: () async {
                    await _db.saveClientNote(clientUid, ctrl.text.trim());
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('📝 Nota salva!'), behavior: SnackBarBehavior.floating,
                    ));
                  },
                  icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                  label: const Text('SALVAR NOTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                )),
              ]),
            );
          },
        ),
      ),
    );
  }

  // ── Edit Client Settings Dialog (Regime, Tags & Faturamento) ─────────────

  Future<void> _showEditClientSettingsDialog(Map<String, dynamic> client) async {
    await showDialog(
      context: context,
      builder: (ctx) => EditClientSettingsDialog(
        client: client,
        db: _db,
        onSuccess: _loadClientSnaps,
      ),
    );
  }

  Future<void> _cobrarClienteViaWhatsApp(Map<String, dynamic> client) async {
    final clientUid = client['id'] ?? '';
    final clientName = client['name'] ?? 'Cliente';

    double amount = 0.0;
    int dueDay = 5;
    String? phone = client['phone']?.toString();

    try {
      final fees = await _db.getBpoFees().first;
      final feeData = fees[clientUid] as Map? ?? {};
      amount = double.tryParse(feeData['amount']?.toString() ?? '0') ?? 0.0;
      dueDay = int.tryParse(feeData['dueDay']?.toString() ?? '5') ?? 5;
      if (feeData['phone'] != null && feeData['phone'].toString().isNotEmpty) {
        phone = feeData['phone'].toString();
      }
    } catch (_) {}

    // Fallback: Buscar telefone direto do perfil público do cliente caso ainda esteja vazio no BPO
    if ((phone == null || phone.trim().isEmpty) && clientUid.isNotEmpty) {
      try {
        final profileSnap = await FirebaseDatabase.instance.ref('users/$clientUid/profile').get();
        if (profileSnap.exists && profileSnap.value is Map) {
          final profileData = Map<String, dynamic>.from(profileSnap.value as Map);
          phone = profileData['phone']?.toString();
        }
      } catch (_) {}
    }

    if (amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ Este cliente não possui valor de honorários configurado!'),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    final String cleanPhone = (phone ?? '').replaceAll(RegExp(r'\D'), '');

    if (cleanPhone.isEmpty) {
      final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
      final message = 'Olá, $clientName! Lembramos que o seu honorário mensal de ${currency.format(amount)} está pendente com vencimento para o dia $dueDay. Por favor, realize o pagamento diretamente pelo app. Obrigado!';
      
      await _db.saveBpoClientMessage(clientUid, message, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('📢 WhatsApp não configurado! Aviso de cobrança enviado direto no painel do cliente no app.'),
        backgroundColor: Color(0xFF7C3AED),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final message = Uri.encodeComponent(
      'Olá, $clientName! Tudo bem?\n\nLembramos que o honorário do BPO Financeiro deste mês (no valor de ${currency.format(amount)}) está pendente com vencimento para o dia $dueDay. \n\nSe precisar da segunda via ou do pix, por favor me avise! Obrigado! 👍'
    );
    
    final String ddi = cleanPhone.startsWith('55') ? '' : '55';
    final url = 'https://wa.me/$ddi$cleanPhone?text=$message';
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _showConfigureBpoPixDialog() async {
    final pixCtrl = TextEditingController();
    
    // Obter chave Pix atual do BPO
    final currentPix = await _db.getPixKey().first;
    pixCtrl.text = currentPix;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.pix_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Minha Chave Pix BPO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textBody)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configure a chave Pix que os seus clientes vão visualizar no aplicativo para realizar o pagamento dos honorários contábeis.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4)),
            const SizedBox(height: 16),
            TextField(
              controller: pixCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'E-mail, CPF, CNPJ ou chave aleatória',
                filled: true, fillColor: const Color(0xFFF8FAFC),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final key = pixCtrl.text.trim();
              await _db.savePixKey(key);
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Chave Pix do BPO atualizada!'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('SALVAR CHAVE', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> _showSendMessageToAllClientsDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const SendMessageToAllClientsDialog(),
    );
    if (result != null) {
      final text = result['message'] as String;
      final visibleToClient = result['visible'] as bool;
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⏳ Enviando avisos em lote...'),
        duration: Duration(seconds: 1),
      ));

      try {
        final clients = await _db.getBpoClients().first;
        for (var client in clients) {
          final uid = client['id'] ?? '';
          if (uid.isNotEmpty) {
            await _db.saveBpoClientMessage(uid, text, visibleToClient);
          }
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('📢 Aviso disparado com sucesso para toda a base de clientes!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Falha ao enviar aviso: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Send Alert Message to Client Dialog ──────────────────────────────────

  Future<void> _showSendMessageToClientDialog(Map<String, dynamic> client) async {
    await showDialog(
      context: context,
      builder: (ctx) => SendMessageToClientDialog(
        client: client,
        db: _db,
      ),
    );
  }

  // ── Generate Report PDF Dialog ───────────────────────────────────────────

  Future<void> _showGeneratePdfDialog(Map<String, dynamic> client) async {
    final clientUid = client['id'] ?? '';
    final clientName = client['name'] ?? '';
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Relatório de $clientName', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Escreva seu parecer técnico ou recomendações que serão incluídas na seção "Nota Estratégica do Contador".',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4)),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              maxLines: 5,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ex: Sugerimos reduzir as despesas operacionais da categoria marketing para garantir maior fôlego de caixa.',
                filled: true, fillColor: const Color(0xFFF8FAFC),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              final snap = _clientSnapsCache[clientUid] ?? await _fetchSnap(clientUid);
              await _generateAndPrintExecutivePdf(clientName, client['regime']?.toString() ?? 'MEI', snap, notesCtrl.text.trim());
            },
            child: const Text('GERAR PDF'),
          )
        ],
      ),
    );
  }

  // Geração do PDF em si
  Future<void> _generateAndPrintExecutivePdf(String clientName, String regime, _ClientSnap snap, String accountantNotes) async {
    await BpoPdfService.generateAndPrintExecutivePdf(
      clientName: clientName,
      regime: regime,
      snap: BpoClientSnap(income: snap.income, expense: snap.expense, txCount: snap.txCount),
      accountantNotes: accountantNotes,
    );
  }

  // ── Adicionar Tarefa Fiscal Dialog ───────────────────────────────────────

  Future<void> _showAddFiscalEventDialog(String clientUid, String clientName) async {
    final titleCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String selectedType = 'Guia de Imposto';

    final types = ['Guia de Imposto', 'Folha de Pagamento', 'Declaração', 'Documentação', 'Outro'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Obrigação para $clientName', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Título da obrigação',
                  hintText: 'Ex: Enviar DAS Junho',
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Tipo de Obrigação',
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
                ),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data de Vencimento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.calendar_month_rounded, color: Color(0xFF7C3AED)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await _db.addBpoClientFiscalEvent(clientUid, {
                  'title': titleCtrl.text.trim(),
                  'type': selectedType,
                  'dueDate': selectedDate.toIso8601String(),
                  'isDone': false,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📅 Obrigação agendada!'), behavior: SnackBarBehavior.floating));
              },
              child: const Text('AGENDAR'),
            )
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(children: [
        // Header
        _buildHeader(currency),
        // Active Client Banner
        if (_activeClientUid != null) _buildActiveBanner(),
        // TabBar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF7C3AED),
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: const Color(0xFF7C3AED),
            indicatorWeight: 2.5,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
            tabs: const [
              Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Clientes'),
              Tab(icon: Icon(Icons.calendar_month_rounded, size: 18), text: 'Agenda Fiscal'),
              Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 18), text: 'Conciliar 🏦'),
              Tab(icon: Icon(Icons.analytics_rounded, size: 18), text: 'DRE & Metas'),
              Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Comparativo'),
              Tab(icon: Icon(Icons.timeline_rounded, size: 18), text: 'Atividade'),
              Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Auditoria'),
            ],
          ),
        ),
        // Tab Content
        Expanded(child: TabBarView(controller: _tabController, children: [
          KeepAliveWrapper(child: _buildClientesTab(currency)),
          KeepAliveWrapper(child: _buildCalendarioTab()),
          KeepAliveWrapper(child: _buildConciliacaoTab(currency)),
          KeepAliveWrapper(child: _buildDreAndMetasTab(currency)),
          KeepAliveWrapper(child: _buildComparativoTab(currency)),
          KeepAliveWrapper(child: _buildAtividadeTab(currency)),
          KeepAliveWrapper(child: _buildAuditoriaTab()),
        ])),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLinking ? null : _showLinkClientDialog,
        backgroundColor: const Color(0xFF7C3AED),
        icon: _isLinking
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(_isLinking ? 'Vinculando...' : 'Vincular Cliente',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (!widget.isHomeScreen) ...[
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              style: IconButton.styleFrom(backgroundColor: Colors.white10, padding: const EdgeInsets.all(10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(width: 14),
          ] else ...[
            IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              tooltip: 'Sair da Conta',
              style: IconButton.styleFrom(backgroundColor: Colors.white10, padding: const EdgeInsets.all(10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Torre BPO', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            Text('Painel unificado de clientes', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          ])),
          IconButton(
            icon: const Icon(Icons.pix_rounded, color: Colors.white, size: 20),
            tooltip: 'Configurar Minha Chave Pix Recebedora',
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15), padding: const EdgeInsets.all(10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _showConfigureBpoPixDialog,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
            tooltip: 'Enviar Aviso em Lote (Todos os Clientes)',
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15), padding: const EdgeInsets.all(10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _showSendMessageToAllClientsDialog,
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              if (uid.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: uid));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('✅ Seu ID copiado! Envie ao cliente.'), behavior: SnackBarBehavior.floating));
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
              child: Row(children: [
                const Icon(Icons.copy_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text('Meu ID', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 20),
            tooltip: 'Configurações de Perfil',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserProfileScreen()),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _db.getBpoClients(),
          builder: (ctx, snap) {
            final count = snap.data?.length ?? 0;
            return Row(children: [
              _headerStat('Clientes', count.toString(), Icons.people_rounded),
              const SizedBox(width: 10),
              _headerStat('Ativos', count.toString(), Icons.check_circle_outline),
              const SizedBox(width: 10),
              _headerStat('Saúde Geral', _loadingSnaps ? '...' : _calculateGeneralHealth(), Icons.favorite_rounded),
            ]);
          },
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _headerStat(String label, String value, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
      child: Column(children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 10)),
      ]),
    ));
  }

  Widget _buildActiveBanner() {
    final uid = _activeClientUid!;
    final name = _activeClientName ?? 'Cliente';
    final clientMap = _activeClientMap;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.5 + _pulseController.value * 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLIENTE SOB GESTÃO ATIVA',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: GoogleFonts.outfit(color: AppTheme.textBody, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _setActiveClient(null, null),
                  icon: const Icon(Icons.exit_to_app_rounded, color: Color(0xFF7C3AED), size: 14),
                  label: const Text('SAIR', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 11, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5, color: Colors.black12),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickActionButton(
                    icon: Icons.sticky_note_2_rounded,
                    label: 'Notas Internas',
                    color: Colors.amber,
                    onTap: () => _showNotesSheet(uid, name),
                  ),
                  const SizedBox(width: 8),
                  if (clientMap != null) ...[
                    _quickActionButton(
                      icon: Icons.campaign_rounded,
                      label: 'Enviar Aviso',
                      color: const Color(0xFF7C3AED),
                      onTap: () => _showSendMessageToClientDialog(clientMap),
                    ),
                    const SizedBox(width: 8),
                    _quickActionButton(
                      icon: Icons.monetization_on_rounded,
                      label: 'Cobrar Cliente',
                      color: const Color(0xFF10B981),
                      onTap: () => _cobrarClienteViaWhatsApp(clientMap),
                    ),
                    const SizedBox(width: 8),
                    _quickActionButton(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'PDF Executivo',
                      color: Colors.redAccent,
                      onTap: () => _showGeneratePdfDialog(clientMap),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _quickActionButton(
                    icon: Icons.calendar_today_rounded,
                    label: 'Agendar Guia',
                    color: Colors.blueAccent,
                    onTap: () => _showAddFiscalEventDialog(uid, name),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(color: AppTheme.textBody, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: Clientes ──────────────────────────────────────────────────────

  Widget _buildClientesTab(NumberFormat currency) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(children: [
        // 🏥 Health Score Summary Card
        if (!_loadingSnaps && _clientSnapsCache.isNotEmpty) _buildHealthScoreSummary(),

        // 📊 Honorários BPO Analytics (Donut)
        _buildHonorariosAnalyticsCard(currency),

        // Filters & Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: AppTheme.textBody, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente...', hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                    filled: true, fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.07))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textMuted), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                      : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filtro por Regime
              _buildRegimeFilterDropdown(),
            ],
          ),
        ),

        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _db.getBpoClients(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
            
            var clients = snap.data ?? [];
            
            // Aplicar Busca
            if (_searchQuery.isNotEmpty) {
              clients = clients.where((c) => (c['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
            }

            // Aplicar Filtro de Regime
            if (_selectedRegimeFilter != 'Todos') {
              clients = clients.where((c) => (c['regime'] ?? 'MEI') == _selectedRegimeFilter).toList();
            }

            if (clients.isEmpty) return _emptyClients();
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: clients.length,
              itemBuilder: (ctx, i) => _clientCard(clients[i], currency, i),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildRegimeFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRegimeFilter,
          dropdownColor: Colors.white,
          style: const TextStyle(color: AppTheme.textBody, fontSize: 13, fontWeight: FontWeight.w600),
          items: ['Todos', 'MEI', 'Simples Nacional', 'Lucro Presumido', 'Lucro Real']
              .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedRegimeFilter = val);
          },
        ),
      ),
    );
  }

  Widget _buildHealthScoreSummary() {
    int total = _clientSnapsCache.length;
    int healthy = 0;
    int critical = 0;
    int inactive = 0;

    _clientSnapsCache.forEach((_, snap) {
      if (snap.txCount == 0) {
        inactive++;
      } else if (snap.income - snap.expense >= 0) {
        healthy++;
      } else {
        critical++;
      }
    });

    final int healthScorePct = total > 0 ? ((healthy / total) * 100).toInt() : 100;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Painel de Saúde da Carteira', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('$healthScorePct% Saudável', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _healthItemStat('Saudáveis', healthy.toString(), const Color(0xFF10B981)),
              _healthItemDivider(),
              _healthItemStat('Atenção/Crítico', critical.toString(), const Color(0xFFEF4444)),
              _healthItemDivider(),
              _healthItemStat('Inativos', inactive.toString(), const Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.05);
  }

  Widget _healthItemStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _healthItemDivider() => Container(width: 1, height: 24, color: Colors.white10);

  String _calculateGeneralHealth() {
    if (_clientSnapsCache.isEmpty) return '100%';
    int healthy = 0;
    _clientSnapsCache.forEach((_, snap) {
      if (snap.income - snap.expense >= 0) healthy++;
    });
    return '${((healthy / _clientSnapsCache.length) * 100).toStringAsFixed(0)}%';
  }

  Widget _clientCard(Map<String, dynamic> client, NumberFormat currency, int index) {
    final uid = client['id'] ?? '';
    final name = client['name'] ?? 'Cliente';
    final phone = client['phone']?.toString();
    final regime = client['regime']?.toString() ?? 'MEI';
    final tags = (client['tags'] as List?)?.map((t) => t.toString()).toList() ?? [];
    final isActive = _activeClientUid == uid;

    final data = _clientSnapsCache[uid];
    final status = _status(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? const Color(0xFF7C3AED).withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.05), width: isActive ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Row: Avatar + name + status + actions menu
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
          child: Row(children: [
            _avatar(name, status),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Expanded(child: Text(name, style: GoogleFonts.outfit(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF4F46E5).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                    child: Text(regime, style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(
                    spacing: 4, runSpacing: 4,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                      child: Text('#$t', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                    )).toList(),
                  ),
                ),
              if (phone != null && phone.isNotEmpty)
                Text(phone, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ])),
            const SizedBox(width: 6),
            _statusBadge(status),
            
            // Actions Popup Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
              color: Colors.white,
              onSelected: (val) {
                switch (val) {
                  case 'notes':
                    _showNotesSheet(uid, name);
                    break;
                  case 'config':
                    _showEditClientSettingsDialog(client);
                    break;
                  case 'message':
                    _showSendMessageToClientDialog(client);
                    break;
                  case 'pdf':
                    _showGeneratePdfDialog(client);
                    break;
                  case 'agenda':
                    _showAddFiscalEventDialog(uid, name);
                    break;
                  case 'cobrar':
                    _cobrarClienteViaWhatsApp(client);
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'notes', child: Row(children: [Icon(Icons.sticky_note_2_rounded, size: 18), SizedBox(width: 8), Text('Notas Internas')])),
                const PopupMenuItem(value: 'config', child: Row(children: [Icon(Icons.settings_rounded, size: 18), SizedBox(width: 8), Text('Regime, Tags & Faturamento')])),
                const PopupMenuItem(value: 'message', child: Row(children: [Icon(Icons.mail_rounded, size: 18), SizedBox(width: 8), Text('Enviar Aviso')])),
                const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf_rounded, size: 18), SizedBox(width: 8), Text('Gerar PDF Executivo')])),
                const PopupMenuItem(value: 'agenda', child: Row(children: [Icon(Icons.calendar_today_rounded, size: 18), SizedBox(width: 8), Text('Agendar Obrigação')])),
                const PopupMenuItem(value: 'cobrar', child: Row(children: [Icon(Icons.monetization_on_rounded, size: 18, color: Color(0xFF10B981)), SizedBox(width: 8), Text('Cobrar Cliente')])),
              ],
            ),
          ]),
        ),
        // Financial row
        if (data != null)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withValues(alpha: 0.04))),
            child: Row(children: [
              _financeStat('Receitas', currency.format(data.income), AppTheme.income),
              _vDivider(),
              _financeStat('Despesas', currency.format(data.expense), AppTheme.expense),
              _vDivider(),
              _financeStat('Saldo', currency.format(data.income - data.expense), (data.income - data.expense) >= 0 ? AppTheme.income : AppTheme.expense),
            ]),
          ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () { Clipboard.setData(ClipboardData(text: uid)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UID copiado'), behavior: SnackBarBehavior.floating)); },
              icon: const Icon(Icons.copy_rounded, size: 14), label: const Text('Copiar ID', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textMuted, side: BorderSide(color: Colors.black.withValues(alpha: 0.1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 9)),
            )),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: ElevatedButton.icon(
              onPressed: () => isActive ? _setActiveClient(null, null) : _setActiveClient(uid, name, client),
              icon: Icon(isActive ? Icons.exit_to_app_rounded : Icons.visibility_rounded, size: 15, color: Colors.white),
              label: Text(isActive ? 'Sair' : 'Acessar Cliente', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: isActive ? AppTheme.expense : const Color(0xFF7C3AED), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 9)),
            )),
          ]),
        ),
      ]),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideY(begin: 0.08);
  }

  Widget _emptyClients() => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.06), shape: BoxShape.circle), child: const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF7C3AED))),
      const SizedBox(height: 20),
      Text('Nenhum cliente correspondente', style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textBody)),
      const SizedBox(height: 8),
      Text('Verifique as buscas ou limpe os filtros de regime tributário.', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
    ]),
  ).animate().fadeIn(duration: 500.ms));

  // ── TAB 2: Calendário Fiscal Consolidado ──────────────────────────────────

  Widget _buildCalendarioTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getBpoClients(),
      builder: (ctx, clientsSnap) {
        if (clientsSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
        }
        final clients = clientsSnap.data ?? [];
        if (clients.isEmpty) return _emptyClients();

        // Extrair e consolidar todas as obrigações fiscais diretamente do snapshot dos clientes
        final List<Map<String, dynamic>> events = [];
        for (var client in clients) {
          final clientUid = client['id'] ?? '';
          final clientName = client['name'] ?? 'Cliente';
          final fiscalCalendar = client['fiscal_calendar'] as Map?;
          if (fiscalCalendar != null) {
            fiscalCalendar.forEach((eventId, eventData) {
              if (eventData is Map) {
                events.add({
                  ...Map<String, dynamic>.from(eventData),
                  'id': eventId,
                  '_clientName': clientName,
                  '_clientUid': clientUid,
                });
              }
            });
          }
        }

        // Ordenar por data de vencimento
        events.sort((a, b) {
          final dA = DateTime.tryParse(a['dueDate'] ?? '') ?? DateTime(2050);
          final dB = DateTime.tryParse(b['dueDate'] ?? '') ?? DateTime(2050);
          return dA.compareTo(dB);
        });

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_rounded, size: 48, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                Text('Nenhuma obrigação agendada', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (ctx, i) {
            final ev = events[i];
            final id = ev['id'] ?? '';
            final title = ev['title'] ?? 'Obrigação';
            final type = ev['type'] ?? 'Outro';
            final isDone = ev['isDone'] ?? false;
            final clientName = ev['_clientName'] ?? '';
            final clientUid = ev['_clientUid'] ?? '';
            final dueDate = DateTime.tryParse(ev['dueDate'] ?? '') ?? DateTime.now();

            final bool isOverdue = !isDone && dueDate.isBefore(DateTime.now());

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isDone,
                    activeColor: const Color(0xFF7C3AED),
                    onChanged: (val) async {
                      if (val != null) {
                        await _db.toggleBpoClientFiscalEventStatus(clientUid, id, val);
                        await _db.addAuditLog({
                          'action': val ? 'fiscal_done' : 'fiscal_undone',
                          'description': 'Obrigação fiscal: $title',
                          'clientName': clientName,
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, decoration: isDone ? TextDecoration.lineThrough : null, color: isDone ? AppTheme.textMuted : AppTheme.textBody)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(clientName, style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                              child: Text(type, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(dueDate), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOverdue ? const Color(0xFFEF4444) : AppTheme.textMuted)),
                      if (isOverdue)
                        const Text('Atrasado', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.bold))
                      else if (isDone)
                        const Text('Concluído', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.expense, size: 18),
                    onPressed: () async {
                      await _db.deleteBpoClientFiscalEvent(clientUid, id);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── TAB 3: Comparativo ───────────────────────────────────────────────────

  Widget _buildComparativoTab(NumberFormat currency) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getBpoClients(),
      builder: (ctx, snap) {
        final clients = snap.data ?? [];
        if (clients.isEmpty) return _emptyClients();
        return FutureBuilder<List<_ClientWithSnap>>(
          future: Future.wait(clients.map((c) async {
            final snap = await _fetchSnap(c['id'] ?? '');
            return _ClientWithSnap(name: c['name'] ?? 'Cliente', uid: c['id'] ?? '', snap: snap);
          })),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
            final data = snap.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Comparativo Financeiro', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBody)),
                Text('Receitas vs. Despesas do mês atual por cliente', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 20),
                // Chart
                Container(
                  height: 280,
                  padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12)]),
                  child: BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: data.map((d) => [d.snap.income, d.snap.expense]).expand((x) => x).fold<double>(0, (a, b) => b > a ? b : a) * 1.3 + 100,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                          '${rodIndex == 0 ? "Receita" : "Despesa"}\n${currency.format(rod.toY)}',
                          TextStyle(color: rodIndex == 0 ? AppTheme.income : AppTheme.expense, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= data.length) return const SizedBox();
                          final name = data[i].name;
                          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(
                            name.length > 8 ? '${name.substring(0, 7)}...' : name,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                          ));
                        },
                      )),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1000,
                      getDrawingHorizontalLine: (_) => FlLine(color: Colors.black.withValues(alpha: 0.04), strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(data.length, (i) => BarChartGroupData(
                      x: i, barRods: [
                        BarChartRodData(toY: data[i].snap.income, color: AppTheme.income, width: 14, borderRadius: BorderRadius.circular(6)),
                        BarChartRodData(toY: data[i].snap.expense, color: AppTheme.expense, width: 14, borderRadius: BorderRadius.circular(6)),
                      ],
                    )),
                  )),
                ),
                const SizedBox(height: 12),
                // Legend
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _legendDot(AppTheme.income, 'Receitas'),
                  const SizedBox(width: 20),
                  _legendDot(AppTheme.expense, 'Despesas'),
                ]),
                const SizedBox(height: 24),
                // Summary cards
                Text('Ranking de Clientes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textBody)),
                const SizedBox(height: 12),
                ...data.sorted.asMap().entries.map((e) => _rankCard(e.key + 1, e.value, currency)),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  ]);

  Widget _rankCard(int rank, _ClientWithSnap c, NumberFormat currency) {
    final profit = c.snap.income - c.snap.expense;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)]),
      child: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(
          color: rank == 1 ? Colors.amber.withValues(alpha: 0.15) : rank == 2 ? Colors.grey.withValues(alpha: 0.1) : Colors.brown.withValues(alpha: 0.08),
          shape: BoxShape.circle),
          child: Center(child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
            color: rank == 1 ? Colors.amber.shade700 : rank == 2 ? Colors.grey.shade600 : Colors.brown.shade400)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody, fontSize: 14)),
          Text('Rec: ${currency.format(c.snap.income)} · Desp: ${currency.format(c.snap.expense)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ])),
        Text(currency.format(profit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: profit >= 0 ? AppTheme.income : AppTheme.expense)),
      ]),
    );
  }

  // ── TAB 4: Atividade ─────────────────────────────────────────────────────

  Widget _buildAtividadeTab(NumberFormat currency) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getBpoClients(),
      builder: (ctx, snap) {
        final clients = snap.data ?? [];
        if (clients.isEmpty) return _emptyClients();
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(clients.map((c) => _db.getClientRecentTransactions(c['id'] ?? '', limit: 5).then(
            (txs) => txs.map((t) => {...t, '_clientName': c['name'] ?? 'Cliente'}).toList())))
            .then((lists) {
              final all = lists.expand((l) => l).toList();
              all.sort((a, b) {
                final dA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
                final dB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
                return dB.compareTo(dA);
              });
              return all.take(40).toList();
            }),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
            final txs = snap.data!;
            if (txs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.timeline_rounded, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text('Nenhuma atividade recente', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 16)),
            ]));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: txs.length,
              itemBuilder: (ctx, i) {
                final tx = txs[i];
                final isIncome = (tx['type'] ?? '') == 'income';
                final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
                final date = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
                  child: Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: (isIncome ? AppTheme.income : AppTheme.expense).withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isIncome ? AppTheme.income : AppTheme.expense, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tx['_clientName'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(tx['description'] ?? tx['category'] ?? '—', style: const TextStyle(color: AppTheme.textBody, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(tx['category'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(currency.format(amount), style: TextStyle(color: isIncome ? AppTheme.income : AppTheme.expense, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(DateFormat('dd/MM').format(date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ]),
                  ]),
                ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05);
              },
            );
          },
        );
      },
    );
  }

  // ── TAB 5: Auditoria ─────────────────────────────────────────────────────

  Widget _buildAuditoriaTab() {
    final clientUid = _activeClientUid;
    
    if (clientUid == null) {
      return Column(
        children: [
          _buildRadarSelectorBanner(),
          Expanded(child: _buildLogsList(null)),
        ],
      );
    }

    return StreamBuilder<List<TransactionModel>>(
      stream: _db.getClientTransactions(clientUid),
      builder: (context, transSnap) {
        final transactions = transSnap.data ?? [];
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _db.getAuditLogs(),
          builder: (context, logSnap) {
            final logs = logSnap.data ?? [];
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuditRadarPanel(transactions),
                  const SizedBox(height: 32),
                  Text('Logs de Auditoria BPO 📋', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textBody)),
                  const SizedBox(height: 12),
                  _buildLogsSubList(logs, clientUid),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadarSelectorBanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.15), blurRadius: 16)],
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Audit Radar Ativo! 🕵️‍♂️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'Selecione um cliente no cabeçalho para rodar a varredura preventiva de riscos e malha fina fiscal.',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAuditRadarPanel(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final double monthlyIncomes = transactions.where((t) => t.type == TransactionType.income && t.date.month == now.month && t.date.year == now.year).fold(0.0, (sum, t) => sum + t.amount);
    final double fatAnualizado = monthlyIncomes * 12;
    
    final double monthlyExpenses = transactions.where((t) => t.type == TransactionType.expense && t.date.month == now.month && t.date.year == now.year).fold(0.0, (sum, t) => sum + t.amount);
    
    final double despesasGenericas = transactions
        .where((t) => t.type == TransactionType.expense && t.date.month == now.month && t.date.year == now.year && (t.category == 'Outros' || t.category == 'Sem Categoria' || t.category.toLowerCase().contains('outr')))
        .fold(0.0, (sum, t) => sum + t.amount);
    final double pctGenericas = monthlyExpenses > 0 ? (despesasGenericas / monthlyExpenses) : 0.0;

    int score = 100;
    List<Map<String, dynamic>> alertas = [];

    if (fatAnualizado > 70000 && fatAnualizado <= 81000) {
      score -= 15;
      alertas.add({
        'titulo': 'Limite do MEI Próximo ⚠️',
        'desc': 'Faturamento projetado em R\$ ${NumberFormat("#,##0.00", "pt_BR").format(fatAnualizado)}. Risco de desenquadramento.',
        'cor': Colors.orangeAccent,
        'icon': Icons.warning_amber_rounded,
      });
    } else if (fatAnualizado > 81000) {
      score -= 25;
      alertas.add({
        'titulo': 'MEI Excedido (Risco Crítico) 🔴',
        'desc': 'Faturamento projetado em R\$ ${NumberFormat("#,##0.00", "pt_BR").format(fatAnualizado)}. É necessário desenquadrar para o Simples Nacional.',
        'cor': Colors.redAccent,
        'icon': Icons.error_outline_rounded,
      });
    }

    if (pctGenericas > 0.15) {
      score -= 15;
      alertas.add({
        'titulo': 'Despesas Genéricas Elevadas 🟡',
        'desc': '${(pctGenericas * 100).toStringAsFixed(0)}% das despesas como "Outros". Risco de glosa fiscal na contabilidade.',
        'cor': Colors.amber,
        'icon': Icons.folder_open_rounded,
      });
    }

    final bool proLabore = transactions.any((t) => t.category.toLowerCase().contains('pró') || t.category.toLowerCase().contains('prolabore') || t.description.toLowerCase().contains('pró'));
    if (monthlyIncomes > 15000 && !proLabore) {
      score -= 15;
      alertas.add({
        'titulo': 'Ausência de Pró-Labore 🧾',
        'desc': 'Faturamento robusto sem retirada oficial de sócios para INSS e IRPF.',
        'cor': Colors.blueAccent,
        'icon': Icons.assignment_ind_rounded,
      });
    }

    if (alertas.isEmpty) {
      alertas.add({
        'titulo': 'Varredura Limpa! 🟢',
        'desc': 'Nenhum indício de inconformidade fiscal ou risco tributário identificado neste mês.',
        'cor': const Color(0xFF10B981),
        'icon': Icons.verified_user_rounded,
      });
    }

    final Color scoreColor = score >= 80
        ? const Color(0xFF10B981)
        : (score >= 50 ? Colors.orange : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audit Radar 🕵️‍♂️', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  Text('Scanner preventivo contra malha fina e inconformidades', style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('BETA', style: GoogleFonts.outfit(color: const Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(score.toString(), style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('SCORE', style: GoogleFonts.inter(fontSize: 8, color: Colors.white60, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score >= 80 ? 'Risco Baixo' : (score >= 50 ? 'Risco Médio' : 'Risco Crítico'),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: scoreColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analisa inconsistências nos dados de faturamento e despesas do cliente ativo em tempo real.',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Text('Apontamentos de Auditoria', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          ...alertas.map((a) => _buildRadarAlertTile(a)),
        ],
      ),
    );
  }

  Widget _buildRadarAlertTile(Map<String, dynamic> a) {
    final Color color = a['cor'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(a['icon'] as IconData, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['titulo'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(a['desc'] as String, style: GoogleFonts.inter(fontSize: 10, color: Colors.white60, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLogsSubList(List<Map<String, dynamic>> logs, String clientUid) {
    final filtered = logs.where((l) => l['clientUid'] == clientUid).toList();
    if (filtered.isEmpty) {
      return Center(child: Text('Nenhuma ação registrada para este cliente', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)));
    }
    return _buildLogsListFromFiltered(filtered);
  }

  Widget _buildLogsList(String? clientUid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getAuditLogs(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
        final logs = snap.data ?? [];
        final filtered = clientUid == null ? logs : logs.where((l) => l['clientUid'] == clientUid).toList();
        
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_rounded, size: 48, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                Text('Nenhuma ação registrada ainda', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 16)),
              ],
            ),
          );
        }
        return _buildLogsListFromFiltered(filtered);
      },
    );
  }

  Widget _buildLogsListFromFiltered(List<Map<String, dynamic>> filtered) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final log = filtered[i];
        final action = log['action']?.toString() ?? 'reconciled';
        final clientName = log['clientName']?.toString() ?? 'Minha Conta';
        final desc = log['description']?.toString() ?? '';
        final amount = log['amount'] != null ? NumberFormat.simpleCurrency(locale: 'pt_BR').format(double.tryParse(log['amount'].toString()) ?? 0) : '';
        final ts = log['ts'] != null ? DateTime.fromMillisecondsSinceEpoch((log['ts'] as num).toInt()) : DateTime.now();

        final (color, icon, label) = switch (action) {
          'reconciled' => (AppTheme.income, Icons.check_circle_outline_rounded, 'Conciliado'),
          'ignored'    => (AppTheme.textMuted, Icons.block_rounded, 'Ignorado'),
          'undone'     => (AppTheme.expense, Icons.undo_rounded, 'Desfeito'),
          'fiscal_done'=> (AppTheme.income, Icons.check_box_rounded, 'Obrigação Paga'),
          'fiscal_undone'=> (AppTheme.expense, Icons.check_box_outline_blank_rounded, 'Obrigação Revertida'),
          _            => (AppTheme.primary, Icons.info_outline_rounded, action),
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withValues(alpha: 0.05))),
          child: Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 17)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
                const SizedBox(width: 6),
                Text(clientName, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ]),
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(color: AppTheme.textBody, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (amount.isNotEmpty) Text(amount, style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(DateFormat('dd/MM HH:mm').format(ts), style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ]),
          ]),
        ).animate(delay: Duration(milliseconds: i * 30)).fadeIn();
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<_ClientSnap> _fetchSnap(String uid) async {
    try {
      final snap = await FirebaseDatabase.instance.ref('users/$uid/transactions').get();
      double inc = 0, exp = 0; int count = 0;
      final now = DateTime.now();
      if (snap.exists && snap.value is Map) {
        (snap.value as Map).forEach((_, v) {
          if (v is Map) {
            final tx = Map<String, dynamic>.from(v);
            final date = DateTime.tryParse(tx['date'] ?? '') ?? DateTime(2000);
            if (date.year == now.year && date.month == now.month) {
              final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
              if ((tx['type'] ?? '') == 'income') { inc += amt; } else { exp += amt; }
              count++;
            }
          }
        });
      }
      return _ClientSnap(income: inc, expense: exp, txCount: count);
    } catch (_) {
      return _ClientSnap.zero();
    }
  }

  _ClientStatus _status(_ClientSnap? d) {
    if (d == null) return _ClientStatus.unknown;
    if (d.txCount == 0) return _ClientStatus.inactive;
    if (d.income - d.expense >= 0) return _ClientStatus.healthy;
    return _ClientStatus.critical;
  }

  Color _statusColor(_ClientStatus s) => switch(s) {
    _ClientStatus.healthy  => AppTheme.income,
    _ClientStatus.critical => AppTheme.expense,
    _ClientStatus.inactive => AppTheme.textMuted,
    _ClientStatus.unknown  => AppTheme.textMuted,
  };

  String _statusLabel(_ClientStatus s) => switch(s) {
    _ClientStatus.healthy  => 'Saudável',
    _ClientStatus.critical => 'Crítico',
    _ClientStatus.inactive => 'Inativo',
    _ClientStatus.unknown  => '...',
  };

  Widget _avatar(String name, _ClientStatus status) {
    final color = _statusColor(status);
    return Container(width: 44, height: 44,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)]), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))));
  }

  Widget _statusBadge(_ClientStatus s) {
    final color = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(_statusLabel(s), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _financeStat(String label, String value, Color color) => Expanded(child: Column(children: [
    Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
    const SizedBox(height: 3),
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
  ]));

  Widget _vDivider() => Container(width: 1, height: 28, color: Colors.black.withValues(alpha: 0.06));
}

// ── Rx Combine Extension for Streams ───────────────────────────────────────

class Rx {
  static Stream<List<T>> combineLatestList<T>(List<Stream<List<T>>> streams) {
    if (streams.isEmpty) return Stream.value([]);
    
    final controllers = <StreamSubscription>[];
    final latestLists = List<List<T>>.filled(streams.length, []);
    final initialized = List<bool>.filled(streams.length, false);
    
    late StreamController<List<T>> controller;
    
    controller = StreamController<List<T>>(
      onListen: () {
        for (var i = 0; i < streams.length; i++) {
          final subscription = streams[i].listen((data) {
            latestLists[i] = data;
            initialized[i] = true;
            if (initialized.every((init) => init)) {
              controller.add(latestLists.expand((l) => l).toList());
            }
          }, onError: controller.addError, onDone: () {
            if (controllers.every((sub) => sub.isPaused)) {
              controller.close();
            }
          });
          controllers.add(subscription);
        }
      },
      onCancel: () {
        for (final sub in controllers) {
          sub.cancel();
        }
      }
    );
    
    return controller.stream;
  }
}

extension StreamExtensions<T> on Stream<T> {
  Stream<R> switchMap<R>(Stream<R> Function(T) mapper) {
    StreamSubscription<R>? innerSubscription;
    StreamSubscription<T>? outerSubscription;
    late StreamController<R> controller;

    controller = StreamController<R>(
      onListen: () {
        outerSubscription = listen(
          (value) {
            innerSubscription?.cancel();
            innerSubscription = mapper(value).listen(
              controller.add,
              onError: controller.addError,
              onDone: () {},
            );
          },
          onError: controller.addError,
          onDone: () {
            if (innerSubscription == null) {
              controller.close();
            }
          },
        );
      },
      onCancel: () {
        innerSubscription?.cancel();
        outerSubscription?.cancel();
      },
    );

    return controller.stream;
  }
}

// ── Data Models ──────────────────────────────────────────────────────────────

enum _ClientStatus { healthy, critical, inactive, unknown }

class _ClientSnap {
  final double income, expense;
  final int txCount;
  const _ClientSnap({required this.income, required this.expense, required this.txCount});
  factory _ClientSnap.zero() => const _ClientSnap(income: 0, expense: 0, txCount: 0);
}

class _ClientWithSnap {
  final String name, uid;
  final _ClientSnap snap;
  const _ClientWithSnap({required this.name, required this.uid, required this.snap});
}

extension _SortClients on List<_ClientWithSnap> {
  List<_ClientWithSnap> get sorted {
    final copy = [...this];
    copy.sort((a, b) => (b.snap.income - b.snap.expense).compareTo(a.snap.income - a.snap.expense));
    return copy;
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ── Donut Chart Widgets e Painter para BPO 📊 ──

extension _BpoAnalytics on _BpoTowerScreenState {
  Widget _buildHonorariosAnalyticsCard(NumberFormat currency) {
    return StreamBuilder<Map<dynamic, dynamic>>(
      stream: _db.getBpoFees(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final fees = snapshot.data!;
        double totalPago = 0.0;
        double totalPendente = 0.0;

        fees.forEach((clientUid, feeData) {
          if (feeData is Map) {
            final double amount = double.tryParse(feeData['amount']?.toString() ?? '0') ?? 0.0;
            final String status = feeData['status']?.toString() ?? 'Pendente';
            if (status == 'Pago') {
              totalPago += amount;
            } else {
              totalPendente += amount;
            }
          }
        });

        final double totalProjetado = totalPago + totalPendente;
        final double pagoPct = totalProjetado > 0 ? (totalPago / totalProjetado) : 0.0;
        final double pendentePct = totalProjetado > 0 ? (totalPendente / totalProjetado) : 0.0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _DonutChartPainter(pagoPct: pagoPct, pendentePct: pendentePct),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(pagoPct * 100).toInt()}%',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        Text(
                          'Pago',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Honorários do Mês',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textBody,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _analyticRow('Recebidos', totalPago, const Color(0xFF10B981), currency),
                    const SizedBox(height: 6),
                    _analyticRow('Pendentes', totalPendente, const Color(0xFFF59E0B), currency),
                    const Divider(height: 12, thickness: 0.5),
                    _analyticRow('Projetado', totalProjetado, const Color(0xFF4F46E5), currency, isBold: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _analyticRow(String label, double value, Color color, NumberFormat currency, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isBold ? AppTheme.textBody : AppTheme.textMuted,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        Text(
          currency.format(value),
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.textBody,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double pagoPct;
  final double pendentePct;

  _DonutChartPainter({required this.pagoPct, required this.pendentePct});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 7.0;
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    final Paint bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, bgPaint);

    if (pagoPct == 0 && pendentePct == 0) return;

    double startAngle = -math.pi / 2;

    if (pagoPct > 0) {
      final Paint pagoPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final sweepAngle = 2 * math.pi * pagoPct;
      canvas.drawArc(rect, startAngle, sweepAngle, false, pagoPaint);
      startAngle += sweepAngle;
    }

    if (pendentePct > 0) {
      final Paint pendentePaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final sweepAngle = 2 * math.pi * pendentePct;
      canvas.drawArc(rect, startAngle, sweepAngle, false, pendentePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.pagoPct != pagoPct || oldDelegate.pendentePct != pendentePct;
  }
}

// ── TAB: DRE & METAS DE FATURAMENTO CONTÁBIL 📊🎯 ──

extension _DreAndMetasTab on _BpoTowerScreenState {
  Widget _buildDreAndMetasTab(NumberFormat currency) {
    if (_activeClientUid == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.06), shape: BoxShape.circle),
                child: const Icon(Icons.analytics_rounded, size: 48, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(height: 20),
              Text('Visualizar DRE & Metas', style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textBody)),
              const SizedBox(height: 8),
              Text('Acesse ou selecione um cliente na aba "Clientes"\npara ver o Demonstrativo e gerenciar metas.',
                style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final clientUid = _activeClientUid!;
    final clientName = _activeClientName ?? 'Cliente Selecionado';

    return StreamBuilder<List<TransactionModel>>(
      stream: _db.getClientTransactions(clientUid),
      builder: (context, txSnap) {
        final transactions = txSnap.data ?? [];
        
        // 1. Cálculos de DRE Contábil do Mês Atual
        final now = DateTime.now();
        final currentMonthTxs = transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
        
        double totalReceitas = 0.0;
        double totalDespesas = 0.0;
        double impostosTaxas = 0.0;
        double custosOperacionais = 0.0;

        for (var t in currentMonthTxs) {
          if (t.type == TransactionType.income) {
            totalReceitas += t.amount;
          } else {
            totalDespesas += t.amount;
            if (t.category.toLowerCase().contains('imposto') || t.category.toLowerCase().contains('taxa') || t.category.toLowerCase().contains('guia')) {
              impostosTaxas += t.amount;
            } else {
              custosOperacionais += t.amount;
            }
          }
        }

        final double ebitda = totalReceitas - totalDespesas;
        final double margemLucro = totalReceitas > 0 ? (ebitda / totalReceitas) * 100 : 0.0;

        // 2. Gráfico de Evolução dos últimos 5 meses
        final List<DateTime> lastMonths = List.generate(5, (i) => DateTime(now.year, now.month - (4 - i), 1));
        final Map<String, double> incomeByMonth = {};
        final Map<String, double> expenseByMonth = {};
        
        for (var m in lastMonths) {
          final key = '${m.month.toString().padLeft(2, '0')}/${m.year}';
          incomeByMonth[key] = 0.0;
          expenseByMonth[key] = 0.0;
        }

        for (var t in transactions) {
          final key = '${t.date.month.toString().padLeft(2, '0')}/${t.date.year}';
          if (incomeByMonth.containsKey(key)) {
            if (t.type == TransactionType.income) {
              incomeByMonth[key] = (incomeByMonth[key] ?? 0.0) + t.amount;
            } else {
              expenseByMonth[key] = (expenseByMonth[key] ?? 0.0) + t.amount;
            }
          }
        }

        final List<FlSpot> incomeSpots = [];
        final List<FlSpot> expenseSpots = [];
        double maxY = 1000.0;

        for (int i = 0; i < lastMonths.length; i++) {
          final key = '${lastMonths[i].month.toString().padLeft(2, '0')}/${lastMonths[i].year}';
          final inc = incomeByMonth[key] ?? 0.0;
          final exp = expenseByMonth[key] ?? 0.0;
          incomeSpots.add(FlSpot(i.toDouble(), inc));
          expenseSpots.add(FlSpot(i.toDouble(), exp));
          if (inc > maxY) maxY = inc;
          if (exp > maxY) maxY = exp;
        }
        maxY = maxY * 1.25; // 25% de margem no topo

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho da DRE do Cliente
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DRE & Metas — $clientName',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textBody),
                      ),
                      Text(
                        'Relatórios contábeis, faturamento e mural do cliente.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _setActiveClient(null, null),
                    icon: const Icon(Icons.exit_to_app_rounded, size: 14),
                    label: const Text('Limpar Seleção', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.expense,
                      side: BorderSide(color: AppTheme.expense.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // GRID: Metas de Faturamento Contábil & Mural de Recados
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta de Faturamento
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.track_changes_rounded, color: Color(0xFF10B981), size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text('Meta de Faturamento', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textBody)),
                            ],
                          ),
                          const Spacer(),
                          // Obter meta atual
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _db.getBpoClients(),
                            builder: (context, snapshot) {
                              final clients = snapshot.data ?? [];
                              final clientData = clients.firstWhere((c) => c['id'] == clientUid, orElse: () => {});
                              final double currentGoal = double.tryParse(clientData['revenue_goal']?.toString() ?? '0') ?? 0.0;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentGoal > 0 ? currency.format(currentGoal) : 'Nenhuma meta definida',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF10B981)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Meta para o mês de ${DateFormat('MMMM', 'pt_BR').format(now)}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                                ],
                              );
                            },
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: TextField(
                                    controller: _revenueGoalController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: 'Nova meta (ex: 15000)',
                                      filled: true, fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED))),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () async {
                                  final double? val = double.tryParse(_revenueGoalController.text.trim());
                                  if (val != null && val >= 0) {
                                    await _db.saveBpoClientRevenueGoal(clientUid, val);
                                    _revenueGoalController.clear();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('🎯 Meta de faturamento contábil salva!'),
                                        backgroundColor: Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Icon(Icons.check_rounded, size: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Mural de Recados BPO
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.campaign_rounded, color: Color(0xFF7C3AED), size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text('Mural de Recados', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textBody)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TextField(
                              controller: _bpoMessageController,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Escreva um recado rápido para a Home do cliente...',
                                filled: true, fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.all(10),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED))),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final text = _bpoMessageController.text.trim();
                                if (text.isNotEmpty) {
                                  await _db.sendBpoMessageToMural(clientUid, text);
                                  _bpoMessageController.clear();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text('📢 Recado enviado para o mural do cliente!'),
                                      backgroundColor: Color(0xFF7C3AED),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                }
                              },
                              icon: const Icon(Icons.send_rounded, size: 12, color: Colors.white),
                              label: const Text('ENVIAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              const SizedBox(height: 16),

              // Histórico de Avisos Enviados (Mural Status)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.getBpoClientSentMessages(clientUid),
                builder: (context, msgSnap) {
                  final msgs = msgSnap.data ?? [];
                  if (msgs.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status das Mensagens no Mural', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textBody)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: msgs.length,
                            itemBuilder: (ctx, i) {
                              final m = msgs[i];
                              final isRead = m['isRead'] == true;
                              final date = DateTime.fromMillisecondsSinceEpoch(m['sentAt'] as int? ?? DateTime.now().millisecondsSinceEpoch);

                              return Container(
                                width: 240,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(DateFormat('dd/MM HH:mm').format(date), style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isRead ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isRead ? 'Lido ✅' : 'Pendente 📥',
                                            style: TextStyle(
                                              color: isRead ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: Text(
                                        m['message']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textBody),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
                  );
                },
              ),

              // Demonstrativo do Resultado do Exercício (DRE) Glassmorphism
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Demonstrativo de Resultado (DRE) 📊', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textBody)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            'Competência: ${DateFormat('MMMM/yyyy', 'pt_BR').format(now)}',
                            style: GoogleFonts.inter(color: const Color(0xFF7C3AED), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _dreRow('Receita Bruta (Faturamento) 🟢', totalReceitas, currency, isPrimary: true),
                    const Divider(height: 16, thickness: 0.5),
                    _dreRow('(-) Impostos e Taxas Fiscais 🧾', impostosTaxas, currency),
                    const SizedBox(height: 8),
                    _dreRow('(-) Despesas Operacionais / Custos 🛠️', custosOperacionais, currency),
                    const Divider(height: 16, thickness: 0.5),
                    _dreRow('(=) Resultado Operacional (EBITDA) 💰', ebitda, currency, isBold: true, isEbitda: true),
                    const Divider(height: 20, thickness: 1, color: Color(0xFFE2E8F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Margem Operacional Líquida', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textBody)),
                        Text(
                          '${margemLucro.toStringAsFixed(1)}%',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: margemLucro >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Gráfico de Evolução Financeira (Últimos 5 Meses)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Evolução de Fluxo de Caixa (5 Meses)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textBody)),
                    const SizedBox(height: 2),
                    Text('Histórico acumulado de faturamento vs despesas', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(color: Colors.black.withValues(alpha: 0.04), strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                getTitlesWidget: (val, meta) {
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < lastMonths.length) {
                                    final m = lastMonths[idx];
                                    return Text(
                                      '${m.month.toString().padLeft(2, '0')}/${m.year.toString().substring(2)}',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            // Receitas
                            LineChartBarData(
                              spots: incomeSpots,
                              isCurved: true,
                              color: const Color(0xFF10B981),
                              barWidth: 3.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                              ),
                            ),
                            // Despesas
                            LineChartBarData(
                              spots: expenseSpots,
                              isCurved: true,
                              color: const Color(0xFFEF4444),
                              barWidth: 3.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Legenda do Gráfico
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendDot(const Color(0xFF10B981), 'Faturamento Recorrente'),
                        const SizedBox(width: 24),
                        _legendDot(const Color(0xFFEF4444), 'Custos e Despesas'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CARD: Previsibilidade de Caixa Contábil 🔮
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.psychology_rounded, color: Color(0xFF7C3AED), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Previsibilidade de Caixa Contábil 🔮',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                            Text(
                              'Análise preditiva de liquidez para os próximos 30 dias',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Builder(
                      builder: (context) {
                        final DateTime threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
                        final List<TransactionModel> recentTxs = transactions.where((t) => t.date.isAfter(threeMonthsAgo)).toList();

                        double recTotal = 0.0;
                        double expTotal = 0.0;
                        for (var t in recentTxs) {
                          if (t.type == TransactionType.income) {
                            recTotal += t.amount;
                          } else {
                            expTotal += t.amount;
                          }
                        }

                        final double recMedia = recTotal / 3;
                        final double expMedia = expTotal / 3;

                        double saldoContabil = 0.0;
                        for (var t in transactions) {
                          if (t.type == TransactionType.income) {
                            saldoContabil += t.amount;
                          } else {
                            saldoContabil -= t.amount;
                          }
                        }

                        final double saldoProjetado = saldoContabil + (recMedia - expMedia);
                        final bool hasRisco = saldoProjetado < 0 && (expMedia > recMedia);
                        
                        int diaCritico = 15;
                        if (hasRisco && saldoContabil > 0) {
                          final double diferencaDiaria = (expMedia - recMedia) / 30;
                          if (diferencaDiaria > 0) {
                            diaCritico = (saldoContabil / diferencaDiaria).round().clamp(1, 30);
                          }
                        }

                        final List<FlSpot> projectionSpots = [];
                        double tempSaldo = saldoContabil;
                        final double passoDiario = (recMedia - expMedia) / 30;

                        projectionSpots.add(FlSpot(0, tempSaldo));
                        projectionSpots.add(FlSpot(1, tempSaldo + passoDiario * 7));
                        projectionSpots.add(FlSpot(2, tempSaldo + passoDiario * 15));
                        projectionSpots.add(FlSpot(3, tempSaldo + passoDiario * 22));
                        projectionSpots.add(FlSpot(4, tempSaldo + passoDiario * 30));

                        double minVal = saldoContabil;
                        double maxVal = saldoContabil;
                        for (var spot in projectionSpots) {
                          if (spot.y < minVal) minVal = spot.y;
                          if (spot.y > maxVal) maxVal = spot.y;
                        }
                        minVal = minVal - (minVal.abs() * 0.1);
                        maxVal = maxVal + (maxVal.abs() * 0.1);
                        if (minVal == maxVal) {
                          minVal -= 100;
                          maxVal += 100;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo Atual Contábil:',
                                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                      ),
                                      Text(
                                        currency.format(saldoContabil),
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Projeção 30 dias:',
                                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                      ),
                                      Text(
                                        currency.format(saldoProjetado),
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: saldoProjetado >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 70,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: LineChart(
                                      LineChartData(
                                        minY: minVal,
                                        maxY: maxVal,
                                        gridData: const FlGridData(show: false),
                                        titlesData: const FlTitlesData(
                                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: projectionSpots,
                                            isCurved: true,
                                            color: saldoProjetado >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            barWidth: 2.5,
                                            dotData: const FlDotData(show: false),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: (saldoProjetado >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: hasRisco ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hasRisco ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFF10B981).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    hasRisco ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                                    color: hasRisco ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE2E8F0), height: 1.4),
                                        children: [
                                          TextSpan(
                                            text: hasRisco ? '🔮 Alerta de Liquidez: ' : '🔮 IA Previsão: ',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: hasRisco
                                                ? 'Há risco do saldo ficar negativo por volta do dia $diaCritico do mês seguinte devido à taxa de queima mensal de ${currency.format(expMedia - recMedia)}. Sugira renegociar despesas ou antecipar recebíveis.'
                                                : 'Média de receitas supera os custos operacionais em ${currency.format(recMedia - expMedia)}/mês. Liquidez altamente confortável e projeção de caixa positiva.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CARD: Planejamento Tributário Inteligente 🔮
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.gavel_rounded, color: Color(0xFF7C3AED), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Planejamento Tributário Inteligente 🔮', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textBody)),
                            Text('Simulador de enquadramento anualizado com base em receitas correntes', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Builder(
                      builder: (context) {
                        final double faturamentoMensal = totalReceitas;
                        final double fatAnual = faturamentoMensal * 12;

                        // 1. MEI
                        final bool isMeiViable = fatAnual <= 81000;
                        final double meiImposto = 960.0;

                        // 2. Simples Nacional
                        double simplesAliquota = 0.06;
                        if (fatAnual > 180000 && fatAnual <= 360000) {
                          simplesAliquota = 0.112;
                        } else if (fatAnual > 360000) {
                          simplesAliquota = 0.15;
                        }
                        final double simplesImposto = fatAnual * simplesAliquota;

                        // 3. Lucro Presumido
                        final double presumidoImposto = fatAnual * 0.145;

                        // Encontrar regime mais barato
                        String melhorRegime = 'Simples Nacional';
                        double menorImposto = simplesImposto;
                        double maiorImposto = presumidoImposto;

                        if (isMeiViable) {
                          melhorRegime = 'MEI';
                          menorImposto = meiImposto;
                        } else {
                          if (presumidoImposto < simplesImposto) {
                            melhorRegime = 'Lucro Presumido';
                            menorImposto = presumidoImposto;
                            maiorImposto = simplesImposto;
                          }
                        }

                        final double economiaEstimada = maiorImposto - menorImposto;

                        // Termômetro do MEI
                        final double faturamentoAcumuladoAno = transactions
                            .where((t) => t.date.year == now.year && t.type == TransactionType.income)
                            .fold(0.0, (sum, t) => sum + t.amount);

                        final int mesesDecorridos = now.month;
                        final double mediaMensalVendas = mesesDecorridos > 0 ? faturamentoAcumuladoAno / mesesDecorridos : 0.0;
                        final double projectionMEI = mediaMensalVendas * 12;

                        final double pctLimite = 81000 > 0 ? (projectionMEI / 81000) : 0.0;
                        final bool hasRiscoMei = projectionMEI > 81000;

                        String mesEstouroStr = 'Este ano';
                        if (hasRiscoMei && mediaMensalVendas > 0) {
                          final int mesIdx = (81000 / mediaMensalVendas).floor().clamp(1, 12);
                          final monthsList = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
                          mesEstouroStr = monthsList[mesIdx - 1];
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Termômetro do MEI (Scanner de Segurança) se o faturamento contiver MEI ou menor que R$ 150k
                            if (fatAnual < 150000) ...[
                              Text(
                                'Termômetro de Segurança do MEI 🚨',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textBody),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Projeção Anual: ${currency.format(projectionMEI)}',
                                    style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${(pctLimite * 100).toStringAsFixed(1)}% do teto',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: hasRiscoMei ? const Color(0xFFEF4444) : (pctLimite >= 0.8 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Barra Neon
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 8,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: pctLimite.clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: hasRiscoMei
                                              ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                                              : (pctLimite >= 0.8
                                                  ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                                  : [const Color(0xFF10B981), const Color(0xFF059669)]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (hasRiscoMei) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFFCA5A5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.flash_on_rounded, color: Color(0xFFEF4444), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '🔥 Alerta de Desenquadramento! A projeção anual indica estouro do limite do MEI em $mesEstouroStr (Previsão: ${currency.format(projectionMEI)}). Recomendamos iniciar transição para Microempresa (ME) imediatamente.',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF991B1B),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const Divider(height: 24, thickness: 0.5),
                            ],

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Faturamento Anualizado Estimado:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                                Text(currency.format(fatAnual), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textBody)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            _taxRegimeRow('MEI (Microempreendedor)', isMeiViable ? currency.format(meiImposto) : 'Inviável (Faturamento > R\$ 81k)', isMeiViable, isSelected: melhorRegime == 'MEI'),
                            const SizedBox(height: 10),
                            _taxRegimeRow('Simples Nacional (Anexo III)', '${(simplesAliquota * 100).toStringAsFixed(1)}% — ${currency.format(simplesImposto)}/ano', true, isSelected: melhorRegime == 'Simples Nacional'),
                            const SizedBox(height: 10),
                            _taxRegimeRow('Lucro Presumido (Serviços)', '14.5% — ${currency.format(presumidoImposto)}/ano', true, isSelected: melhorRegime == 'Lucro Presumido'),
                            
                            const Divider(height: 32, thickness: 0.5),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFF59E0B), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textBody, height: 1.5),
                                        children: [
                                          const TextSpan(text: 'Parecer BPO: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody)),
                                          const TextSpan(text: 'O regime tributário mais vantajoso é o '),
                                          TextSpan(text: melhorRegime, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                                          const TextSpan(text: '. A economia anual estimada de impostos em relação ao regime menos vantajoso é de '),
                                          TextSpan(text: currency.format(economiaEstimada), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                          const TextSpan(text: '.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _taxRegimeRow(String name, String detail, bool isViable, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? const Color(0xFF10B981) : AppTheme.textMuted,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: AppTheme.textBody)),
            ],
          ),
          Text(detail, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isViable ? (isSelected ? const Color(0xFF10B981) : AppTheme.textBody) : AppTheme.expense)),
        ],
      ),
    );
  }

  Widget _dreRow(String label, double val, NumberFormat currency, {bool isPrimary = false, bool isBold = false, bool isEbitda = false}) {
    Color valColor = AppTheme.textBody;
    if (isPrimary) {
      valColor = const Color(0xFF10B981);
    } else if (isEbitda) {
      valColor = val >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    } else if (val > 0) {
      valColor = const Color(0xFFEF4444);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isPrimary ? 13 : 12,
            fontWeight: (isPrimary || isBold) ? FontWeight.bold : FontWeight.normal,
            color: isPrimary ? AppTheme.textBody : AppTheme.textMuted,
          ),
        ),
        Text(
          currency.format(val),
          style: GoogleFonts.outfit(
            fontSize: isPrimary ? 14 : 12,
            fontWeight: (isPrimary || isBold) ? FontWeight.bold : FontWeight.normal,
            color: valColor,
          ),
        ),
      ],
    );
  }
}

extension _ConciliacaoTab on _BpoTowerScreenState {
  String _getFriendlyBankName(String packageName) {
    switch (packageName) {
      case 'com.nu.production': return 'Nubank';
      case 'br.com.inter': return 'Banco Inter';
      case 'br.com.next': return 'Next';
      case 'br.com.bb.android': return 'Banco do Brasil';
      case 'com.itau': return 'Itaú';
      case 'br.com.itau.pers': return 'Itaú Personnalité';
      case 'com.bradesco': return 'Bradesco';
      case 'br.com.bradesco.netemp': return 'Bradesco Empresas';
      case 'br.com.santander.teller': return 'Santander';
      case 'com.c6bank.app': return 'C6 Bank';
      case 'br.com.caixa.mobi': return 'Caixa Econômica';
      case 'com.mercadopago.wallet': return 'Mercado Pago';
      case 'br.com.uol.ps.phone': return 'PagBank';
      case 'com.picpay': return 'PicPay';
      default: return packageName.split('.').last;
    }
  }

  Color _getBankColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('nu')) return const Color(0xFF8A05BE);
    if (lower.contains('inter')) return const Color(0xFFFF7A00);
    if (lower.contains('itau') || lower.contains('itaú')) return const Color(0xFFEC7000);
    if (lower.contains('bradesco')) return const Color(0xFFCC092F);
    if (lower.contains('brasil') || lower.contains('bb')) return const Color(0xFFFCDE04);
    if (lower.contains('caixa')) return const Color(0xFF0066AE);
    if (lower.contains('santander')) return const Color(0xFFEC0000);
    if (lower.contains('c6')) return const Color(0xFF000000);
    if (lower.contains('mercado')) return const Color(0xFF00B1EA);
    if (lower.contains('picpay')) return const Color(0xFF21C25E);
    return const Color(0xFF64748B);
  }

  Widget _buildConciliacaoTab(NumberFormat currency) {
    if (_activeClientUid == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.06), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_rounded, size: 48, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(height: 20),
              Text('Conciliar Lançamentos Bancários', style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textBody)),
              const SizedBox(height: 8),
              Text('Selecione um cliente na aba "Clientes" para visualizar\ne gerenciar as transações capturadas do banco.',
                style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final clientUid = _activeClientUid!;
    final clientName = _activeClientName ?? 'Cliente';

    // Lista fixa de categorias contábeis padrão para seleção
    final List<String> availableCategories = [
      'Alimentação 🍔',
      'Transporte 🚗',
      'Moradia 🏠',
      'Lazer 🍿',
      'Saúde 💊',
      'Educação 📚',
      'Combustível ⛽',
      'Serviços ⚙️',
      'Impostos 🧾',
      'Receitas 💰',
      'Pró-Labore 💸',
      'Outros ⚙️',
    ];

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getNotificationLogs(),
      builder: (context, snapshot) {
        final allLogs = snapshot.data ?? [];
        final suggestedLogs = allLogs.where((log) => log['status'] == 'suggested').toList();

        if (suggestedLogs.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animação de Sucesso Neon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF10B981),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tudo Conciliado! Carteira Limpa! ☕',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Todas as transações do cliente $clientName capturadas pelo banco foram devidamente processadas ou revisadas.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        var filteredLogs = suggestedLogs;
        
        // 1. Filtrar por categoria contábil sugerida
        if (_bpoFilterCategory != null && _bpoFilterCategory != 'Todas') {
          filteredLogs = filteredLogs.where((log) {
            final cat = log['suggestedCategory']?.toString() ?? (log['isIncome'] == true ? 'Receitas 💰' : 'Outros ⚙️');
            return cat.toLowerCase().contains(_bpoFilterCategory!.toLowerCase().split(' ').first);
          }).toList();
        }
        
        // 2. Filtrar por período de data
        if (_bpoFilterPeriod != null) {
          filteredLogs = filteredLogs.where((log) {
            final timestampStr = log['timestamp']?.toString() ?? '';
            final DateTime logDate = DateTime.tryParse(timestampStr) ?? DateTime.now();
            return logDate.isAfter(_bpoFilterPeriod!.start) && logDate.isBefore(_bpoFilterPeriod!.end.add(const Duration(days: 1)));
          }).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo de Pendências
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conciliação Pendente — $clientName',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textBody),
                      ),
                      Text(
                        'Existem ${suggestedLogs.length} lançamentos aguardando classificação contábil.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${suggestedLogs.length} pendentes',
                      style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Barra de Filtros Avançados
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  // Filtro de Categoria
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _bpoFilterCategory ?? 'Todas',
                      dropdownColor: Colors.white,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textBody),
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        labelStyle: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: ['Todas', ...availableCategories].map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 12)));
                      }).toList(),
                      onChanged: (val) {
                        stateSet(() {
                          _bpoFilterCategory = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filtro de Período
                  InkWell(
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        initialDateRange: _bpoFilterPeriod,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF7C3AED),
                                onPrimary: Colors.white,
                                onSurface: AppTheme.textBody,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (range != null) {
                        stateSet(() {
                          _bpoFilterPeriod = range;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 14, color: _bpoFilterPeriod != null ? const Color(0xFF7C3AED) : AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            _bpoFilterPeriod == null
                                ? 'Filtrar Data'
                                : '${DateFormat('dd/MM').format(_bpoFilterPeriod!.start)} - ${DateFormat('dd/MM').format(_bpoFilterPeriod!.end)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _bpoFilterPeriod != null ? const Color(0xFF7C3AED) : AppTheme.textBody,
                              fontWeight: _bpoFilterPeriod != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (_bpoFilterPeriod != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                stateSet(() {
                                  _bpoFilterPeriod = null;
                                });
                              },
                              child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.expense),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de Transações
            Expanded(
              child: filteredLogs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum lançamento encontrado',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textBody),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tente ajustar ou limpar os filtros de Categoria ou Período para buscar outros lançamentos.',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        final logId = log['id'] as String;
                  final rawBank = log['packageName']?.toString() ?? 'unknown';
                  final bankName = _getFriendlyBankName(rawBank);
                  final bankColor = _getBankColor(bankName);

                  final double amount = double.tryParse(log['amount']?.toString() ?? '0.0') ?? 0.0;
                  final String rawRestaurant = log['restaurant']?.toString() ?? '';
                  final String description = rawRestaurant.isNotEmpty ? rawRestaurant : (log['title']?.toString() ?? 'Transação');
                  final bool isIncome = log['isIncome'] == true;
                  final String timestampStr = log['timestamp']?.toString() ?? '';
                  final DateTime date = DateTime.tryParse(timestampStr) ?? DateTime.now();

                  final bool isSuspect = log['isSuspect'] == true;
                  final String? anomalyReason = log['anomalyReason']?.toString();

                  // Categoria sugerida por padrão
                  String selectedCategory = log['suggestedCategory']?.toString() ?? (isIncome ? 'Receitas 💰' : 'Outros ⚙️');
                  if (!availableCategories.contains(selectedCategory)) {
                    // Tentar normalizar ou adicionar à lista temporariamente
                    selectedCategory = availableCategories.firstWhere((cat) => cat.toLowerCase().contains(selectedCategory.toLowerCase()), orElse: () => availableCategories.first);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSuspect ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.05),
                        width: isSuspect ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSuspect ? const Color(0xFFF59E0B).withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner de Alerta Sentinela se for suspeito
                          if (isSuspect)
                            Container(
                              color: const Color(0xFFFEF3C7),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Sentinela Guard: $anomalyReason (Score: ${log['anomalyScore'] ?? 'Alta'})',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFB45309),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Conteúdo Principal
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Icone do Banco
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: bankColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.account_balance_rounded,
                                      color: bankColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Informações
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        description,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textBody),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            bankName,
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: bankColor),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '•',
                                            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateFormat('dd MMM - HH:mm', 'pt_BR').format(date),
                                            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Valor
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isIncome ? '+' : '-'} ${currency.format(amount)}',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isIncome ? 'Entrada Pix' : 'Saída Pix/Débito',
                                      style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Rodapé de Ações
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.03))),
                            ),
                            child: Row(
                              children: [
                                // Dropdown de Categoria Contábil
                                Text(
                                  'Categoria:',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedCategory,
                                        isExpanded: true,
                                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textBody),
                                        items: availableCategories.map((cat) {
                                          return DropdownMenuItem<String>(
                                            value: cat,
                                            child: Text(cat),
                                          );
                                        }).toList(),
                                        onChanged: (newCat) {
                                          if (newCat != null) {
                                            stateSet(() {
                                              log['suggestedCategory'] = newCat;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Botão Ignorar
                                OutlinedButton(
                                  onPressed: () async {
                                    await _db.updateNotificationLogStatus(logId, 'ignored');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Transação ignorada da Caixa de Entrada.'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('Ignorar', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 6),

                                // Botão Confirmar
                                ElevatedButton(
                                  onPressed: () async {
                                    // 1. Gravar a transação real
                                    final tx = TransactionModel(
                                      id: '',
                                      description: description,
                                      amount: amount,
                                      category: selectedCategory,
                                      date: date,
                                      type: isIncome ? TransactionType.income : TransactionType.expense,
                                    );
                                    await _db.addTransaction(tx);

                                    // 2. Liquidar no Omie se houver título (nCodLanc)
                                    final int? nCodLanc = log['nCodLanc'] != null ? int.tryParse(log['nCodLanc'].toString()) : null;
                                    if (nCodLanc != null) {
                                      _payOmieBillForClient(nCodLanc, amount, clientUid);
                                    }

                                    // 3. Confirmar o log no banco
                                    await _db.updateNotificationLogStatus(logId, 'confirmed');

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(nCodLanc != null
                                              ? '⚡ Conciliado e liquidado no Omie com sucesso!'
                                              : '⚡ Lançamento bancário conciliado com sucesso!'),
                                          backgroundColor: const Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C3AED),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('Confirmar ⚡', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Método assíncrono para liquidar boleto no Omie associado ao cliente ativo
  Future<void> _payOmieBillForClient(int nCodLanc, double amount, String clientUid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Como estamos no modo ativo, as contas cadastradas do Omie e conta ativa pertencem ao cliente ativo.
      // A estrutura de dados de chaves do Omie usa um sufixo com o UID do usuário.
      final accountsKey = 'omie_accounts_v2_$clientUid';
      final activeIdKey = 'active_account_id_$clientUid';

      final accountsJson = prefs.getString(accountsKey) ?? prefs.getString('omie_accounts_v2');
      if (accountsJson == null) return;

      final List<dynamic> decoded = jsonDecode(accountsJson);
      final activeId = prefs.getString(activeIdKey) ?? prefs.getString('active_account_id');
      
      Map<String, dynamic>? activeAccount;
      if (activeId != null) {
        for (var item in decoded) {
          if (item['id'] == activeId) {
            activeAccount = Map<String, dynamic>.from(item);
            break;
          }
        }
      }
      activeAccount ??= decoded.isNotEmpty ? Map<String, dynamic>.from(decoded.first) : null;

      if (activeAccount != null) {
        final String? key = activeAccount['appKey'] ?? activeAccount['app_key'];
        final String? secret = activeAccount['appSecret'] ?? activeAccount['app_secret'];
        
        if (key != null && secret != null) {
          final omie = OmieService(appKey: key, appSecret: secret);
          await omie.payBill(nCodLanc, amount);
          if (kDebugMode) print('Título $nCodLanc liquidado via BPO Tower para cliente $clientUid.');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao dar baixa no Omie via BPO Tower: $e');
    }
  }
}


