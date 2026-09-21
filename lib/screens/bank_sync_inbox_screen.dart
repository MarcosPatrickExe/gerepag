import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import '../models/transaction_model.dart';
import '../services/realtime_db_service.dart';

class BankSyncInboxScreen extends StatefulWidget {
  const BankSyncInboxScreen({super.key});

  @override
  State<BankSyncInboxScreen> createState() => _BankSyncInboxScreenState();
}

class _BankSyncInboxScreenState extends State<BankSyncInboxScreen> {
  final RealtimeDbService _db = RealtimeDbService();
  String _selectedFilter = 'all'; // all, suggested, confirmed, ignored
  bool _isReconcilingAll = false;
  String _searchQuery = '';
  double _minAmountFilter = 0.0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _db.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getFriendlyAppName(String packageName) {
    switch (packageName) {
      case 'com.nu.production': return 'Nubank 🟣';
      case 'br.com.inter': return 'Banco Inter 🟠';
      case 'br.com.next': return 'Next 🟢';
      case 'br.com.bb.android': return 'Banco do Brasil 🟡';
      case 'com.itau': return 'Itaú 🔵';
      case 'br.com.itau.pers': return 'Itaú Personnalité 💎';
      case 'com.bradesco': return 'Bradesco 🔴';
      case 'br.com.bradesco.netemp': return 'Bradesco Empresas 💼';
      case 'br.com.santander.teller': return 'Santander 🟥';
      case 'com.c6bank.app': return 'C6 Bank ⚫';
      case 'br.com.caixa.mobi': return 'Caixa Econômica 🟦';
      case 'com.mercadopago.wallet': return 'Mercado Pago 🔵';
      case 'br.com.uol.ps.phone': return 'PagBank 🟢';
      case 'com.picpay': return 'PicPay 🟢';
      default: return packageName.split('.').last;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return AppTheme.income;
      case 'ignored': return AppTheme.textMuted;
      default: return Colors.orangeAccent;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle_outline_rounded;
      case 'ignored': return Icons.block_rounded;
      default: return Icons.pending_actions_rounded;
    }
  }

  Future<void> _reconcileAll(List<Map<String, dynamic>> pendings) async {
    setState(() => _isReconcilingAll = true);
    
    int successCount = 0;
    int failCount = 0;
    final provider = Provider.of<TransactionsProvider>(context, listen: false);

    for (var log in pendings) {
      try {
        final double amount = (log['amount'] as num?)?.toDouble() ?? 0.0;
        final String store = log['restaurant'] ?? '';
        final bool isIncome = log['isIncome'] ?? false;
        final int? nCodLanc = log['nCodLanc'] != null ? int.tryParse(log['nCodLanc'].toString()) : null;
        final String category = log['suggestedCategory'] ?? (isIncome ? 'Receitas' : 'Geral');
        
        DateTime? date;
        if (log['timestamp'] != null) {
          date = DateTime.tryParse(log['timestamp']);
        }
        date ??= DateTime.now();

        // 1. Adicionar transação locally/Firebase
        await provider.addTransaction(TransactionModel(
          id: '',
          description: store,
          amount: amount,
          category: category,
          date: date,
          type: isIncome ? TransactionType.income : TransactionType.expense,
        ));

        // 2. Dar baixa no Omie se houver nCodLanc
        if (nCodLanc != null) {
          await provider.payOmieBill(nCodLanc, amount);
        }

        // 3. Atualizar status na Caixa de Entrada
        await _db.updateNotificationLogStatus(log['id'], 'confirmed');

        // 4. Registrar no log de auditoria BPO
        final clientName = RealtimeDbService.bpoActiveClientUid != null
            ? (await _db.getBpoClients().first).firstWhere(
                (c) => c['id'] == RealtimeDbService.bpoActiveClientUid,
                orElse: () => {'name': 'Cliente'},
              )['name']?.toString() ?? 'Cliente'
            : 'Minha Conta';
        await _db.addAuditLog({
          'action': 'reconciled',
          'description': store,
          'amount': amount,
          'clientName': clientName,
        });

        successCount++;
      } catch (e) {
        failCount++;
        debugPrint('Erro ao conciliar item individual: $e');
      }
    }

    if (mounted) {
      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sucesso! Todas as $successCount transações conciliadas. 🎉'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conciliação em lote finalizada. Sucessos: $successCount | Falhas: $failCount'),
            backgroundColor: Colors.orangeAccent,
          )
        );
      }
      setState(() => _isReconcilingAll = false);
    }
  }

  Future<void> _undoReconciliation(Map<String, dynamic> log) async {
    final provider = Provider.of<TransactionsProvider>(context, listen: false);
    final double amount = (log['amount'] as num?)?.toDouble() ?? 0.0;
    final String store = log['restaurant'] ?? '';
    final bool isIncome = log['isIncome'] ?? false;

    try {
      // 1. Procurar a transação correspondente no Provider
      final List<TransactionModel> txs = provider.transactions;
      TransactionModel? targetTx;
      
      for (var tx in txs) {
        if ((tx.amount - amount).abs() < 0.01 &&
            tx.description == store &&
            tx.type == (isIncome ? TransactionType.income : TransactionType.expense)) {
          DateTime? logDate = log['timestamp'] != null ? DateTime.tryParse(log['timestamp']) : null;
          logDate ??= DateTime.now();
          if (tx.date.year == logDate.year &&
              tx.date.month == logDate.month &&
              tx.date.day == logDate.day) {
            targetTx = tx;
            break;
          }
        }
      }

      if (targetTx != null) {
        // 2. Excluir a transação
        await provider.deleteTransaction(targetTx.id);
      }

      // 3. Reverter status na Caixa de Entrada e flag autoReconciled
      await _db.updateNotificationLogStatusAndFlags(log['id'], status: 'suggested', autoReconciled: false);

      // 4. Registrar desfazimento no log de auditoria
      await _db.addAuditLog({
        'action': 'undone',
        'description': store,
        'amount': amount,
        'clientName': 'Minha Conta',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conciliação desfeita e transação removida! 🔄'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao desfazer conciliação: $e'), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Fundo azul escuro espacial
      body: Stack(
        children: [
          // 1. Grid de pontos e gradiente de fundo
          _buildBackgroundGradient(),
          SafeArea(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getNotificationLogs(),
              builder: (context, snapshot) {
                final logs = snapshot.data ?? [];
                
                // Aplicar filtros
                var filteredLogs = logs.where((log) {
                  if (_selectedFilter == 'all') return true;
                  return log['status'] == _selectedFilter;
                }).toList();

                // Filtrar por busca
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filteredLogs = filteredLogs.where((log) {
                    final title = (log['title'] ?? '').toString().toLowerCase();
                    final text = (log['text'] ?? '').toString().toLowerCase();
                    final restaurant = (log['restaurant'] ?? '').toString().toLowerCase();
                    final bank = _getFriendlyAppName(log['packageName'] ?? '').toLowerCase();
                    return title.contains(q) || text.contains(q) || restaurant.contains(q) || bank.contains(q);
                  }).toList();
                }

                // Filtrar por valor mínimo
                if (_minAmountFilter > 0) {
                  filteredLogs = filteredLogs.where((log) {
                    final amount = (log['amount'] as num?)?.toDouble() ?? 0.0;
                    return amount >= _minAmountFilter;
                  }).toList();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho (passando os logs totais para verificar pendências)
                      _buildHeader(context, logs),
                      const SizedBox(height: 16),
                      // Painel de Métricas de Economia de Tempo
                      _buildMetricsDashboard(logs),
                      const SizedBox(height: 16),
                      // Filtro de Busca e Valor
                      _buildSearchAndAmountFilters(),
                      const SizedBox(height: 16),
                      // Barra de Filtros de Categoria
                      _buildFilterTabs(),
                      const SizedBox(height: 16),
                      // Conteúdo da Caixa de Entrada
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                            : snapshot.hasError
                                ? Center(child: Text('Erro ao carregar notificações: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)))
                                : filteredLogs.isEmpty
                                    ? _buildEmptyState()
                                    : ListView.builder(
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: filteredLogs.length,
                                        itemBuilder: (context, index) {
                                          final log = filteredLogs[index];
                                          return _buildNotificationCard(context, provider, log);
                                        },
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
  }

  Widget _buildBackgroundGradient() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.2,
            colors: [
              Color(0xFF1E1B4B), // Indigo profundo
              Color(0xFF020617), // Fundo escuro padrão
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<Map<String, dynamic>> logs) {
    // Filtrar notificações pendentes (sugeridas) para conciliação em lote
    final pendingLogs = logs.where((log) => log['status'] == 'suggested').toList();
    final hasPendings = pendingLogs.isNotEmpty;

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white10,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Caixa de Entrada Bancária',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 2),
              const Text(
                'Conciliação e auditoria das notificações de bancos',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showRulesManagementSheet(context),
          icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white10,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          tooltip: 'Regras de Automação',
        ),
        const SizedBox(width: 8),
        if (hasPendings && !_isReconcilingAll)
          ElevatedButton.icon(
            onPressed: () => _reconcileAll(pendingLogs),
            icon: const Icon(Icons.playlist_add_check_rounded, color: Colors.white, size: 16),
            label: const Text('CONCILIAR TUDO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        if (_isReconcilingAll)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ),
      ],
    );
  }

  Widget _buildMetricsDashboard(List<Map<String, dynamic>> logs) {
    final totalCount = logs.length;
    final autoReconciledCount = logs.where((l) => l['status'] == 'confirmed' && (l['autoReconciled'] ?? false)).length;
    final confirmedCount = logs.where((l) => l['status'] == 'confirmed').length;
    
    final double efficiency = totalCount > 0 ? (confirmedCount / totalCount) * 100 : 0.0;
    final double timeSavedSeconds = autoReconciledCount * 30.0;
    final String timeSavedStr = timeSavedSeconds >= 60 
        ? '${(timeSavedSeconds / 60).toStringAsFixed(1)}m poupado'
        : '${timeSavedSeconds.toInt()}s poupado';

    return Row(
      children: [
        _buildMetricItem('Economia ⚡', timeSavedStr, Colors.amberAccent),
        const SizedBox(width: 8),
        _buildMetricItem('Autoconciliados', '$autoReconciledCount Pix ⚡', AppTheme.income),
        const SizedBox(width: 8),
        _buildMetricItem('Eficiência', '${efficiency.toStringAsFixed(0)}% conc.', AppTheme.primary),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndAmountFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Buscar por estabelecimento ou banco...',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
            suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Valor Mínimo: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            const SizedBox(width: 8),
            _buildAmountFilterButton(0.0, 'Todos'),
            const SizedBox(width: 8),
            _buildAmountFilterButton(50.0, '> R\$ 50'),
            const SizedBox(width: 8),
            _buildAmountFilterButton(100.0, '> R\$ 100'),
            const SizedBox(width: 8),
            _buildAmountFilterButton(500.0, '> R\$ 500'),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountFilterButton(double val, String label) {
    final bool isSelected = _minAmountFilter == val;
    return GestureDetector(
      onTap: () => setState(() => _minAmountFilter = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.textMuted,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _buildTab('all', 'Todas'),
          _buildTab('suggested', 'Pendentes'),
          _buildTab('confirmed', 'Conciliadas'),
          _buildTab('ignored', 'Ignoradas'),
        ],
      ),
    );
  }

  Widget _buildTab(String filter, String label) {
    final bool isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, TransactionsProvider provider, Map<String, dynamic> log) {
    final double amount = (log['amount'] as num?)?.toDouble() ?? 0.0;
    final String store = log['restaurant'] ?? '';
    final String title = log['title'] ?? '';
    final String text = log['text'] ?? '';
    final String status = log['status'] ?? 'suggested';
    final bool isIncome = log['isIncome'] ?? false;
    final int? nCodLanc = log['nCodLanc'] != null ? int.tryParse(log['nCodLanc'].toString()) : null;
    final String category = log['suggestedCategory'] ?? (isIncome ? 'Receitas' : 'Geral');
    final bool autoReconciled = log['autoReconciled'] ?? false;
    
    DateTime? date;
    if (log['timestamp'] != null) {
      date = DateTime.tryParse(log['timestamp']);
    }
    date ??= DateTime.now();

    // Verificação de divergência/atraso crítico de data
    DateTime? dueDate;
    if (log['dueDate'] != null) {
      final String dStr = log['dueDate'].toString();
      final parts = dStr.split('/');
      if (parts.length == 3) {
        dueDate = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      } else {
        dueDate = DateTime.tryParse(dStr);
      }
    }

    bool hasDateDivergence = false;
    int daysLate = 0;
    if (dueDate != null) {
      final dueZero = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final payZero = DateTime(date.year, date.month, date.day);
      if (payZero.isAfter(dueZero.add(const Duration(days: 5)))) {
        hasDateDivergence = true;
        daysLate = payZero.difference(dueZero).inDays;
      }
    }

    final Color statusColor = _getStatusColor(status);
    final isPending = status == 'suggested';

    final bool isSuspect = log['isSuspect'] ?? false;
    final String? anomalyReason = log['anomalyReason'];
    final String? ruleMatched = log['ruleMatched'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSuspect ? Colors.redAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
          width: isSuspect ? 1.5 : 1.0,
        ),
        boxShadow: isSuspect 
          ? [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.04), blurRadius: 12, spreadRadius: 1)]
          : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.1),
                radius: 16,
                child: Icon(_getStatusIcon(status), color: statusColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getFriendlyAppName(log['packageName'] ?? ''),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Text(
                DateFormat('dd/MM HH:mm').format(date),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title.isNotEmpty ? '$title - $text' : text,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
          ),
          if (isSuspect && anomalyReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sentinela Guard: $anomalyReason',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasDateDivergence) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Atraso Crítico: Recebimento com $daysLate dias de atraso (Vencimento: ${log['dueDate']})',
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    autoReconciled
                        ? 'Autoconciliado ⚡'
                        : (nCodLanc != null ? 'Omie Vincular: #$nCodLanc' : 'Lançamento Manual'),
                    style: TextStyle(
                      color: autoReconciled ? AppTheme.income : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: autoReconciled ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (ruleMatched != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '⚙️ Regra: $ruleMatched',
                            style: const TextStyle(color: Colors.indigoAccent, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.simpleCurrency(locale: 'pt_BR').format(amount),
                    style: TextStyle(
                      color: isIncome ? AppTheme.income : AppTheme.expense,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await _db.updateNotificationLogStatus(log['id'], 'ignored');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notificação marcada como ignorada.'))
                      );
                    }
                  },
                  child: const Text('IGNORAR', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    // 1. Adicionar transação locally/Firebase
                    await provider.addTransaction(TransactionModel(
                      id: '',
                      description: store,
                      amount: amount,
                      category: category,
                      date: date!,
                      type: isIncome ? TransactionType.income : TransactionType.expense,
                    ));

                    // 2. Dar baixa no Omie se houver nCodLanc
                    if (nCodLanc != null) {
                      final success = await provider.payOmieBill(nCodLanc, amount);
                      if (success) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reconciliação e quitação efetuadas no Omie! 🎉'))
                          );
                        }
                      }
                    }

                    // 3. Atualizar status na Caixa de Entrada
                    await _db.updateNotificationLogStatus(log['id'], 'confirmed');
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transação conciliada e registrada com sucesso!'))
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    nCodLanc != null ? 'CONCILIAR TÍTULO' : 'REGISTRAR AGORA',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'confirmed') ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _undoReconciliation(log),
                  icon: const Icon(Icons.undo_rounded, size: 14, color: Colors.redAccent),
                  label: const Text(
                    'DESFAZER CONCILIAÇÃO',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, color: AppTheme.textMuted, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Caixa de Entrada Vazia',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nenhuma notificação encontrada para este filtro.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
  void _showRulesManagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const _RulesManagerBottomSheet(),
        ),
      ),
    );
  }
}

class _RulesManagerBottomSheet extends StatefulWidget {
  const _RulesManagerBottomSheet();

  @override
  State<_RulesManagerBottomSheet> createState() => _RulesManagerBottomSheetState();
}

class _RulesManagerBottomSheetState extends State<_RulesManagerBottomSheet> {
  final RealtimeDbService _db = RealtimeDbService();
  final TextEditingController _keywordController = TextEditingController();
  String _selectedCategory = 'Geral';
  bool _autoApprove = false;
  String _selectedBank = 'Todos';
  String _selectedClientScope = 'global'; // 'global' or a clientUid
  List<Map<String, dynamic>> _bpoClients = [];

  @override
  void initState() {
    super.initState();
    // Load BPO clients list for scope selector
    _db.getBpoClients().first.then((clients) {
      if (mounted) setState(() => _bpoClients = clients);
    });
  }

  final List<String> _categories = [
    'Comida',
    'Transporte',
    'Lazer',
    'Saúde',
    'Receitas',
    'Geral',
    'Outros',
    'Tarifas Bancárias',
    'Impostos',
    'Salários'
  ];

  final List<String> _banks = [
    'Todos',
    'Nubank',
    'Banco Inter',
    'Next',
    'Banco do Brasil',
    'Itaú',
    'Bradesco',
    'Santander',
    'C6 Bank',
    'Caixa Econômica',
    'Mercado Pago',
    'PagBank',
    'PicPay'
  ];

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _addRule() async {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insira uma palavra-chave!'))
      );
      return;
    }

    final rule = {
      'keyword': keyword,
      'category': _selectedCategory,
      'autoApprove': _autoApprove,
      'bankFilter': _selectedBank,
      'clientScope': _selectedClientScope,
    };

    await _db.addReconciliationRule(rule);
    _keywordController.clear();
    setState(() {
      _autoApprove = false;
      _selectedBank = 'Todos';
      _selectedClientScope = 'global';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regra de automação criada com sucesso! ⚙️'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D), // Fundo ultra escuro espacial
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Indicador de arrasto
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              children: [
                Row(
                  children: [
                    const Icon(Icons.rule_rounded, color: AppTheme.primary, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Regras de Automação',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Crie regras para classificar e conciliar transações automaticamente usando termos que aparecem nas notificações do banco.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Form de Adição de Regra
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOVA REGRA',
                        style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 16),
                      // Palavra-chave
                      TextField(
                        controller: _keywordController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Palavra-chave (ex: Uber, IFood, Posto)',
                          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.02),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Categoria e Banco Filtro (Lado a Lado)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Categoria', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      dropdownColor: const Color(0xFF0F172A),
                                      isExpanded: true,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
                                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                      onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Banco', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedBank,
                                      dropdownColor: const Color(0xFF0F172A),
                                      isExpanded: true,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
                                      items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                      onChanged: (val) => setState(() => _selectedBank = val ?? _selectedBank),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Escopo do Cliente BPO
                      if (_bpoClients.isNotEmpty) ...[
                        const Text('Escopo do Cliente', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedClientScope,
                              dropdownColor: const Color(0xFF0F172A),
                              isExpanded: true,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
                              items: [
                                const DropdownMenuItem(value: 'global', child: Text('🌐 Global (todos os clientes)')),
                                ..._bpoClients.map((c) => DropdownMenuItem(
                                  value: c['id']?.toString() ?? 'global',
                                  child: Text('👤 ${c['name'] ?? c['id']}'),
                                )),
                              ],
                              onChanged: (val) => setState(() => _selectedClientScope = val ?? 'global'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Switch Autoconciliação
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Autoconciliar Instantaneamente',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Registra a transação no banco de dados local imediatamente sem pedir confirmação manual.',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: _autoApprove,
                            activeColor: AppTheme.primary,
                            activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
                            inactiveThumbColor: AppTheme.textMuted,
                            inactiveTrackColor: Colors.white10,
                            onChanged: (val) => setState(() => _autoApprove = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Botão Salvar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addRule,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'SALVAR REGRA',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'REGRAS ATIVAS',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 12),

                // Lista de Regras Existentes
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _db.getReconciliationRules(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                    }
                    final rules = snapshot.data ?? [];
                    if (rules.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.rule_folder_rounded, color: Colors.white.withValues(alpha: 0.15), size: 36),
                              const SizedBox(height: 12),
                              const Text('Nenhuma regra configurada ainda.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rules.length,
                      itemBuilder: (context, index) {
                        final rule = rules[index];
                        final String id = rule['id'] ?? '';
                        final String keyword = rule['keyword'] ?? '';
                        final String category = rule['category'] ?? 'Geral';
                        final bool autoApprove = rule['autoApprove'] ?? false;
                        final String bankFilter = rule['bankFilter'] ?? 'Todos';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.01),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          keyword,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            category,
                                            style: const TextStyle(color: AppTheme.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.account_balance_rounded, size: 10, color: AppTheme.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Banco: $bankFilter',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          autoApprove ? Icons.bolt_rounded : Icons.touch_app_rounded,
                                          size: 10,
                                          color: autoApprove ? AppTheme.income : Colors.amberAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          autoApprove ? 'Autoconciliar' : 'Confirmar manual',
                                          style: TextStyle(
                                            color: autoApprove ? AppTheme.income : Colors.amberAccent,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Scope badge
                                    Builder(builder: (context) {
                                      final scope = rule['clientScope']?.toString() ?? 'global';
                                      final isGlobal = scope == 'global';
                                      final scopeLabel = isGlobal
                                          ? 'Global'
                                          : (_bpoClients.firstWhere(
                                              (c) => c['id'] == scope,
                                              orElse: () => {'name': scope},
                                            )['name']?.toString() ?? scope);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isGlobal ? Icons.public_rounded : Icons.person_rounded,
                                              size: 10,
                                              color: isGlobal ? Colors.blueAccent : const Color(0xFF7C3AED),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Escopo: $scopeLabel',
                                              style: TextStyle(
                                                color: isGlobal ? Colors.blueAccent : const Color(0xFF7C3AED),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () async {
                                  await _db.deleteReconciliationRule(id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Regra removida! 🔄'))
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
