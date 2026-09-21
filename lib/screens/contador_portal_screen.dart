import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../providers/transactions_provider.dart';
import '../services/realtime_db_service.dart';
import '../models/transaction_model.dart';
import 'login_screen.dart';

class ContadorPortalScreen extends StatefulWidget {
  const ContadorPortalScreen({super.key});

  @override
  State<ContadorPortalScreen> createState() => _ContadorPortalScreenState();
}

class _ContadorPortalScreenState extends State<ContadorPortalScreen> {
  int _activeTab = 0; // 0 = Clientes, 1 = Auditoria, 2 = Parecer, 3 = Exportação
  String? _selectedClientUid;
  String? _selectedClientName;

  final RealtimeDbService _dbService = RealtimeDbService();
  final TextEditingController _messageController = TextEditingController();

  DateTimeRange? _exportDateRange;
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final String currentContadorUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Sleek Dark Slate
      appBar: AppBar(
        title: Text(
          'Portal do Contador 💼',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Sair da Conta',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 🧭 SIDE MENU (DESKTOP E TABLET)
          _buildSideNavigation(),

          // 💻 CONTEÚDO PRINCIPAL
          Expanded(
            child: Container(
              color: const Color(0xFF0B0F19), // Fundo ainda mais escuro para contraste
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClientStatusBanner(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildActiveTabContent(provider, currentContadorUid),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🧭 Side Navigation Menu
  Widget _buildSideNavigation() {
    return Container(
      width: 250,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            'GerePag Fiscal',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Copiloto do Contador Parceiro',
            style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          _buildNavItem(icon: Icons.people_rounded, label: 'Carteira de Clientes', index: 0),
          _buildNavItem(icon: Icons.checklist_rtl_rounded, label: 'Auditoria Fiscal', index: 1, requiresClient: true),
          _buildNavItem(icon: Icons.quickreply_rounded, label: 'Parecer Técnico', index: 2, requiresClient: true),
          _buildNavItem(icon: Icons.file_download_outlined, label: 'Exportação Contábil', index: 3, requiresClient: true),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Parceria Ativa 🌟', style: TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Você está usando o painel fiscal avançado GerePag para auditores.',
                    style: TextStyle(color: Colors.white70, fontSize: 10, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool requiresClient = false,
  }) {
    final bool isSelected = _activeTab == index;
    final bool isEnabled = !requiresClient || _selectedClientUid != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: isEnabled
            ? () => setState(() => _activeTab = index)
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Selecione um cliente na carteira para acessar este menu.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F172A)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Colors.teal.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.tealAccent
                    : (isEnabled ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? Colors.white
                        : (isEnabled ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📝 Banner de Estado do Cliente Ativo
  Widget _buildClientStatusBanner() {
    if (_selectedClientUid == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blueAccent, size: 22),
            const SizedBox(width: 12),
            Text(
              'Nenhum cliente selecionado. Escolha um na lista abaixo para auditar.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)], // Teal Gradient
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.2), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auditando Cliente: $_selectedClientName',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'UID: $_selectedClientUid',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedClientUid = null;
                _selectedClientName = null;
                _activeTab = 0;
              });
              _dbService.setBpoActiveClient(null);
            },
            icon: const Icon(Icons.close_rounded, size: 14),
            label: const Text('LIMPAR SELEÇÃO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // 📂 Direcionador de Conteúdo de Abas
  Widget _buildActiveTabContent(TransactionsProvider provider, String contadorUid) {
    switch (_activeTab) {
      case 1:
        return _buildAuditingTab();
      case 2:
        return _buildNotesTab();
      case 3:
        return _buildExportTab();
      case 0:
      default:
        return _buildClientsTab(provider, contadorUid);
    }
  }

  // 👥 ABA 0: Carteira de Clientes
  Widget _buildClientsTab(TransactionsProvider provider, String contadorUid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Minha Carteira de Clientes 💼',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _buildLinkCodeCard(contadorUid),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _dbService.getContadorClients(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyClientsState(contadorUid);
              }

              final clients = snapshot.data!;
              return ListView.builder(
                itemCount: clients.length,
                itemBuilder: (context, idx) {
                  final client = clients[idx];
                  final String clientId = client['id'] ?? '';
                  final String name = client['name'] ?? 'Cliente Sem Nome';
                  final String? email = client['email'];
                  final isCurrentActive = _selectedClientUid == clientId;

                  return StreamBuilder<List<TransactionModel>>(
                    stream: _dbService.getClientTransactions(clientId),
                    builder: (context, transSnap) {
                      final transactions = transSnap.data ?? [];
                      double balance = 0.0;
                      int auditedCount = 0;
                      for (var tx in transactions) {
                        if (tx.type == TransactionType.income) {
                          balance += tx.amount;
                        } else {
                          balance -= tx.amount;
                        }
                        if (tx.auditedByContador) {
                          auditedCount++;
                        }
                      }

                      final int totalTx = transactions.length;
                      final double auditProgress = totalTx > 0 ? (auditedCount / totalTx) : 1.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCurrentActive ? Colors.tealAccent : const Color(0xFF334155),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  _dbService.setBpoActiveClient(clientId);
                                  await provider.init();
                                  setState(() {
                                    _selectedClientUid = clientId;
                                    _selectedClientName = name;
                                    _activeTab = 1; // Mudar para auditoria automaticamente
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('📂 Cliente "$name" selecionado! Iniciando auditoria.'),
                                      backgroundColor: Colors.teal,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isCurrentActive 
                                              ? Colors.teal.withValues(alpha: 0.2)
                                              : const Color(0xFF0F172A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.storefront_rounded,
                                          color: isCurrentActive ? Colors.tealAccent : const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              email ?? 'Sem e-mail cadastrado',
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF94A3B8),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            // Progresso de auditoria
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: LinearProgressIndicator(
                                                    value: auditProgress,
                                                    backgroundColor: const Color(0xFF0F172A),
                                                    color: Colors.tealAccent,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  '$auditedCount/$totalTx Auditados',
                                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'SALDO DE CAIXA',
                                            style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                          ),
                                          Text(
                                            currency.format(balance),
                                            style: GoogleFonts.outfit(
                                              color: balance >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLinkCodeCard(String contadorUid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.vpn_key_rounded, color: Colors.tealAccent, size: 14),
          const SizedBox(width: 8),
          Text(
            'Seu ID: ',
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
          ),
          SelectableText(
            contadorUid,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: contadorUid));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 ID de Vinculação copiado com sucesso!'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
            child: const Icon(Icons.copy_rounded, color: Colors.tealAccent, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyClientsState(String contadorUid) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded, size: 60, color: Color(0xFF475569)),
            const SizedBox(height: 20),
            Text(
              'Sua carteira está vazia! 💼',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Compartilhe seu ID de Vinculação abaixo com seus clientes. Eles devem acessar Configurações e colar este código para vincular o painel deles ao seu Portal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildLinkCodeCard(contadorUid),
          ],
        ),
      ),
    );
  }

  // 📝 ABA 1: Auditoria Fiscal
  Widget _buildAuditingTab() {
    if (_selectedClientUid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revisão e Auditoria Fiscal 📑',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Audite lançamentos e salve o status de conformidade tributária diretamente no caixa do cliente.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<List<TransactionModel>>(
            stream: _dbService.getClientTransactions(_selectedClientUid!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Nenhuma transação encontrada para este cliente.', style: TextStyle(color: Color(0xFF64748B))),
                );
              }

              final txs = snapshot.data!
                ..sort((a, b) => b.date.compareTo(a.date));

              return ListView.builder(
                itemCount: txs.length,
                itemBuilder: (context, index) {
                  final tx = txs[index];
                  final isIncome = tx.type == TransactionType.income;
                  final String dateStr = DateFormat('dd/MM/yyyy').format(tx.date);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: tx.auditedByContador 
                              ? Colors.teal.withValues(alpha: 0.5) 
                              : const Color(0xFF334155),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Status
                          Icon(
                            tx.auditedByContador ? Icons.verified_rounded : Icons.pending_actions_rounded,
                            color: tx.auditedByContador ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      tx.description.isNotEmpty ? tx.description : 'Sem Descrição',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (tx.auditedByContador)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'AUDITADO',
                                          style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$dateStr • Categoria: ${tx.category}',
                                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          // Valor
                          Text(
                            (isIncome ? '+' : '-') + currency.format(tx.amount),
                            style: GoogleFonts.outfit(
                              color: isIncome ? const Color(0xFF34D399) : const Color(0xFFF87171),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Checkbox de auditoria
                          Checkbox(
                            value: tx.auditedByContador,
                            activeColor: Colors.tealAccent,
                            checkColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFF64748B)),
                            onChanged: (bool? val) async {
                              if (val != null) {
                                await _dbService.toggleTransactionTaxAudit(_selectedClientUid!, tx.id, val);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(val 
                                          ? '✅ Lançamento auditado com sucesso!'
                                          : '🔄 Status de auditoria removido.'),
                                      backgroundColor: val ? Colors.teal : Colors.orange,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 📝 ABA 2: Parecer Técnico do Contador
  Widget _buildNotesTab() {
    if (_selectedClientUid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parecer Técnico & Recomendações ✍️',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Escreva orientações fiscais ou alertas para o seu cliente. Seu aviso aparecerá de forma prioritária no topo do painel dele.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Histórico / Parecer ativo
                StreamBuilder<Map<String, dynamic>?>(
                  stream: _dbService.getContadorMessageForClient(), // Como o effective UID é o do cliente selecionado, busca a mensagem dele!
                  builder: (context, snap) {
                    final messageData = snap.data;
                    final String activeMessage = messageData?['message'] ?? 'Nenhum parecer enviado ainda.';
                    final int? ts = messageData?['sentAt'];
                    final String dateStr = ts != null 
                        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ts))
                        : '';

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PARECER ATIVO NO DASHBOARD DO CLIENTE',
                                style: GoogleFonts.inter(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              if (dateStr.isNotEmpty)
                                Text(
                                  'Enviado em $dateStr',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            activeMessage,
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Novo Parecer Técnico:',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Digite as instruções aqui (Ex: Lembrete de pagamento do DAS, dicas de redução tributária ou auditorias críticas)...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.tealAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final text = _messageController.text.trim();
                      if (text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Escreva uma mensagem antes de enviar.')),
                        );
                        return;
                      }

                      await _dbService.setContadorMessage(_selectedClientUid!, text);
                      _messageController.clear();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🚀 Parecer Técnico publicado com sucesso no painel do cliente!'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('ENVIAR NOTA E NOTIFICAR CLIENTE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 📂 ABA 3: Exportação Contábil CSV
  Widget _buildExportTab() {
    if (_selectedClientUid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exportação Contábil Fiscal (CSV) 📊',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Gere o extrato contábil formatado. O arquivo gerado pode ser importado diretamente no software da sua contabilidade (ex: Domínio Sistemas, Alterdata).',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtros de Período',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                locale: const Locale('pt', 'BR'),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Colors.tealAccent,
                                        onPrimary: Color(0xFF0F172A),
                                        surface: Color(0xFF1E293B),
                                        onSurface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (range != null) {
                                setState(() => _exportDateRange = range);
                              }
                            },
                            icon: const Icon(Icons.date_range_rounded, size: 16, color: Colors.tealAccent),
                            label: Text(
                              _exportDateRange == null
                                  ? 'SELECIONAR DATAS'
                                  : '${DateFormat('dd/MM/yy').format(_exportDateRange!.start)} até ${DateFormat('dd/MM/yy').format(_exportDateRange!.end)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF475569)),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              StreamBuilder<List<TransactionModel>>(
                stream: _dbService.getClientTransactions(_selectedClientUid!),
                builder: (context, snapshot) {
                  final transactions = snapshot.data ?? [];
                  final filtered = transactions.where((t) {
                    if (_exportDateRange == null) return true;
                    return t.date.isAfter(_exportDateRange!.start.subtract(const Duration(days: 1))) &&
                        t.date.isBefore(_exportDateRange!.end.add(const Duration(days: 1)));
                  }).toList();

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Lançamentos filtrados:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                          Text(
                            '${filtered.length} Transações',
                            style: GoogleFonts.outfit(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: filtered.isEmpty
                              ? null
                              : () {
                                  _exportTransactionsToCsv(filtered);
                                },
                          icon: const Icon(Icons.file_present_rounded, size: 18),
                          label: const Text('COMPARTILHAR EXTRATO FISCAL (CSV)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF1E293B),
                            disabledForegroundColor: const Color(0xFF475569),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
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
    );
  }

  // Lógica de exportação contábil imediata
  void _exportTransactionsToCsv(List<TransactionModel> list) {
    String csv = 'Data,Categoria,Descricao,Valor,Tipo,Auditado pelo Contador\n';
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (var t in list) {
      final String typeStr = t.type == TransactionType.income ? 'Entrada' : 'Saida';
      csv += '${dateFormat.format(t.date)},${t.category},${t.description.replaceAll(',', ';')},${t.amount},$typeStr,${t.auditedByContador ? 'Sim' : 'Nao'}\n';
    }

    Share.share(csv, subject: 'Exportação Fiscal GerePag - Cliente $_selectedClientName');
  }
}
