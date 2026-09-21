part of '../../transactions_provider.dart';

extension TransactionsProviderOps on TransactionsProvider {
  // 📝 Ações Financeiras
  Future<void> addTransaction(TransactionModel transaction) async {
    HapticFeedback.mediumImpact();
    await _realtimeService.addTransaction(transaction);
  }

  Future<void> payCreditCardInvoice(String cardId, String walletId, double amount) async {
    final transaction = TransactionModel(
      id: '',
      amount: amount,
      category: 'Pagamento de Cartão 💳',
      description: 'Liquidação de Fatura',
      date: DateTime.now(),
      type: TransactionType.expense,
      accountId: walletId,
    );
    await addTransaction(transaction);
    notify();
  }

  Future<void> adjustWalletBalance(String walletId, double newBalance) async {
    final currentBalance = getWalletBalance(walletId);
    final diff = newBalance - currentBalance;
    
    if (diff == 0) return;

    final transaction = TransactionModel(
      id: '',
      amount: diff.abs(),
      category: 'Ajuste de Saldo ⚙️',
      description: 'Ajuste manual de conciliação',
      date: DateTime.now(),
      type: diff > 0 ? TransactionType.income : TransactionType.expense,
      accountId: walletId,
    );
    await addTransaction(transaction);
    notify();
  }

  Future<void> deleteTransaction(String id) async {
    HapticFeedback.heavyImpact();
    await _realtimeService.deleteTransaction(id);
  }

  Future<void> transferBetweenWallets(String fromId, String toId, double amount, String description) async {
    final now = DateTime.now();
    final fromWallet = wallets.firstWhere((w) => w.id == fromId);
    final toWallet = wallets.firstWhere((w) => w.id == toId);

    // Transação de Saída (Origem)
    final expense = TransactionModel(
      id: '',
      amount: amount,
      category: 'Transferência 🔄',
      description: 'Transferência para ${toWallet.name}: $description',
      date: now,
      type: TransactionType.expense,
      accountId: fromId,
    );
    
    // Transação de Entrada (Destino)
    final income = TransactionModel(
      id: '',
      amount: amount,
      category: 'Transferência 🔄',
      description: 'Transferência de ${fromWallet.name}: $description',
      date: now,
      type: TransactionType.income,
      accountId: toId,
    );
    
    await addTransaction(expense);
    await addTransaction(income);
    notify();
  }


  void updateSimulation(double val) {
    _simulatedExpense = val;
    notify();
  }

  Future<void> setOmieGoal(double val) async {
    _omieGoal = val;
    await _realtimeService.saveOmieGoal(val);
    notify();
  }

  Future<void> saveOmieCredentials(String key, String secret) async {
    _omieKey = key;
    _omieSecret = secret;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('omie_key', key);
    await prefs.setString('omie_secret', secret);
    await _realtimeService.saveOmieCredentials(key, secret);
    refreshOmieData();
  }

  Future<bool> createOmieReceivable({
    required int clientCode,
    required String dueDate,
    required double amount,
    required String categoryCode,
    required String description,
  }) async {
    if (_omieKey == null || _omieSecret == null) return false;
    final omie = OmieService(appKey: _omieKey!, appSecret: _omieSecret!);
    _isLoading = true;
    notify();
    try {
      final success = await omie.addAccountReceivable(
        clientCode: clientCode,
        dueDate: dueDate,
        amount: amount,
        categoryCode: categoryCode,
        description: description,
      );
      if (success) {
        await refreshOmieData(fullSync: true);
      }
      return success;
    } catch (e) {
      print('❌ [OMIE] Erro ao criar conta a receber: $e');
      return false;
    } finally {
      _isLoading = false;
      notify();
    }
  }

  // 🚨 Detecção de Anomalias (Restaurado com Tipagem Correta)
  AnomalyResult checkAnomaly(TransactionModel t) {
    return AnomalyService.check(t, _transactions);
  }

  // 🧬 Mapeamento de Getters Específicos para a UI
  
  Map<String, double> get categoricalExpenses {
    final Map<String, double> cats = {};
    
    // Processar Omie
    for (var x in _omieAccountsPayable) {
      final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
      if (_isWithinCurrentFilter(dt)) {
        if (_selectedCategoryId != null && x['codigo_categoria'] != _selectedCategoryId) continue;
        final name = omieCategories[x['codigo_categoria']] ?? 'Outros';
        cats[name] = (cats[name] ?? 0) + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
      }
    }

    // Processar Local
    for (var t in _transactions) {
      if (t.type == TransactionType.expense && _isWithinCurrentFilter(t.date)) {
        final name = t.category;
        cats[name] = (cats[name] ?? 0) + t.amount;
      }
    }

    return cats;
  }

  // --- NOVOS GETTERS DE BI AVANÇADO ---

  double get omieSalariesCLT {
    return _sumByCategoryKeywords(['salário', 'clt', 'inss', 'fgts', 'férias', '13º', 'décimo', 'rescisão']);
  }

  double get omieSalariesPJ {
    return _sumByCategoryKeywords(['honorários', 'pj', 'mei', 'prestação de serviços', 'pro-labore', 'pró-labore']);
  }

  double get omieBankFees {
    return _sumByCategoryKeywords(['tarifa', 'taxa bancária', 'manutenção', 'ted', 'doc', 'pix taxa', 'anuidade', 'juros sub']);
  }

  double get omieTotalTaxes {
    double total = omieTaxSummary; // Já pega retidos de OS
    total += _sumByCategoryKeywords(['darf', 'das ', 'gps ', 'imposto', 'irrf', 'pis', 'cofins', 'csll', 'iss', 'icms', 'iptu', 'ipva']);
    return total;
  }

  List<dynamic> get omieFilteredTransactions {
    final List<dynamic> omieParts = [..._omieAccountsReceivable, ..._omieAccountsPayable];
    final List<dynamic> localParts = _transactions.map((t) => {
      'data_vencimento': t.date.toIso8601String(),
      'descricao': t.description,
      'valor_documento': t.amount,
      'codigo_categoria': t.category,
      'type': t.type == TransactionType.income ? 'RECEBER' : 'PAGAR',
      'is_local': true,
    }).toList();

    final List<dynamic> all = [...omieParts, ...localParts];
    return all.where((x) {
      final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
      if (!_isWithinCurrentFilter(dt)) return false;
      if (_selectedCategoryId != null && x['codigo_categoria'] != _selectedCategoryId) return false;
      return true;
    }).toList()..sort((a, b) => _safeParseDate(b['data_vencimento'] ?? b['dDtVenc']).compareTo(_safeParseDate(a['data_vencimento'] ?? a['dDtVenc'])));
  }

  double _sumByCategoryKeywords(List<String> keywords) {
    double total = 0;
    for (var x in _omieAccountsPayable) {
      final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
      if (_isWithinCurrentFilter(dt)) {
        final catName = (omieCategories[x['codigo_categoria']] ?? '').toLowerCase();
        final obs = (x['observacao'] ?? '').toLowerCase();
        
        bool match = keywords.any((k) => catName.contains(k.toLowerCase()) || obs.contains(k.toLowerCase()));
        if (match) {
          total += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
        }
      }
    }
    return total;
  }

  List<MapEntry<DateTime, double>> get dailyBalanceHistory {
    final Map<DateTime, double> history = {};
    
    // Processar Omie
    for (var x in _omieAccountsReceivable) {
      if (!_applyGlobalFilters(x)) continue;
      final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
      if (_isWithinCurrentFilter(dt)) {
        final key = _filterMode == OmieFilterMode.yearly ? DateTime(dt.year, dt.month, 1) : dt;
        history[key] = (history[key] ?? 0) + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
      }
    }

    // Processar Local (Entradas)
    for (var t in _transactions) {
      if (t.type == TransactionType.income && _isWithinCurrentFilter(t.date)) {
        final key = _filterMode == OmieFilterMode.yearly ? DateTime(t.date.year, t.date.month, 1) : t.date;
        history[key] = (history[key] ?? 0) + t.amount;
      }
    }

    return history.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  // --- MOTOR DE KANBAN DE OS ---
  
  Map<String, List<dynamic>> get omieOSByStage {
    final Map<String, List<dynamic>> stages = {
      'Backlog': [],
      'Em Produção': [],
      'Revisão': [],
      'Concluído': [],
    };

    for (var os in _omieOS) {
      final cab = os['Cabecalho'] ?? os['cabecalho'] ?? {};
      
      // 1. Filtrar pelo período ativo (mensal, anual, customizado, etc)
      final dt = _safeParseDate(cab['dDtPrevisao'] ?? cab['dDtInc'] ?? cab['dDtAlt']);
      if (!_isWithinCurrentFilter(dt)) continue;

      // 2. Filtrar por cliente
      if (_selectedClientId != null) {
        final itemClient = cab['nCodCli']?.toString().trim();
        if (itemClient != _selectedClientId.toString().trim()) continue;
      }

      // 3. Filtrar por projeto
      if (_selectedProjectId != null) {
        final itemProj = cab['nCodProj']?.toString().trim();
        if (itemProj != _selectedProjectId.toString().trim()) continue;
      }

      // 4. Filtrar por departamento
      if (_selectedDepartmentId != null) {
        final itemDept = cab['cCodDept']?.toString().trim();
        if (itemDept != _selectedDepartmentId.toString().trim()) continue;
      }

      final etapa = cab['cEtapa']?.toString() ?? '00';
      
      if (etapa == '00' || etapa == '02') {
        stages['Backlog']!.add(os);
      } else if (etapa == '10' || etapa == '15') {
        stages['Em Produção']!.add(os);
      } else if (etapa == '20' || etapa == '30') {
        stages['Revisão']!.add(os);
      } else if (etapa == '50' || etapa == '60') {
        stages['Concluído']!.add(os);
      } else {
        stages['Backlog']!.add(os); // Fallback
      }
    }
    return stages;
  }

  String get executiveSummary {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    if (!isBusinessMode) {
      final sortedCats = categoricalExpenses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCatsStr = sortedCats.take(5).map((e) => '• ${e.key}: ${currency.format(e.value)}').join('\n');

      return """
📊 *RESUMO FINANCEIRO - $now*

💰 *SALDO ATUAL:* ${currency.format(totalBalance)}

📉 *GASTOS POR CATEGORIA (Top 5):*
${topCatsStr.isEmpty ? 'Nenhum gasto registrado' : topCatsStr}

_Gerado pelo App Financerio_
""";
    }

    return """
🚀 *RESUMO EXECUTIVO - $now*

📈 *DESEMPENHO:*
• Saldo Atual: ${currency.format(totalBalance)}
• Impostos: ${currency.format(omieTotalTaxes)}
• Tarifas: ${currency.format(omieBankFees)}
• CLT: ${currency.format(omieSalariesCLT)} | PJ: ${currency.format(omieSalariesPJ)}
• Runway: ${omieRunway.toStringAsFixed(1)} meses

⚠️ *ALERTA:*
• OS Abertas: ${_omieOS.length}
• Pedidos: ${_omieOrders.length}

_Gerado por Inteligência Omie v8_
""";
  }
}
