import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';
import '../../../services/realtime_db_service.dart';
import '../../../models/transaction_model.dart';
import '../../bpo/bpo_automation_dashboard.dart';
import '../../bpo/bpo_ocr_split_view.dart';
import '../../bpo/bpo_smart_batch_upload.dart';
import '../../bpo/bpo_efficiency_reports.dart';
import '../../bpo/bpo_client_overview.dart';
import '../../bpo/bpo_mobile_scanner.dart';
import '../../bpo/bpo_archive_history.dart';
import '../../bpo/bpo_omie_config.dart';

class BpoControlTowerView extends StatefulWidget {
  final VoidCallback? onManageAccount;

  const BpoControlTowerView({
    super.key,
    this.onManageAccount,
  });

  @override
  State<BpoControlTowerView> createState() => _BpoControlTowerViewState();
}

class _BpoControlTowerViewState extends State<BpoControlTowerView> {
  int _activeTab = 0; // 0 = Visão Geral, 1 = Gestor de Honorários
  String _searchQuery = '';
  bool _isExporting = false;

  void _showAddManualClientDialog(BuildContext context) {
    final nameController = TextEditingController();
    final uidController = TextEditingController();
    final phoneController = TextEditingController();
    final dbService = RealtimeDbService();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Vincular Cliente Manual',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Peça para seu cliente ir em Ajustes > ID de Vinculação BPO, copiar o código e enviar para você.',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nome do Cliente (ex: João Silva)',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: uidController,
                decoration: InputDecoration(
                  labelText: 'ID de Vinculação (UID)',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'WhatsApp do Cliente (Opcional - ex: 11999998888)',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCELAR',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final uid = uidController.text.trim();
                      final phone = phoneController.text.trim();

                      if (name.isEmpty || uid.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚠️ Preencha todos os campos!')),
                        );
                        return;
                      }

                      final success = await dbService.linkClientToBpo(uid, name, phone: phone.isNotEmpty ? phone : null);
                      if (context.mounted) {
                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Cliente vinculado com sucesso!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('❌ ID de cliente inválido ou não cadastrado.')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    child: Text(
                      'VINCULAR CLIENTE',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditFeeDialog(BuildContext context, String clientUid, String clientName, Map<String, dynamic> currentFee) {
    final feeController = TextEditingController(text: (currentFee['amount'] ?? 0.0).toString());
    final dueDayController = TextEditingController(text: (currentFee['dueDay'] ?? 5).toString());
    final phoneController = TextEditingController(text: (currentFee['phone'] ?? '').toString());
    final dbService = RealtimeDbService();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monetization_on_rounded, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Honorários: $clientName',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: feeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Valor Mensal (R\$)',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dueDayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Dia do Vencimento (1 a 31)',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'WhatsApp do Cliente (com DDD)',
                  labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCELAR',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(feeController.text.trim()) ?? 0.0;
                      final dueDay = int.tryParse(dueDayController.text.trim()) ?? 5;

                      if (amount <= 0 || dueDay < 1 || dueDay > 31) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚠️ Insira valores válidos!')),
                        );
                        return;
                      }

                      await dbService.saveBpoFee(
                        clientUid,
                        amount,
                        dueDay,
                        currentFee['status'] ?? 'Pendente',
                        phone: phoneController.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Honorário atualizado!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    child: Text(
                      'SALVAR',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final dbService = RealtimeDbService();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 900;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: dbService.getBpoClients(),
      builder: (context, manualClientsSnap) {
        final manualClients = manualClientsSnap.data ?? [];

        // Montar a lista unificada de todos os clientes do BPO
        final List<Map<String, dynamic>> allClientsList = [];
        for (var acc in provider.omieAccounts) {
          allClientsList.add({
            'id': acc.id,
            'name': acc.name,
            'isOmie': true,
            'meta': 'CNPJ: ${acc.cnpj ?? "Não cadastrado"}',
          });
        }
        for (var mc in manualClients) {
          allClientsList.add({
            'id': mc['id'],
            'name': mc['name'],
            'isOmie': false,
            'meta': 'UID: ${mc['id']}',
            'phone': mc['phone'],
          });
        }

        // Renderizar com base na Tab Ativa
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu de Abas Segmentado e Rolável de Alta Estética para o BPO Suite
            Padding(
              padding: EdgeInsets.only(left: isNarrow ? 16 : 32, right: isNarrow ? 16 : 32, top: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildBpoSubTab(0, 'Visão Geral'),
                      _buildBpoSubTab(1, 'Honorários BPO'),
                      _buildBpoSubTab(2, 'Checklist'),
                      _buildBpoSubTab(3, '⚡ Automação OCR'),
                      _buildBpoSubTab(4, '📄 Split View OCR'),
                      _buildBpoSubTab(5, '📥 Upload Lote'),
                      _buildBpoSubTab(6, '📈 Eficiência BPO'),
                      _buildBpoSubTab(7, '🏢 Clientes BPO'),
                      _buildBpoSubTab(8, '📱 Mobile Scanner'),
                      _buildBpoSubTab(9, '🗄️ Histórico Archive'),
                      _buildBpoSubTab(10, '⚙️ Config. Omie'),
                    ],
                  ),
                ),
              ),
            ),

            // Tab 0: Visão Geral de Clientes e Omie
            Offstage(
              offstage: _activeTab != 0,
              child: _buildGeneralTab(context, provider, dbService, manualClients, currency, isNarrow),
            ),

            // Tab 1: Faturamento & Honorários do BPO
            Offstage(
              offstage: _activeTab != 1,
              child: _buildFeesTab(context, dbService, allClientsList, currency, isNarrow),
            ),

            // Tab 2: Checklist de Documentos do BPO
            Offstage(
              offstage: _activeTab != 2,
              child: _buildDocumentsTab(context, dbService, allClientsList, isNarrow),
            ),

            // Tab 3: Dashboard Automação OCR
            Offstage(offstage: _activeTab != 3, child: const BpoAutomationDashboard()),

            // Tab 4: Verificação OCR Split View
            Offstage(offstage: _activeTab != 4, child: const BpoOcrSplitView()),

            // Tab 5: Centro de Upload em Lote
            Offstage(offstage: _activeTab != 5, child: const BpoSmartBatchUpload()),

            // Tab 6: Relatórios de Eficiência BPO
            Offstage(offstage: _activeTab != 6, child: const BpoEfficiencyReports()),

            // Tab 7: Gestão de Clientes BPO
            Offstage(offstage: _activeTab != 7, child: const BpoClientOverview()),

            // Tab 8: Scanner Mobile PWA
            Offstage(offstage: _activeTab != 8, child: const BpoMobileScanner()),

            // Tab 9: Histórico Archive
            Offstage(offstage: _activeTab != 9, child: const BpoArchiveHistory()),

            // Tab 10: Configurações de Integração Omie
            Offstage(offstage: _activeTab != 10, child: const BpoOmieConfig()),
          ],
        );
      },
    );
  }

  Widget _buildBpoSubTab(int tabIndex, String label) {
    final bool isSelected = _activeTab == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTab(
    BuildContext context,
    TransactionsProvider provider,
    RealtimeDbService dbService,
    List<Map<String, dynamic>> manualClients,
    NumberFormat currency,
    bool isNarrow,
  ) {
    // Filtrar clientes com base na busca
    final filteredOmie = provider.omieAccounts.where((acc) {
      final name = acc.name.toLowerCase();
      final cnpj = acc.cnpj?.toLowerCase() ?? '';
      return name.contains(_searchQuery) || cnpj.contains(_searchQuery);
    }).toList();

    final filteredManual = manualClients.where((mc) {
      final name = mc['name']?.toString().toLowerCase() ?? '';
      final uid = mc['id']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery) || uid.contains(_searchQuery);
    }).toList();

    int totalClients = provider.omieAccounts.length + manualClients.length;
    double totalBalance = 0.0;
    int criticalAccounts = 0;

    for (var acc in provider.omieAccounts) {
      final metrics = provider.accountMetrics[acc.id] ?? {};
      final double bal = metrics['balance'] ?? 0.0;
      final int due = metrics['dueTodayCount'] ?? 0;
      final String status = metrics['status'] ?? '';
      
      totalBalance += bal;
      if (due > 0 || status == 'Erro') {
        criticalAccounts++;
      }
    }

    return Padding(
        padding: EdgeInsets.all(isNarrow ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabeçalho Responsivo Premium
            isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Torre BPO Financeiro 🏢',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Controle centralizado, conciliação rápida e auditoria de clientes.',
                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildHeaderButton(
                            onPressed: () => _showAddManualClientDialog(context),
                            icon: Icons.person_add_alt_rounded,
                            label: 'Vincular Cliente',
                            isPrimary: false,
                          ),
                          _buildHeaderButton(
                            onPressed: () => provider.refreshOmieData(fullSync: true),
                            icon: Icons.sync_rounded,
                            label: provider.isRefreshingOmie ? 'Sincronizando...' : 'Sincronizar Tudo',
                            isPrimary: true,
                            isLoading: provider.isRefreshingOmie,
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Torre BPO Financeiro 🏢',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Controle centralizado, conciliação rápida e auditoria de clientes.',
                            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildHeaderButton(
                            onPressed: () => _showAddManualClientDialog(context),
                            icon: Icons.person_add_alt_rounded,
                            label: 'Vincular Cliente',
                            isPrimary: false,
                          ),
                          const SizedBox(width: 12),
                          _buildHeaderButton(
                            onPressed: () => provider.refreshOmieData(fullSync: true),
                            icon: Icons.sync_rounded,
                            label: provider.isRefreshingOmie ? 'Sincronizando...' : 'Sincronizar Tudo',
                            isPrimary: true,
                            isLoading: provider.isRefreshingOmie,
                          ),
                        ],
                      ),
                    ],
                  ),
                
            const SizedBox(height: 32),

            // Barra de Busca Dinâmica
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome do cliente ou CNPJ/UID...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

             // 2. Grid de KPIs Consolidada
            GridView.count(
              crossAxisCount: isNarrow ? 1 : 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isNarrow ? 3.2 : 2.2,
              children: [
                _buildKpiCard(
                  title: 'Clientes Ativos',
                  value: totalClients.toString(),
                  subtitle: '${provider.omieAccounts.length} automatizados • ${manualClients.length} manuais',
                  gradientColors: [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                  icon: Icons.people_rounded,
                ),
                _buildKpiCard(
                  title: 'Saldo Consolidado',
                  value: currency.format(totalBalance),
                  subtitle: 'Total em caixa nos bancos',
                  gradientColors: [const Color(0xFF10B981), const Color(0xFF047857)],
                  icon: Icons.account_balance_wallet_rounded,
                ),
                _buildKpiCard(
                  title: 'Atenção Requerida',
                  value: criticalAccounts.toString(),
                  subtitle: 'Empresas com alertas hoje',
                  gradientColors: criticalAccounts > 0 
                      ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                      : [const Color(0xFF64748B), const Color(0xFF475569)],
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Feed de Urgências da Carteira
            Builder(
              builder: (context) {
                final List<String> urgentAlerts = [];
                for (var acc in provider.omieAccounts) {
                  final metrics = provider.accountMetrics[acc.id] ?? {};
                  final double bal = metrics['balance'] ?? 0.0;
                  final int due = metrics['dueTodayCount'] ?? 0;
                  final String status = metrics['status'] ?? '';
                  
                  if (bal < 0) {
                    urgentAlerts.add('⚠️ ${acc.name}: Saldo negativo de ${currency.format(bal)}');
                  }
                  if (due > 0) {
                    urgentAlerts.add('⚠️ ${acc.name}: $due contas a pagar/receber hoje!');
                  }
                  if (status == 'Erro') {
                    urgentAlerts.add('⚠️ ${acc.name}: Falha na integração com Omie ERP!');
                  }
                }

                if (urgentAlerts.isEmpty) return const SizedBox.shrink();

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign_rounded, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'FEED DE URGÊNCIAS DA CARTEIRA',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: const Color(0xFFEF4444),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...urgentAlerts.map((alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          alert,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF991B1B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )),
                    ],
                  ),
                );
              }
            ),

            const SizedBox(height: 40),

            // Layout Responsivo: Lista de Clientes e DRE (Esquerda/Principal) e Quadro de Notas (Direita/Lateral)
            Builder(
              builder: (context) {
                final Widget clientsColumnContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. Seção: Empresas Automáticas (Omie)
                    _buildSectionHeader('EMPRESAS INTEGRADAS (OMIE API)', Icons.api_rounded),
                    const SizedBox(height: 16),
                    if (filteredOmie.isEmpty)
                      _buildEmptyStateCard(_searchQuery.isEmpty 
                          ? 'Nenhuma empresa integrada com chaves Omie. Vá em configurações para cadastrá-las.'
                          : 'Nenhuma empresa integrada encontrada para a busca.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredOmie.length,
                        itemBuilder: (context, idx) {
                          final acc = filteredOmie[idx];
                          final metrics = provider.accountMetrics[acc.id] ?? {};
                          final double balance = metrics['balance'] ?? 0.0;
                          final bool isRed = metrics['isRed'] ?? false;
                          final int dueToday = metrics['dueTodayCount'] ?? 0;
                          final String status = metrics['status'] ?? 'Pendente';
                          final String lastSync = metrics['lastSync'] != null
                              ? DateFormat('dd/MM HH:mm').format(DateTime.parse(metrics['lastSync']))
                              : 'Nunca';
                          final isCurrentActive = acc.id == provider.activeAccountId && RealtimeDbService.bpoActiveClientUid == null;

                          return _buildClientItemCard(
                            context,
                            name: acc.name,
                            meta: 'CNPJ: ${acc.cnpj ?? "Não cadastrado"}',
                            balance: balance,
                            isRed: isRed,
                            dueToday: dueToday,
                            status: status,
                            lastSync: lastSync,
                            isActive: isCurrentActive,
                            isOmie: true,
                            onManage: () async {
                              dbService.setBpoActiveClient(null);
                              await provider.switchAccount(acc.id);
                              if (widget.onManageAccount != null) {
                                widget.onManageAccount!();
                              }
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 40),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 32),

                    // 4. Seção: Clientes Manuais
                    _buildSectionHeader('CLIENTES VINCULADOS (SEM INTEGRAÇÃO / MANUAIS)', Icons.cloud_done_outlined),
                    const SizedBox(height: 16),
                    
                    if (filteredManual.isEmpty)
                      _buildEmptyStateCard(_searchQuery.isEmpty
                          ? 'Nenhum cliente manual vinculado. Compartilhe o ID de Vinculação com seus clientes para conectá-los.'
                          : 'Nenhum cliente manual encontrado para a busca.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredManual.length,
                        itemBuilder: (context, idx) {
                          final client = filteredManual[idx];
                          final String clientId = client['id'] ?? '';
                          final String name = client['name'] ?? 'Cliente';
                          final String? phone = client['phone'];
                          final isCurrentActive = RealtimeDbService.bpoActiveClientUid == clientId;

                          return StreamBuilder<List<TransactionModel>>(
                            stream: dbService.getClientTransactions(clientId),
                            builder: (context, transSnap) {
                              final transactions = transSnap.data ?? [];
                              double balance = 0.0;
                              int dueToday = 0;
                              final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

                              for (var tx in transactions) {
                                if (tx.type == TransactionType.income) {
                                  balance += tx.amount;
                                } else {
                                  balance -= tx.amount;
                                }
                                if (DateFormat('yyyy-MM-dd').format(tx.date) == todayStr) {
                                  dueToday++;
                                }
                              }

                              return _buildClientItemCard(
                                context,
                                name: name,
                                meta: 'UID: $clientId',
                                balance: balance,
                                isRed: balance < 0,
                                dueToday: dueToday,
                                status: 'Firebase',
                                lastSync: 'Sincronizado',
                                isActive: isCurrentActive,
                                isOmie: false,
                                phone: phone,
                                onManage: () async {
                                  dbService.setBpoActiveClient(clientId);
                                  await provider.init();
                                  if (widget.onManageAccount != null) {
                                    widget.onManageAccount!();
                                  }
                                },
                              );
                            }
                          );
                        },
                      ),

                    const SizedBox(height: 40),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 32),

                    // 5. Seção: Consolidated DRE/Audit Table
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('DRE COMPARATIVO (VISÃO FINANCEIRA DE CLIENTES)', Icons.analytics_rounded),
                        _isExporting
                            ? const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: () async {
                                  setState(() => _isExporting = true);
                                  try {
                                    final currencyStr = NumberFormat.simpleCurrency(locale: 'pt_BR');
                                    String csv = 'Cliente;Saldo Bancario;Status Conexao;Contas Hoje\r\n';
                                    
                                    for (var acc in provider.omieAccounts) {
                                      final metrics = provider.accountMetrics[acc.id] ?? {};
                                      final double balance = metrics['balance'] ?? 0.0;
                                      final int dueToday = metrics['dueTodayCount'] ?? 0;
                                      final String status = metrics['status'] ?? 'Pendente';
                                      
                                      csv += '${acc.name.toUpperCase()};${currencyStr.format(balance).replaceAll('R\$', '').trim()};Omie ERP ($status);$dueToday contas\r\n';
                                    }
                                    
                                    for (var mc in manualClients) {
                                      final String clientId = mc['id'] ?? '';
                                      final String name = mc['name'] ?? 'Cliente';
                                      
                                      final transactions = await dbService.getClientTransactionsOnce(clientId);
                                      double balance = 0.0;
                                      int dueToday = 0;
                                      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                                      
                                      for (var tx in transactions) {
                                        if (tx.type == TransactionType.income) {
                                          balance += tx.amount;
                                        } else {
                                          balance -= tx.amount;
                                        }
                                        if (DateFormat('yyyy-MM-dd').format(tx.date) == todayStr) {
                                          dueToday++;
                                        }
                                      }
                                      csv += '${name.toUpperCase()};${currencyStr.format(balance).replaceAll('R\$', '').trim()};Manual (Nuvem);$dueToday contas\r\n';
                                    }

                                    final String encoded = Uri.encodeComponent(csv);
                                    final String url = 'data:text/csv;charset=utf-8,\uFEFF' + encoded;
                                    await launchUrlString(url, mode: LaunchMode.externalApplication);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✅ Planilha exportada com sucesso!')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('❌ Erro ao exportar planilha: $e')),
                                      );
                                    }
                                  } finally {
                                    setState(() => _isExporting = false);
                                  }
                                },
                                icon: const Icon(Icons.table_rows_rounded, size: 16),
                                label: Text('EXPORTAR PLANILHA', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  foregroundColor: const Color(0xFF0F172A),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (provider.omieAccounts.isEmpty && manualClients.isEmpty)
                      _buildEmptyStateCard('Sem clientes cadastrados para comparação.')
                    else
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              constraints: BoxConstraints(minWidth: isNarrow ? 600 : MediaQuery.of(context).size.width - 64),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    color: const Color(0xFFF8FAFC),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Text('CLIENTE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF475569), fontSize: 11))),
                                        Expanded(flex: 2, child: Text('SALDO BANCÁRIO', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF475569), fontSize: 11))),
                                        Expanded(flex: 2, child: Text('STATUS CONEXÃO', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF475569), fontSize: 11))),
                                        Expanded(flex: 2, child: Text('CONTAS HOJE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF475569), fontSize: 11))),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                  
                                  ...provider.omieAccounts.map((acc) {
                                    final metrics = provider.accountMetrics[acc.id] ?? {};
                                    final double balance = metrics['balance'] ?? 0.0;
                                    final int dueToday = metrics['dueTodayCount'] ?? 0;
                                    final String status = metrics['status'] ?? 'Pendente';
                                    
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 3, child: Text(acc.name.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF0F172A)))),
                                          Expanded(flex: 2, child: Text(currency.format(balance), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: balance < 0 ? Colors.red : Colors.green))),
                                          Expanded(flex: 2, child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: status == 'Sucesso' ? Colors.green : Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text('Omie ERP ($status)', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E293B))),
                                            ],
                                          )),
                                          Expanded(flex: 2, child: Container(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: dueToday > 0 ? Colors.amber.shade50 : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '$dueToday contas',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: dueToday > 0 ? Colors.amber.shade800 : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          )),
                                        ],
                                      ),
                                    );
                                  }),

                                  ...manualClients.map((mc) {
                                    final String clientId = mc['id'] ?? '';
                                    final String name = mc['name'] ?? 'Cliente';
                                    
                                    return StreamBuilder<List<TransactionModel>>(
                                      stream: dbService.getClientTransactions(clientId),
                                      builder: (context, transSnap) {
                                        final transactions = transSnap.data ?? [];
                                        double balance = 0.0;
                                        int dueToday = 0;
                                        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

                                        for (var tx in transactions) {
                                          if (tx.type == TransactionType.income) {
                                            balance += tx.amount;
                                          } else {
                                            balance -= tx.amount;
                                          }
                                          if (DateFormat('yyyy-MM-dd').format(tx.date) == todayStr) {
                                            dueToday++;
                                          }
                                        }

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          decoration: const BoxDecoration(
                                            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(flex: 3, child: Text(name.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF0F172A)))),
                                              Expanded(flex: 2, child: Text(currency.format(balance), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: balance < 0 ? Colors.red : Colors.green))),
                                              Expanded(flex: 2, child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.green,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text('Manual (Nuvem)', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E293B))),
                                                ],
                                              )),
                                              Expanded(flex: 2, child: Container(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: dueToday > 0 ? Colors.amber.shade50 : const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '$dueToday hoje',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: dueToday > 0 ? Colors.amber.shade800 : const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ),
                                              )),
                                            ],
                                          ),
                                        );
                                      }
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );

                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNotesSection(dbService, isNarrow),
                          const SizedBox(height: 40),
                          clientsColumnContent,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: clientsColumnContent),
                          const SizedBox(width: 32),
                          Expanded(flex: 1, child: _buildNotesSection(dbService, isNarrow)),
                        ],
                      );
              }
            ),
          ],
        ),
      );
  }

  Widget _buildNotesSection(RealtimeDbService dbService, bool isNarrow) {
    final noteController = TextEditingController();

    return StreamBuilder<Map<String, dynamic>>(
      stream: dbService.getBpoNotes(),
      builder: (context, snapshot) {
        final notesMap = snapshot.data ?? {};
        final List<MapEntry<String, dynamic>> notesList = notesMap.entries.toList();
        notesList.sort((a, b) {
          final int tA = (a.value as Map)['createdAt'] ?? 0;
          final int tB = (b.value as Map)['createdAt'] ?? 0;
          return tB.compareTo(tA);
        });

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.push_pin_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'QUADRO DE AVISOS INTERNOS',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: const Color(0xFFD97706),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: noteController,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: 'Novo lembrete rápido...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFFDE68A)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFD97706), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (val) async {
                        final text = val.trim();
                        if (text.isNotEmpty) {
                          await dbService.addBpoNote(text);
                          noteController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final text = noteController.text.trim();
                      if (text.isNotEmpty) {
                        await dbService.addBpoNote(text);
                        noteController.clear();
                      }
                    },
                    icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFD97706)),
                    tooltip: 'Adicionar Nota',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (notesList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Nenhum lembrete salvo.',
                      style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notesList.length,
                  itemBuilder: (context, index) {
                    final noteId = notesList[index].key;
                    final noteData = notesList[index].value as Map;
                    final String text = noteData['text'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              text,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E293B)),
                            ),
                          ),
                          IconButton(
                            onPressed: () => dbService.deleteBpoNote(noteId),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                            tooltip: 'Remover lembrete',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeesTab(
    BuildContext context,
    RealtimeDbService dbService,
    List<Map<String, dynamic>> allClientsList,
    NumberFormat currency,
    bool isNarrow,
  ) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: dbService.getBpoFees(),
      builder: (context, feesSnap) {
        if (feesSnap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
          );
        }

        final feesData = feesSnap.data ?? {};
        
        // Calcular Métricas Financeiras do BPO
        double estimatedIncome = 0.0;
        double receivedIncome = 0.0;
        double pendingIncome = 0.0;

        for (var client in allClientsList) {
          final String cid = client['id'];
          final clientFee = feesData[cid] as Map? ?? {};
          final double amount = double.tryParse(clientFee['amount']?.toString() ?? '0') ?? 0.0;
          final String status = clientFee['status']?.toString() ?? 'Pendente';

          estimatedIncome += amount;
          if (status == 'Pago') {
            receivedIncome += amount;
          } else {
            pendingIncome += amount;
          }
        }

        return Padding(
          padding: EdgeInsets.all(isNarrow ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Título & Subtítulo da Gestão
              Text(
                'Gestão de Faturamento BPO 💰',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Defina honorários mensais e controle quem realizou os pagamentos do mês.',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 24),

              // 2. KPIs de Faturamento do BPO
              GridView.count(
                crossAxisCount: isNarrow ? 1 : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isNarrow ? 3.2 : 2.2,
                children: [
                  _buildKpiCard(
                    title: 'Faturamento Estimado',
                    value: currency.format(estimatedIncome),
                    subtitle: 'Total contratado com clientes',
                    gradientColors: [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                    icon: Icons.monetization_on_outlined,
                  ),
                  _buildKpiCard(
                    title: 'Honorários Recebidos',
                    value: currency.format(receivedIncome),
                    subtitle: 'Faturamento liquidado este mês',
                    gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  _buildKpiCard(
                    title: 'Honorários Pendentes',
                    value: currency.format(pendingIncome),
                    subtitle: 'Faturamento a receber',
                    gradientColors: pendingIncome > 0
                        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                        : [const Color(0xFF64748B), const Color(0xFF475569)],
                    icon: Icons.hourglass_empty_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildFaturamentoChart(receivedIncome, pendingIncome, currency),

              const SizedBox(height: 40),

              // 3. Tabela de Clientes e Honorários
              _buildSectionHeader('TABELA DE CONTROLE DE HONORÁRIOS', Icons.table_chart_rounded),
              const SizedBox(height: 16),

              if (allClientsList.isEmpty)
                _buildEmptyStateCard('Vincule clientes primeiro na aba principal para gerenciar faturamento.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allClientsList.length,
                  itemBuilder: (context, idx) {
                    final client = allClientsList[idx];
                    final String cid = client['id'];
                    final String name = client['name'];
                    final String meta = client['meta'];
                    final bool isOmie = client['isOmie'];

                    final clientFee = feesData[cid] as Map? ?? {};
                    final double amount = double.tryParse(clientFee['amount']?.toString() ?? '0') ?? 0.0;
                    final int dueDay = int.tryParse(clientFee['dueDay']?.toString() ?? '5') ?? 5;
                    final String status = clientFee['status']?.toString() ?? 'Pendente';
                    final bool hasFee = amount > 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Status Dot / Tag
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: hasFee 
                                  ? (status == 'Pago' ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                  : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Cliente Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.toUpperCase(),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isOmie ? 'Omie ERP • $meta' : 'Manual • $meta',
                                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Valor & Vencimento
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                hasFee ? currency.format(amount) : 'Sem valor',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: hasFee ? const Color(0xFF0F172A) : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasFee ? 'Vence dia $dueDay' : 'Clique em editar',
                                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10),
                              ),
                            ],
                          ),

                          const SizedBox(width: 24),

                          // Ações
                          Row(
                            children: [
                              // Toggle Status Pago/Pendente
                              if (hasFee)
                                IconButton(
                                  onPressed: () async {
                                    final nextStatus = status == 'Pago' ? 'Pendente' : 'Pago';
                                    await dbService.saveBpoFee(cid, amount, dueDay, nextStatus, phone: clientFee['phone']?.toString());
                                    
                                    if (nextStatus == 'Pago' && amount > 0) {
                                      final String? bpoUid = dbService.currentUserUid;
                                      if (bpoUid != null) {
                                        final feeTx = TransactionModel(
                                          id: '',
                                          amount: amount,
                                          category: 'Honorário BPO 💰',
                                          description: 'Recebimento Honorário: $name',
                                          date: DateTime.now(),
                                          type: TransactionType.income,
                                        );
                                        await dbService.addManualTransaction(bpoUid, feeTx);
                                      }
                                    }

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            nextStatus == 'Pago'
                                                ? '✅ Honorário Pago! Receita registrada no caixa do BPO.'
                                                : '✅ Status alterado para Pendente!'
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    status == 'Pago' ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                    color: status == 'Pago' ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                    size: 22,
                                  ),
                                  tooltip: 'Marcar como Pago / Pendente',
                                ),

                              if (hasFee && status == 'Pendente')
                                IconButton(
                                  onPressed: () async {
                                    final String rawPhone = clientFee['phone']?.toString() ?? client['phone']?.toString() ?? '';
                                    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
                                    if (cleanPhone.isNotEmpty) {
                                      final String ddi = cleanPhone.startsWith('55') ? '' : '55';
                                      final message = Uri.encodeComponent(
                                        'Olá, $name! Tudo bem?\n\nLembramos que o honorário do BPO Financeiro deste mês (no valor de ${currency.format(amount)}) está pendente com vencimento para o dia $dueDay. \n\nSe precisar da segunda via ou do pix, por favor me avise! Obrigado! 👍'
                                      );
                                      final url = 'https://wa.me/$ddi$cleanPhone?text=$message';
                                      await launchUrlString(url, mode: LaunchMode.externalApplication);
                                    } else {
                                      // WhatsApp não cadastrado no BPO. Tenta buscar no perfil público do cliente
                                      String? fallbackPhone;
                                      try {
                                        final profileSnap = await FirebaseDatabase.instance.ref('users/$cid/profile').get();
                                        if (profileSnap.exists && profileSnap.value is Map) {
                                          final profileData = Map<String, dynamic>.from(profileSnap.value as Map);
                                          fallbackPhone = profileData['phone']?.toString();
                                        }
                                      } catch (_) {}

                                      final cleanFallback = (fallbackPhone ?? '').replaceAll(RegExp(r'\D'), '');
                                      if (cleanFallback.isNotEmpty) {
                                        final String ddi = cleanFallback.startsWith('55') ? '' : '55';
                                        final message = Uri.encodeComponent(
                                          'Olá, $name! Tudo bem?\n\nLembramos que o honorário do BPO Financeiro deste mês (no valor de ${currency.format(amount)}) está pendente com vencimento para o dia $dueDay. \n\nSe precisar da segunda via ou do pix, por favor me avise! Obrigado! 👍'
                                        );
                                        final url = 'https://wa.me/$ddi$cleanFallback?text=$message';
                                        await launchUrlString(url, mode: LaunchMode.externalApplication);
                                      } else {
                                        // Sem WhatsApp algum. Enviar aviso direto no aplicativo do cliente
                                        final message = 'Olá, $name! Lembramos que o seu honorário mensal de ${currency.format(amount)} está pendente com vencimento para o dia $dueDay. Por favor, realize o pagamento diretamente pelo app. Obrigado!';
                                        await dbService.saveBpoClientMessage(cid, message, true);

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('📢 WhatsApp não configurado! Lembrete de cobrança enviado para a tela inicial do cliente no app.'),
                                              backgroundColor: Color(0xFF7C3AED),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 20,
                                  ),
                                  tooltip: 'Enviar lembrete de cobrança via WhatsApp ou App',
                                ),

                              // Editar Valor/Dia
                              IconButton(
                                onPressed: () => _showEditFeeDialog(context, cid, name, Map<String, dynamic>.from(clientFee)),
                                icon: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 20),
                                tooltip: 'Configurar Honorário',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaturamentoChart(double received, double pending, NumberFormat currency) {
    final total = received + pending;
    final double receivedPct = total > 0 ? (received / total) : 0.0;
    final double pendingPct = total > 0 ? (pending / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISTRIBUIÇÃO DE RECEBIMENTOS (MÊS VIGENTE)',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: const Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 16,
              width: double.infinity,
              color: const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  if (receivedPct > 0)
                    Expanded(
                      flex: (receivedPct * 100).round(),
                      child: Container(
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  if (pendingPct > 0)
                    Expanded(
                      flex: (pendingPct * 100).round(),
                      child: Container(
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pago: ${currency.format(received)} (${(receivedPct * 100).toStringAsFixed(1)}%)',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pendente: ${currency.format(pending)} (${(pendingPct * 100).toStringAsFixed(1)}%)',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(
    BuildContext context,
    RealtimeDbService dbService,
    List<Map<String, dynamic>> allClientsList,
    bool isNarrow,
  ) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: dbService.getBpoDocuments(),
      builder: (context, docSnap) {
        if (docSnap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
          );
        }

        final docData = docSnap.data ?? {};
        final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

        // Calcular Pendências Totais
        int totalPendingItems = 0;
        for (var client in allClientsList) {
          final String cid = client['id'];
          final clientDocs = docData[cid]?[currentMonth] as Map? ?? {};
          if (clientDocs['bankStatement'] != true) totalPendingItems++;
          if (clientDocs['salesInvoices'] != true) totalPendingItems++;
          if (clientDocs['purchaseReceipts'] != true) totalPendingItems++;
        }

        return Padding(
          padding: EdgeInsets.all(isNarrow ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Título & Subtítulo
              Text(
                'Checklist de Documentos Mensais 📂',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Monitore o envio de extratos bancários, XMLs e comprovantes dos clientes para o fechamento do mês.',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 24),

              // KPI de Pendências
              _buildKpiCard(
                title: 'Pendências no Mês',
                value: totalPendingItems.toString(),
                subtitle: 'Total de documentos pendentes na carteira',
                gradientColors: totalPendingItems > 0
                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                    : [const Color(0xFF10B981), const Color(0xFF059669)],
                icon: Icons.folder_zip_rounded,
              ),

              const SizedBox(height: 40),

              _buildSectionHeader('ENTREGA DE DOCUMENTOS - FECHAMENTO ${DateFormat('MMMM / yyyy', 'pt_BR').format(DateTime.now()).toUpperCase()}', Icons.playlist_add_check_rounded),
              const SizedBox(height: 16),

              if (allClientsList.isEmpty)
                _buildEmptyStateCard('Vincule clientes primeiro na aba principal.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allClientsList.length,
                  itemBuilder: (context, idx) {
                    final client = allClientsList[idx];
                    final String cid = client['id'];
                    final String name = client['name'];
                    final String meta = client['meta'];
                    final String? phone = client['phone'];

                    final clientDocs = docData[cid]?[currentMonth] as Map? ?? {};
                    final bool hasStatement = clientDocs['bankStatement'] == true;
                    final bool hasInvoices = clientDocs['salesInvoices'] == true;
                    final bool hasReceipts = clientDocs['purchaseReceipts'] == true;

                    final bool isAllReceived = hasStatement && hasInvoices && hasReceipts;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: isNarrow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: isAllReceived ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name.toUpperCase(),
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildDocCheckChip(context, dbService, cid, 'bankStatement', 'Extrato', hasStatement),
                                    _buildDocCheckChip(context, dbService, cid, 'salesInvoices', 'XML/Notas', hasInvoices),
                                    _buildDocCheckChip(context, dbService, cid, 'purchaseReceipts', 'Recibos', hasReceipts),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (!isAllReceived)
                                  _buildDocReminderButton(context, name, phone, hasStatement, hasInvoices, hasReceipts),
                              ],
                            )
                          : Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isAllReceived ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.toUpperCase(),
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        meta,
                                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildDocCheckChip(context, dbService, cid, 'bankStatement', 'Extrato Bancário', hasStatement),
                                      _buildDocCheckChip(context, dbService, cid, 'salesInvoices', 'Notas Fiscais', hasInvoices),
                                      _buildDocCheckChip(context, dbService, cid, 'purchaseReceipts', 'Comprovantes', hasReceipts),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (!isAllReceived)
                                  _buildDocReminderButton(context, name, phone, hasStatement, hasInvoices, hasReceipts)
                                else
                                  const SizedBox(width: 48, height: 48),
                              ],
                            ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocCheckChip(
    BuildContext context,
    RealtimeDbService dbService,
    String clientUid,
    String docType,
    String label,
    bool value,
  ) {
    return ActionChip(
      onPressed: () async {
        await dbService.saveBpoDocumentStatus(clientUid, docType, !value);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Checklist "$label" atualizado!')),
          );
        }
      },
      avatar: Icon(
        value ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        color: value ? Colors.white : const Color(0xFF64748B),
        size: 16,
      ),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: value ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
      backgroundColor: value ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildDocReminderButton(
    BuildContext context,
    String clientName,
    String? phone,
    bool hasStatement,
    bool hasInvoices,
    bool hasReceipts,
  ) {
    return IconButton(
      onPressed: () async {
        final cleanPhone = phone?.replaceAll(RegExp(r'\D'), '') ?? '';
        if (cleanPhone.isNotEmpty) {
          final String ddi = cleanPhone.startsWith('55') ? '' : '55';
          final List<String> pendingList = [];
          if (!hasStatement) pendingList.add('• Extrato Bancário Conciliado');
          if (!hasInvoices) pendingList.add('• Notas Fiscais de Venda/Serviço (XML)');
          if (!hasReceipts) pendingList.add('• Comprovantes de Despesa/Pagamento');

          final String checklist = pendingList.join('\n');
          final message = Uri.encodeComponent(
            'Olá, $clientName! Tudo bem?\n\nLembramos que para podermos realizar o fechamento financeiro do mês corrente, precisamos que você nos envie os seguintes documentos pendentes:\n\n$checklist\n\nPor favor, nos envie assim que puder! Muito obrigado pela ajuda! 👍'
          );
          final url = 'https://wa.me/$ddi$cleanPhone?text=$message';
          await launchUrlString(url, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ WhatsApp do cliente não cadastrado! Vincule o contato nas configurações ou nas abas anteriores.'),
              backgroundColor: Colors.amber,
            ),
          );
        }
      },
      icon: const Icon(Icons.notifications_active_outlined, color: Color(0xFFEF4444), size: 20),
      tooltip: 'Enviar checklist de pendências via WhatsApp',
    );
  }

  Widget _buildHeaderButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    final Color bgColor = isPrimary ? const Color(0xFF2563EB) : Colors.white;
    final Color fgColor = isPrimary ? Colors.white : const Color(0xFF0F172A);
    final BorderSide borderSide = isPrimary ? BorderSide.none : const BorderSide(color: Color(0xFFE2E8F0));

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        side: borderSide,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: isPrimary ? 2 : 0,
        shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isLoading 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(icon, size: 18, color: fgColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.12),
              size: 72,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: const Color(0xFF64748B),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildClientItemCard(
    BuildContext context, {
    required String name,
    required String meta,
    required double balance,
    required bool isRed,
    required int dueToday,
    required String status,
    required String lastSync,
    required bool isActive,
    required bool isOmie,
    String? phone,
    required VoidCallback onManage,
  }) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final Color statusColor = status == 'Sucesso' || status == 'Firebase'
        ? const Color(0xFF10B981)
        : (status == 'Sincronizando' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive 
                ? const Color(0xFF2563EB).withValues(alpha: 0.06)
                : const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onManage,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar do Cliente
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B)).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOmie ? Icons.business_center_rounded : Icons.person_rounded,
                    color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informações Básicas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'GERENCIANDO',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF2563EB),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      // Badge de Status de Conexão
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isOmie ? '$status • Ref: $lastSync' : 'Cliente Conectado (Nuvem)',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => launchUrlString('https://wa.me/55$phone?text=Olá! Como estão as finanças hoje?'),
                    icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF10B981), size: 22),
                    tooltip: 'Conversar no WhatsApp',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () async {
                      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                      if (cleanPhone.isNotEmpty) {
                        final String ddi = cleanPhone.startsWith('55') ? '' : '55';
                        final String typeStr = isOmie ? 'Omie ERP' : 'Controle Manual';
                        final message = Uri.encodeComponent(
                          '📊 *Fechamento Financeiro: $name*\n'
                          'Tipo de Controle: $typeStr\n\n'
                          '💰 *Saldo de Caixa:* ${currency.format(balance)}\n'
                          '⚡ *Lançamentos Hoje:* $dueToday itens\n\n'
                          'Qualquer dúvida sobre a conciliação, estamos à disposição! 👍'
                        );
                        final url = 'https://wa.me/$ddi$cleanPhone?text=$message';
                        await launchUrlString(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.share_rounded, color: Color(0xFF2563EB), size: 20),
                    tooltip: 'Compartilhar Fechamento via WhatsApp',
                  ),
                ],

                const SizedBox(width: 16),

                // Seção Direita de Valores / Alertas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isOmie ? 'SALDO EM CONTA' : 'SALDO MANUAL',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      currency.format(balance),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isRed ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: dueToday > 0 
                            ? const Color(0xFFFFF7ED) 
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: dueToday > 0 
                              ? const Color(0xFFFFEDD5) 
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '$dueToday ${isOmie ? "contas hoje" : "hoje"}',
                        style: GoogleFonts.inter(
                          color: dueToday > 0 ? const Color(0xFFC2410C) : const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // Botão Gerenciar de Alta Estética
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'GERENCIAR',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isActive ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
