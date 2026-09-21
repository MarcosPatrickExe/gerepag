part of '../../transactions_provider.dart';

extension TransactionsProviderSync on TransactionsProvider {
  // 📡 Sincronização Principal com Omie
  Future<void> refreshOmieData({bool fullSync = true}) async {
    if (_isDemoMode) {
      print('🎮 [DEMO] Modo Demonstração ativo. Ignorando sincronização real.');
      return;
    }
    if (_omieAccounts.isEmpty && (_omieKey == null || _omieSecret == null)) {
      print('❌ [SYNC] Nenhuma conta configurada. Cancelando refresh.');
      return;
    }
    
    if (_isRefreshingOmie) {
      print('⚠️ [SYNC] Sincronização já em curso. Ignorando.');
      return;
    }

    _isLoading = true;
    _isRefreshingOmie = true;
    notify();

    try {
      if (_isConsolidatedMode) {
        await _performConsolidatedSync(fullSync);
      } else {
        await _performSingleAccountSync(fullSync);
      }
      _lastSyncTime = DateTime.now();
      await _saveCache(); // Persistir dados sincronizados no cache local
      WidgetService.updateBalance(totalBalance);
    } catch (e) {
      print('❌ [SYNC] Erro Crítico: $e');
    } finally {
      _isLoading = false;
      _isRefreshingOmie = false;
      notify();
    }
  }

  Future<void> _performSingleAccountSync(bool fullSync) async {
    if (_omieKey == null || _omieSecret == null) return;
    
    final accountId = _activeAccountId ?? 'default';
    updateAccountSyncStatus(accountId, 'Sincronizando');

    try {
      final omie = OmieService(appKey: _omieKey!, appSecret: _omieSecret!);
      
      _omieSummary = await omie.getFinancialSummary();
      if (_omieSummary != null) _realtimeService.saveOmieSummary(_omieSummary!);

      if (fullSync) {
        // Buscar CNPJ se não tiver
        if (activeAccount?.cnpj == null) {
          final cnpj = await omie.getCompanyCnpj();
          if (cnpj != null) {
            final idx = _omieAccounts.indexWhere((a) => a.id == accountId);
            if (idx != -1) {
              _omieAccounts[idx] = OmieAccount(
                id: _omieAccounts[idx].id,
                name: _omieAccounts[idx].name,
                appKey: _omieAccounts[idx].appKey,
                appSecret: _omieAccounts[idx].appSecret,
                cnpj: cnpj,
              );
              _saveAccountsToPrefs();
            }
          }
        }

        _omieCategories = await omie.listCategories();
        _omieClients = await omie.listClients();
        _omieProjects = await omie.listProjects();
        _omieDepartments = await omie.listDepartments();
        _omieUnits = await omie.listBusinessUnits();
        _omieOS = await omie.listServiceOrders();
        _omieOrders = await omie.listSalesOrders();
        _omieAccountsReceivable = await omie.listAccountsReceivable();
        _omieAccountsPayable = await omie.listAccountsPayable();
        
        print('📦 [SYNC] Dados Reais Recebidos:');
        print(' - Pedidos: ${_omieOrders.length}');
        print(' - Contas a Receber: ${_omieAccountsReceivable.length}');
        print(' - Contas a Pagar: ${_omieAccountsPayable.length}');
        print(' - OS: ${_omieOS.length}');
      }
      updateAccountSyncStatus(accountId, 'Sucesso', time: DateTime.now());
    } catch (e) {
      updateAccountSyncStatus(accountId, 'Erro');
      rethrow;
    }
  }

  Future<void> _performConsolidatedSync(bool fullSync) async {
    // Resetar acumuladores
    _omieAccountsReceivable = [];
    _omieAccountsPayable = [];
    _omieOS = [];
    _omieOrders = [];
    _accountMetrics = {};
    
    double totalBanco = 0;
    double totalReceber = 0;
    double totalPagar = 0;

    for (var acc in _omieAccounts) {
      updateAccountSyncStatus(acc.id, 'Sincronizando');
      final omie = OmieService(appKey: acc.appKey, appSecret: acc.appSecret);
      
      try {
        final summary = await omie.getFinancialSummary();
        double balance = 0;
        if (summary != null) {
          balance = double.tryParse(summary['contaCorrente']?['vTotal']?.toString() ?? '0') ?? 0;
          totalBanco += balance;
          totalReceber += double.tryParse(summary['contaReceber']?['vTotal']?.toString() ?? '0') ?? 0;
          totalPagar += double.tryParse(summary['contaPagar']?['vTotal']?.toString() ?? '0') ?? 0;
        }

        List<dynamic> accReceivables = [];
        List<dynamic> accPayables = [];

        if (fullSync) {
          // Buscar CNPJ se não tiver
          if (acc.cnpj == null) {
            final cnpj = await omie.getCompanyCnpj();
            if (cnpj != null) {
              final idx = _omieAccounts.indexWhere((a) => a.id == acc.id);
              if (idx != -1) {
                _omieAccounts[idx] = OmieAccount(
                  id: _omieAccounts[idx].id,
                  name: _omieAccounts[idx].name,
                  appKey: _omieAccounts[idx].appKey,
                  appSecret: _omieAccounts[idx].appSecret,
                  cnpj: cnpj,
                );
                _saveAccountsToPrefs();
              }
            }
          }

          accReceivables = await omie.listAccountsReceivable();
          accPayables = await omie.listAccountsPayable();

          _omieAccountsReceivable.addAll(accReceivables);
          _omieAccountsPayable.addAll(accPayables);
          _omieOS.addAll(await omie.listServiceOrders());
          _omieOrders.addAll(await omie.listSalesOrders());
          _omieCategories.addAll(await omie.listCategories());
          _omieClients.addAll(await omie.listClients());
          _omieProjects.addAll(await omie.listProjects());
          _omieDepartments.addAll(await omie.listDepartments());
          _omieUnits.addAll(await omie.listBusinessUnits());
        }

        final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
        final dueTodayCount = accReceivables.where((x) => x['data_vencimento'] == todayStr).length +
                              accPayables.where((x) => x['data_vencimento'] == todayStr).length;

        _accountMetrics[acc.id] = {
          'name': acc.name,
          'balance': balance,
          'dueTodayCount': dueTodayCount,
          'isRed': balance < 0,
          'lastSync': DateTime.now().toIso8601String(),
          'status': 'Sucesso',
        };

        updateAccountSyncStatus(acc.id, 'Sucesso', time: DateTime.now());
      } catch (e) {
        print('⚠️ Error syncing account ${acc.name}: $e');
        _accountMetrics[acc.id] = {
          'name': acc.name,
          'balance': 0.0,
          'dueTodayCount': 0,
          'isRed': false,
          'lastSync': DateTime.now().toIso8601String(),
          'status': 'Erro',
        };
        updateAccountSyncStatus(acc.id, 'Erro');
      }
    }

    // Criar resumo consolidado mockado
    _omieSummary = {
      "contaCorrente": {"vTotal": totalBanco},
      "contaReceber": {"vTotal": totalReceber},
      "contaPagar": {"vTotal": totalPagar},
    };
  }
}
