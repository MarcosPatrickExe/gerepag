import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../services/omie_service.dart';
import '../services/realtime_db_service.dart';
import '../services/anomaly_service.dart';
import '../services/widget_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:share_plus/share_plus.dart';
import '../models/omie_account.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../models/dre_node.dart';
import '../models/wallet_model.dart';
import '../models/credit_card_model.dart';


import 'dart:async';

// Motores de Inteligência Modularizados
part 'transactions_provider/parts/sync_core.dart';
part 'transactions_provider/parts/crm_engine.dart';
part 'transactions_provider/parts/forecasting_engine.dart';
part 'transactions_provider/parts/ops_finance.dart';
part 'transactions_provider/parts/bi_intelligence.dart';
part 'transactions_provider/parts/semester_flow.dart';
part 'transactions_provider/parts/sales_bi.dart';
part 'transactions_provider/parts/inventory_bi.dart';
part 'transactions_provider/parts/simulation_core.dart';
part 'transactions_provider/parts/check_panel.dart';

enum OmieFilterMode { daily, monthly, yearly, custom }

class TransactionsProvider with ChangeNotifier {
  final RealtimeDbService _realtimeService = RealtimeDbService();
  
  // --- ESTADO PRIVADO ---
  List<TransactionModel> _transactions = [];
  List<WalletModel> _wallets = [];
  List<CreditCardModel> _creditCards = [];
  StreamSubscription<List<TransactionModel>>? _transactionSub;
  StreamSubscription<List<WalletModel>>? _walletSub;
  StreamSubscription<List<CreditCardModel>>? _cardSub;
  bool _isLoading = false;
  bool _isPrivacyMode = false;
  bool _isBusinessMode = false;
  double _simulatedExpense = 0.0;
  String? _omieKey;
  String? _omieSecret;
  List<OmieAccount> _omieAccounts = [];
  String? _activeAccountId;
  Map<String, dynamic>? _omieSummary;
  Map<String, String> _omieCategories = {};
  Map<String, String> _omieClients = {};
  Map<String, String> _omieProjects = {};
  Map<String, String> _omieDepartments = {};
  Map<String, String> _omieUnits = {};
  bool _isUsingOmie = false;
  List<dynamic> _omieAccountsReceivable = [];
  List<dynamic> _omieAccountsPayable = [];
  List<dynamic> _omieOS = [];
  List<dynamic> _omieOrders = [];
  List<dynamic> _omieBankBalances = [];
  bool _isRefreshingOmie = false;
  Map<String, dynamic> _consolidatedSummary = {};
  List<Map<String, dynamic>> _billingHistory = [];
  StreamSubscription<List<Map<String, dynamic>>>? _billingSub;
  bool _isDemoMode = false;
  Map<String, Map<String, dynamic>> _accountMetrics = {};
  DateTime? _lastSyncTime;
  Map<String, DateTime?> _accountSyncTimes = {};
  Map<String, String> _accountSyncStatuses = {};
  bool _isConsolidatedMode = false;
  String _userName = 'Usuário';
  String? _clientLogo;
  String _userRole = 'user';
  String _userNiche = 'autonomo';
  
  static const String _syncCacheKey = 'omie_sync_cache_v1';

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheStr = prefs.getString(_getSyncCacheKey());
    if (cacheStr != null) {
      try {
        final cache = jsonDecode(cacheStr);
        _omieSummary = cache['summary'];
        _omieAccountsReceivable = cache['receivable'] ?? [];
        _omieAccountsPayable = cache['payable'] ?? [];
        _omieOS = cache['os'] ?? [];
        _omieOrders = cache['orders'] ?? [];
        _omieBankBalances = cache['bankBalances'] ?? [];
        _omieCategories = Map<String, String>.from(cache['categories'] ?? {});
        _omieClients = Map<String, String>.from(cache['clients'] ?? {});
        _omieProjects = Map<String, String>.from(cache['projects'] ?? {});
        _omieDepartments = Map<String, String>.from(cache['departments'] ?? {});
        _omieUnits = Map<String, String>.from(cache['units'] ?? {});
        
        final lastSyncStr = cache['lastSync'];
        if (lastSyncStr != null) _lastSyncTime = DateTime.parse(lastSyncStr);
        
        print('✅ [CACHE] Dados carregados com sucesso.');
        notifyListeners();
      } catch (e) {
        print('⚠️ [CACHE] Erro ao carregar cache: $e');
      }
    }
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = {
      'summary': _omieSummary,
      'receivable': _omieAccountsReceivable,
      'payable': _omieAccountsPayable,
      'os': _omieOS,
      'orders': _omieOrders,
      'bankBalances': _omieBankBalances,
      'categories': _omieCategories,
      'clients': _omieClients,
      'projects': _omieProjects,
      'departments': _omieDepartments,
      'units': _omieUnits,
      'lastSync': _lastSyncTime?.toIso8601String(),
    };
    await prefs.setString(_getSyncCacheKey(), jsonEncode(cache));
    print('💾 [CACHE] Dados salvos localmente.');
  }

  Future<void> updateOSStage(String osId, String newStageEtapa) async {
    for (var i = 0; i < _omieOS.length; i++) {
      var os = _omieOS[i];
      if (os is Map) {
        var cab = os['Cabecalho'] ?? os['cabecalho'];
        if (cab != null && cab['cNumOS']?.toString() == osId) {
          var newCab = Map<String, dynamic>.from(cab);
          newCab['cEtapa'] = newStageEtapa;
          var newOs = Map<String, dynamic>.from(os);
          if (newOs['Cabecalho'] != null) {
            newOs['Cabecalho'] = newCab;
          } else {
            newOs['cabecalho'] = newCab;
          }
          _omieOS[i] = newOs;
          break;
        }
      }
    }
    notifyListeners();
    await _saveCache();
  }
  
  DateTime? get lastSyncTime => _lastSyncTime;
  Map<String, DateTime?> get accountSyncTimes => _accountSyncTimes;
  Map<String, String> get accountSyncStatuses => _accountSyncStatuses;
  bool get isSyncing => _isRefreshingOmie;
  OmieFilterMode get omieFilterMode => _filterMode;

  void setOmieFilterMode(OmieFilterMode mode) {
    _filterMode = mode;
    _invalidateCache();
    notifyListeners();
  }

  DateTime? _selectedSpecificDate;
  String? _selectedCategoryId;
  String? _selectedClientId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _selectedProjectId;
  String? _selectedDepartmentId;
  String? _selectedUnitId;
  double _omieGoal = 0.0;
  
  String? get selectedProjectId => _selectedProjectId;
  String? get selectedDepartmentId => _selectedDepartmentId;
  String? get selectedUnitId => _selectedUnitId;
  String? get selectedCategoryId => _selectedCategoryId;

  void setProjectId(String? id) {
    if (_selectedProjectId == id) return;
    _selectedProjectId = id;
    _invalidateCache();
    notifyListeners();
  }

  void setDepartmentId(String? id) {
    if (_selectedDepartmentId == id) return;
    _selectedDepartmentId = id;
    _invalidateCache();
    notifyListeners();
  }

  void setUnitId(String? id) {
    if (_selectedUnitId == id) return;
    _selectedUnitId = id;
    _invalidateCache();
    notifyListeners();
  }

  void setCategoryId(String? id) {
    if (_selectedCategoryId == id) return;
    _selectedCategoryId = id;
    _invalidateCache();
    notifyListeners();
  }
  
  OmieFilterMode _filterMode = OmieFilterMode.monthly;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // 🚀 BI Performance Cache
  final Map<String, dynamic> _biCache = {};
  
  void _invalidateCache() {
    _biCache.clear();
  }

  // --- GETTERS DE ESTADO BÁSICO ---
  List<TransactionModel> get transactions {
    return _transactions.where((t) => _isWithinCurrentFilter(t.date)).toList();
  }
  
  List<WalletModel> get wallets => _wallets;
  List<CreditCardModel> get creditCards => _creditCards;
  
  OmieFilterMode get filterMode => _filterMode;
  DateTime? get rangeStart => _rangeStart;
  DateTime? get rangeEnd => _rangeEnd;
  bool get isLoading => _isLoading;
  bool get isPrivacyMode => _isPrivacyMode;
  bool get isBusinessMode => _isBusinessMode;
  Map<String, String> get omieCategories => _omieCategories;
  Map<String, String> get omieProjects => _omieProjects;
  Map<String, String> get omieDepartments => _omieDepartments;
  Map<String, String> get omieUnits => _omieUnits;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  DateTime? get selectedSpecificDate => _selectedSpecificDate;
  String? get omieKey => _omieKey;
  Map<String, String> get omieClients => _omieClients;
  List<dynamic> get omieOS => _omieOS;
  List<dynamic> get omieOrders => _omieOrders;
  double get simulatedExpense => _simulatedExpense;
  bool get isRefreshingOmie => _isRefreshingOmie;
  bool get isConsolidatedMode => _isConsolidatedMode;
  bool get isDemoMode => _isDemoMode;
  Map<String, Map<String, dynamic>> get accountMetrics => _accountMetrics;
  List<Map<String, dynamic>> get billingHistory => _billingHistory;
  double get omieGoal => _omieGoal;
  Map<String, dynamic>? get omieSummary => _omieSummary;
  List<dynamic> get omieAccountsReceivable => _omieAccountsReceivable;
  List<dynamic> get omieAccountsPayable => _omieAccountsPayable;
  String? get selectedClientId => _selectedClientId;
  List<OmieAccount> get omieAccounts => _omieAccounts;
  String? get activeAccountId => _activeAccountId;
  OmieAccount? get activeAccount => _omieAccounts.firstWhereOrNull((a) => a.id == _activeAccountId);
  String get userName => _userName;
  String? get clientLogo => _clientLogo;
  String get userRole => _userRole;
  String get userNiche => _userNiche;
  
  // --- ALIASES PARA COMPATIBILIDADE DE DASHBOARD ---
  Map<String, double> get omieGeoSales => incomeByStateRank;
  List<Map<String, dynamic>> get omieCashFlowForecast => omieDailyForecast;
  Map<String, double> get incomeByCategoryRank => incomeByCategoryRankBI;
  Map<String, double> get expenseByCategoryRank => expenseByCategoryRankBI;
  Map<String, double> get incomeByClientRank => incomeByClientRankBI;

  Set<String> get groupCnpjs {
    return _omieAccounts
        .map((a) => a.cnpj?.replaceAll(RegExp(r'[^0-9]'), '') ?? '')
        .where((c) => c.isNotEmpty)
        .toSet();
  }

  bool isIntercompany(dynamic x) {
    if (x == null) return false;
    // O CNPJ do cliente/fornecedor pode estar em vários campos dependendo do endpoint
    final cnpj = (x['cnpj_cpf'] ?? x['cCPFCNPJ'] ?? x['cnpj_cpf_receber'])?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (cnpj.isEmpty) return false;
    return groupCnpjs.contains(cnpj);
  }

  // --- MÉTODOS DE CONTROLE ---
  void togglePrivacyMode() {
    _isPrivacyMode = !_isPrivacyMode;
    SharedPreferences.getInstance().then((p) => p.setBool('privacy_mode', _isPrivacyMode));
    notifyListeners();
  }

  void setBusinessMode(bool enabled) {
    if (enabled && _omieAccounts.isEmpty) {
      _isBusinessMode = false;
      return;
    }
    _isBusinessMode = enabled;
    SharedPreferences.getInstance().then((p) => p.setBool(_getBusinessModeKey(), _isBusinessMode));
    notifyListeners();
  }

  void toggleBusinessMode([BuildContext? context]) {
    if (!_isBusinessMode && _omieAccounts.isEmpty) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Você não possui uma conta profissional (Omie) configurada.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }
    setBusinessMode(!_isBusinessMode);
  }

  Future<void> updateUserName(String name) async {
    _userName = name;
    await _realtimeService.updateUserProfile({'name': name});
    notifyListeners();
  }

  Future<void> updateClientLogo(String base64) async {
    _clientLogo = base64;
    await _realtimeService.saveClientLogo(base64);
    notifyListeners();
  }

  void toggleConsolidatedMode() {
    _isConsolidatedMode = !_isConsolidatedMode;
    if (_isConsolidatedMode) {
      refreshOmieData(fullSync: true); 
    }
    notifyListeners();
  }

  // --- MÉTODOS DE CONTROLE ---
  void setPeriod(int month, int year) {
    if (_selectedMonth == month && _selectedYear == year && _filterMode == OmieFilterMode.monthly) return;
    _filterMode = OmieFilterMode.monthly;
    _selectedMonth = month;
    _selectedYear = year;
    _selectedSpecificDate = null;
    _invalidateCache();
    notifyListeners();
  }

  void setSpecificDate(DateTime? date) {
    if (date != null) {
      if (_selectedSpecificDate == date && _filterMode == OmieFilterMode.daily) return;
      _filterMode = OmieFilterMode.daily;
      _selectedSpecificDate = date;
      _selectedMonth = date.month;
      _selectedYear = date.year;
      _invalidateCache();
    }
    notifyListeners();
  }

  void setYear(int year) {
    if (_selectedYear == year && _filterMode == OmieFilterMode.yearly) return;
    _filterMode = OmieFilterMode.yearly;
    _selectedYear = year;
    _selectedSpecificDate = null;
    _invalidateCache();
    notifyListeners();
  }

  void setCustomRange(DateTime start, DateTime end) {
    _filterMode = OmieFilterMode.custom;
    _rangeStart = start;
    _rangeEnd = end;
    _selectedSpecificDate = null;
    notifyListeners();
  }

  void filterByCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void filterByClient(String? clientId) {
    _selectedClientId = clientId;
    notifyListeners();
  }

  void updateAccountSyncStatus(String accountId, String status, {DateTime? time}) {
    _accountSyncStatuses[accountId] = status;
    if (time != null) _accountSyncTimes[accountId] = time;
    notifyListeners();
  }

  // --- GERENCIAMENTO DE MULTI-CONTAS ---
  
  Future<void> saveOmieAccount(String name, String key, String secret) async {
    final newAcc = OmieAccount(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      appKey: key,
      appSecret: secret,
    );
    
    _omieAccounts.add(newAcc);
    _activeAccountId = newAcc.id;
    _omieKey = key;
    _omieSecret = secret;
    
    await _saveAccountsToPrefs();
    await refreshOmieData(fullSync: true);
  }

  Future<void> saveBillingRecord({
    required String contactName,
    required double amount,
    required String dueDate,
    required String description,
    required String whatsappText,
    required String clientId,
  }) async {
    await _realtimeService.saveBillingRecord(
      contactName: contactName,
      amount: amount,
      dueDate: dueDate,
      description: description,
      whatsappText: whatsappText,
      clientId: clientId,
    );
  }

  Future<void> switchAccount(String id) async {
    final acc = _omieAccounts.firstWhereOrNull((a) => a.id == id);
    if (acc != null) {
      _activeAccountId = id;
      _omieKey = acc.appKey;
      _omieSecret = acc.appSecret;
      
      // Limpar dados antigos para evitar confusão visual durante o refresh
      _omieSummary = null;
      _omieAccountsReceivable = [];
      _omieAccountsPayable = [];
      
      await _saveAccountsToPrefs();
      await refreshOmieData(fullSync: true);
    }
  }

  Future<void> removeAccount(String id) async {
    _omieAccounts.removeWhere((a) => a.id == id);
    if (_activeAccountId == id) {
      if (_omieAccounts.isNotEmpty) {
        await switchAccount(_omieAccounts.first.id);
      } else {
        _activeAccountId = null;
        _omieKey = null;
        _omieSecret = null;
      }
    }
    await _saveAccountsToPrefs();
    notifyListeners();
  }

  Future<void> _saveAccountsToPrefs() async {
    final jsonList = _omieAccounts.map((a) => a.toMap()).toList();
    
    // 1. Salvar Local (Cache rápido)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getAccountsKey(), jsonEncode(jsonList));
    await prefs.setString(_getActiveAccountIdKey(), _activeAccountId ?? '');

    // 2. Salvar na Nuvem (Firebase) para Sincronização
    await _realtimeService.saveOmieAccounts(jsonList);
    if (_activeAccountId != null) {
      await _realtimeService.setActiveOmieAccountId(_activeAccountId!);
    }
  }

  bool isWithinCurrentFilterDetailed(dynamic x) {
    if (x == null) return false;
    
    // Eliminação Intercompany (Holding Mode)
    if (_isConsolidatedMode && isIntercompany(x)) {
      return false;
    }

    final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
    if (!_isWithinCurrentFilter(dt)) return false;
    return _applyGlobalFilters(x);
  }

  bool _applyGlobalFilters(dynamic x) {
    if (_selectedCategoryId != null) {
      final itemCat = (x['codigo_categoria'] ?? x['codigo_categoria_receber'] ?? x['cCodCategor'] ?? x['codigo_categoria_detalhe'])?.toString().trim();
      if (itemCat != _selectedCategoryId.toString().trim()) return false;
    }
    
    if (_selectedProjectId != null) {
      final itemProj = (x['codigo_projeto'] ?? x['nCodProj'] ?? x['codigo_projeto_receber'] ?? x['nCodProjSessao'])?.toString().trim();
      if (itemProj != _selectedProjectId.toString().trim()) return false;
    }

    if (_selectedDepartmentId != null) {
      final itemDept = (x['codigo_departamento'] ?? x['cCodDept'] ?? x['codigo_departamento_receber'])?.toString().trim();
      if (itemDept != _selectedDepartmentId.toString().trim()) return false;
    }

    if (_selectedUnitId != null) {
      final itemUnit = (x['codigo_unidade'] ?? x['cCodUnidade'] ?? x['codigo_unidade_receber'])?.toString().trim();
      if (itemUnit != _selectedUnitId.toString().trim()) return false;
    }

    if (_selectedClientId != null) {
      final itemClient = (x['codigo_cliente_fornecedor'] ?? x['nCodCliente'] ?? x['codigo_cliente'])?.toString().trim();
      if (itemClient != _selectedClientId.toString().trim()) return false;
    }
    return true;
  }

  bool _isWithinCurrentFilter(DateTime dt) {
    switch (_filterMode) {
      case OmieFilterMode.daily:
        return _selectedSpecificDate != null &&
               dt.day == _selectedSpecificDate!.day &&
               dt.month == _selectedSpecificDate!.month &&
               dt.year == _selectedSpecificDate!.year;
      case OmieFilterMode.monthly:
        return dt.month == _selectedMonth && dt.year == _selectedYear;
      case OmieFilterMode.yearly:
        return dt.year == _selectedYear;
      case OmieFilterMode.custom:
        if (_rangeStart == null || _rangeEnd == null) return false;
        // Normalizar para ignorar horas na comparação de range
        final dateOnly = DateTime(dt.year, dt.month, dt.day);
        final startOnly = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
        final endOnly = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day);
        return dateOnly.isAtSameMomentAs(startOnly) || 
               dateOnly.isAtSameMomentAs(endOnly) ||
               (dateOnly.isAfter(startOnly) && dateOnly.isBefore(endOnly));
    }
  }

  // --- GETTERS FINANCEIROS E BI ---
  
  double get totalBalance {
    double omieVal = double.tryParse(_omieSummary?['contaCorrente']?['vTotal']?.toString() ?? '0.0') ?? 0.0;
    
    double initialWalletsBalance = _wallets.fold(0.0, (sum, w) => sum + w.initialBalance);
    
    // Filtramos transações que NÃO são de cartão de crédito para o saldo bancário imediato
    double localVal = _transactions
        .where((t) => t.creditCardId == null) 
        .fold(0.0, (sum, t) => sum + (t.type == TransactionType.income ? t.amount : -t.amount));
        
    return omieVal + initialWalletsBalance + localVal;
  }

  double getWalletBalance(String walletId) {
    final wallet = _wallets.firstWhereOrNull((w) => w.id == walletId);
    if (wallet == null) return 0.0;
    
    double initial = wallet.initialBalance;
    double flow = _transactions.where((t) => t.accountId == walletId).fold(0.0, (sum, t) => sum + (t.type == TransactionType.income ? t.amount : -t.amount));
    
    return initial + flow;
  }

  double get currentBalance => _wallets.fold(0.0, (sum, w) => sum + getWalletBalance(w.id));
  double get totalReceivable => _omieAccountsReceivable.fold(0.0, (sum, x) => sum + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0));
  double get totalPayable => _omieAccountsPayable.fold(0.0, (sum, x) => sum + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0));
  List<dynamic> get omieRawReceivables => _omieAccountsReceivable;
  List<dynamic> get omieRawPayables => _omieAccountsPayable;
  List<dynamic> get omieOSList => _omieOS;
  List<dynamic> get omieOrdersList => _omieOrders;


  double get monthIncome {
    double omieSum = _sumByPeriod(_omieAccountsReceivable);
    double localSum = _transactions.where((t) => t.type == TransactionType.income && _isWithinCurrentFilter(t.date)).fold(0.0, (sum, t) => sum + t.amount);
    return omieSum + localSum;
  }


  double get monthExpense {
    double omieSum = _sumByPeriod(_omieAccountsPayable);
    double localSum = _transactions.where((t) => t.type == TransactionType.expense && _isWithinCurrentFilter(t.date)).fold(0.0, (sum, t) => sum + t.amount);
    return omieSum + localSum;
  }
  double get omieFlashCash => monthIncome - monthExpense;

  double get omieOverdue {
    final now = DateTime.now();
    double total = 0;
    for (var x in _omieAccountsReceivable) {
      if (x['status_titulo'] == 'PAGO') continue;
      final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
      if (dt.isBefore(now)) {
        total += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      }
    }
    return total;
  }

  double get omieBillsDueToday {
    final now = DateTime.now();
    double total = 0;
    for (var x in _omieAccountsPayable) {
      if (x['status_titulo'] == 'PAGO') continue;
      final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        total += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      }
    }
    return total;
  }

  double get omieRunway {
    final saldo = totalBalance;
    final despesaMedia = monthExpense;
    return despesaMedia <= 0 ? 99.0 : saldo / despesaMedia;
  }

  Map<String, double> get omieDRE => {'revenue': monthIncome, 'expenses': monthExpense, 'profit': monthIncome - monthExpense};

  Map<String, double> get omieMRRStats {
    double mrr = 0; double singles = 0;
    for (var item in _omieAccountsReceivable) {
      if (!_applyGlobalFilters(item)) continue;
      final val = double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0;
      if ((item['nCodCtr'] ?? 0) != 0) mrr += val; else singles += val;
    }
    return {'MRR': mrr, 'Singles': singles};
  }

  Map<String, double> get omieAgingData {
    final Map<String, double> aging = {'0-15': 0, '16-30': 0, '31-60': 0, '60+': 0};
    final now = DateTime.now();
    for (var item in _omieAccountsReceivable) {
      if (item['status_titulo'] == 'PAGO') continue;
      if (!_applyGlobalFilters(item)) continue;
      try {
        final dt = DateFormat('dd/MM/yyyy').parse(item['data_vencimento'] ?? item['dDtVenc']);
        if (dt.isBefore(now)) {
          final diff = now.difference(dt).inDays;
          final val = double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0;
          if (diff <= 15) aging['0-15'] = aging['0-15']! + val;
          else if (diff <= 30) aging['16-30'] = aging['16-30']! + val;
          else if (diff <= 60) aging['31-60'] = aging['31-60']! + val;
          else aging['60+'] = aging['60+']! + val;
        }
      } catch (_) {}
    }
    return aging;
  }

  List<Map<String, dynamic>> get omieTopClientsABC {
    final Map<String, double> clients = {};
    double totalRevenue = 0;
    
    for (var item in _omieAccountsReceivable) {
      final dt = _safeParseDate(item['data_vencimento'] ?? item['dDtVenc']);
      if (_isWithinCurrentFilter(dt)) {
        final val = double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0;
        final name = _omieClients[item['codigo_cliente_fornecedor'].toString()] ?? 'Cliente ${item['codigo_cliente_fornecedor']}';
        clients[name] = (clients[name] ?? 0) + val;
        totalRevenue += val;
      }
    }

    final sortedEntries = clients.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    double cumulative = 0;
    return sortedEntries.map((e) {
      cumulative += e.value;
      final percent = totalRevenue > 0 ? (e.value / totalRevenue) * 100 : 0.0;
      final cumPercent = totalRevenue > 0 ? (cumulative / totalRevenue) * 100 : 0.0;
      
      String abcClass = 'C';
      if (cumPercent <= 70) abcClass = 'A';
      else if (cumPercent <= 90) abcClass = 'B';
      
      return {
        'client': e.key,
        'value': e.value,
        'percent': percent,
        'class': abcClass,
      };
    }).toList();
  }

  // --- GETTERS DE BI AVANÇADO ---
  
  Map<String, double> get omieExpenseDonutData {
    final Map<String, double> cats = {};
    for (var x in _omieAccountsPayable) {
      if (!_applyGlobalFilters(x)) continue;
      final name = _omieCategories[x['codigo_categoria']] ?? 'Outros';
      cats[name] = (cats[name] ?? 0) + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
    }
    return cats;
  }

  double get omieTaxSummary {
    double total = 0;
    for (var os in _omieOS) {
      final val = double.tryParse((os['Cabecalho'] ?? os['cabecalho'] ?? {})['nValorTotalImpRet']?.toString() ?? '0') ?? 0;
      total += val;
    }
    return total;
  }

  Map<String, double> get omieProjectData {
    final Map<String, double> projects = {};
    for (var item in _omieAccountsPayable) {
      if (!_applyGlobalFilters(item)) continue;
      final dt = _safeParseDate(item['data_vencimento'] ?? item['dDtVenc']);
      if (_isWithinCurrentFilter(dt)) {
        final name = _omieProjects[item['codigo_projeto'].toString()] ?? 'Sem Projeto';
        projects[name] = (projects[name] ?? 0) + (double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0);
      }
    }
    return projects;
  }

  Map<int, Map<String, double>> get omieYearlyComparison {
    if (_biCache.containsKey('yearlyComparison')) return _biCache['yearlyComparison'];
    
    final Map<int, Map<String, double>> years = {};
    for (var item in _omieAccountsReceivable) {
      if (!_applyGlobalFilters(item)) continue;
      try {
        final dt = _safeParseDate(item['data_vencimento'] ?? item['dDtVenc']);
        if (!years.containsKey(dt.year)) years[dt.year] = {};
        
        final m = DateFormat('MMM').format(dt);
        years[dt.year]![m] = (years[dt.year]![m] ?? 0) + (double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0);
      } catch (_) {}
    }
    
    _biCache['yearlyComparison'] = years;
    return years;
  }

  String get omieBusinessAIContext => "Saldo: $totalBalance, Receita: $monthIncome, Despesa: $monthExpense";

  Map<String, int> get omieProductivityStats => {'OS': _omieOS.length, 'Pedidos': _omieOrders.length};

  List<dynamic> get omieUpcomingPayments => _omieAccountsPayable.where((x) => x['status_titulo'] != 'PAGO').toList();

  List<Map<String, dynamic>> get omieCashFlowProjection => omieForecasting;

  Map<int, double> get omieCashFlowHeatmap {
    final Map<int, double> heatmap = {};
    for (var item in _omieAccountsReceivable) {
      if (!_applyGlobalFilters(item)) continue;
      try {
        final dt = DateFormat('dd/MM/yyyy').parse(item['data_vencimento'] ?? item['dDtVenc']);
        if (dt.month == _selectedMonth && dt.year == _selectedYear) {
          heatmap[dt.day] = (heatmap[dt.day] ?? 0) + (double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0);
        }
      } catch (_) {}
    }
    return heatmap;
  }

  double get omieMonthlyFaturamentoTotal {
    double total = 0;
    for (var x in _omieAccountsReceivable) {
      final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
      if (_isWithinCurrentFilter(dt)) {
        total += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      }
    }
    return total;
  }

  double get omieSimulatedRunway => totalBalance / (monthExpense + _simulatedExpense);

  // --- CÁLCULOS DE BI AVANÇADO (ESTILO POWER BI) ---

  double get omieOperationalResult => monthIncome - monthExpense;

  double get omieEBITDA {
    // EBITDA = Resultado Operacional + Impostos + Juros + Depreciação
    // Como simplificação para o ERP, usamos Receita - Despesas Operacionais (excluindo impostos e financeiros)
    double operatingExpenses = 0;
    for (var x in _omieAccountsPayable) {
      if (!_applyGlobalFilters(x)) continue;
      final cat = _omieCategories[x['codigo_categoria']]?.toLowerCase() ?? '';
      // Excluir Impostos e Despesas Financeiras do EBITDA
      if (cat.contains('imposto') || cat.contains('taxa') || cat.contains('jura') || cat.contains('financi')) continue;
      operatingExpenses += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
    }
    return monthIncome - operatingExpenses;
  }

  double get omieEBITDAPercent => monthIncome > 0 ? (omieEBITDA / monthIncome) * 100 : 0.0;

  double get omieContributionMargin {
    // Margem de Contribuição = Receita - Custos Variáveis
    double variableCosts = 0;
    for (var x in _omieAccountsPayable) {
      if (!_applyGlobalFilters(x)) continue;
      final cat = _omieCategories[x['codigo_categoria']]?.toLowerCase() ?? '';
      // Exemplo: Custos de mercadorias, insumos, fretes
      if (cat.contains('mercadoria') || cat.contains('insumo') || cat.contains('frete') || cat.contains('comiss')) {
        variableCosts += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      }
    }
    return monthIncome - variableCosts;
  }

  double get omieNetMargin => monthIncome > 0 ? (omieOperationalResult / monthIncome) * 100 : 0.0;

  double get omieAvgPaymentTerm {
    double totalDays = 0;
    double totalAmount = 0;
    for (var x in _omieAccountsPayable) {
      try {
        final dtVenc = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
        final dtEmis = _safeParseDate(x['data_emissao'] ?? x['dDtEmis'] ?? x['data_registro'] ?? x['dDtReg']);
        final val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
        if (val > 0) {
          final days = dtVenc.difference(dtEmis).inDays.abs();
          totalDays += days * val;
          totalAmount += val;
        }
      } catch (_) {}
    }
    return totalAmount > 0 ? totalDays / totalAmount : 30.0;
  }

  double get omieAvgReceiptTerm {
    double totalDays = 0;
    double totalAmount = 0;
    for (var x in _omieAccountsReceivable) {
      try {
        final dtVenc = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
        final dtEmis = _safeParseDate(x['data_emissao'] ?? x['dDtEmis'] ?? x['data_registro'] ?? x['dDtReg']);
        final val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
        if (val > 0) {
          final days = dtVenc.difference(dtEmis).inDays.abs();
          totalDays += days * val;
          totalAmount += val;
        }
      } catch (_) {}
    }
    return totalAmount > 0 ? totalDays / totalAmount : 30.0;
  }

  List<Map<String, dynamic>> get omieMonthlyBarHistory {
    if (_biCache.containsKey('monthlyBarHistory')) return _biCache['monthlyBarHistory'];
    
    final Map<String, Map<String, double>> history = {};
    final now = DateTime.now();
    
    // Gerar dados para os últimos 12 meses
    for (int i = 0; i < 12; i++) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final label = DateFormat('MMM/yy').format(monthDate);
        history[label] = {'income': 0.0, 'expense': 0.0};
    }

    void processList(List<dynamic> list, String key) {
        for (var item in list) {
            try {
                final dt = _safeParseDate(item['data_vencimento'] ?? item['dDtVenc']);
                final label = DateFormat('MMM/yy').format(dt);
                if (history.containsKey(label)) {
                    history[label]![key] = (history[label]![key] ?? 0) + (double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0);
                }
            } catch (_) {}
        }
    }

    processList(_omieAccountsReceivable, 'income');
    processList(_omieAccountsPayable, 'expense');

    // Converter para lista ordenada por data (antigo -> novo)
    final sortedKeys = history.keys.toList().reversed.toList();
    final result = sortedKeys.map((k) => {
        'month': k,
        'income': history[k]!['income'],
        'expense': history[k]!['expense'],
        'net': history[k]!['income']! - history[k]!['expense']!,
    }).toList();

    _biCache['monthlyBarHistory'] = result;
    return result;
  }

  List<FlSpot> get omieBalanceHistorySpots {
    // Simulando uma linha de saldo baseada em fluxo diário (BI v8)
    final Map<int, double> dailyFlow = {};
    for (int i = 1; i <= 31; i++) dailyFlow[i] = 0.0;

    for (var x in _omieAccountsReceivable) {
        final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
        if (dt.month == _selectedMonth && dt.year == _selectedYear) {
            dailyFlow[dt.day] = (dailyFlow[dt.day] ?? 0) + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
        }
    }
    for (var x in _omieAccountsPayable) {
        final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
        if (dt.month == _selectedMonth && dt.year == _selectedYear) {
            dailyFlow[dt.day] = (dailyFlow[dt.day] ?? 0) - (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
        }
    }

    double currentBalance = totalBalance;
    List<FlSpot> spots = [];
    for (int i = 1; i <= 31; i++) {
        currentBalance += (dailyFlow[i] ?? 0);
        spots.add(FlSpot(i.toDouble(), currentBalance));
    }
    return spots;
  }

  Map<String, double> get omieRadarData {
    return {
      'volVendas': (monthIncome / 50000 * 100).clamp(0, 100),
      'qtdVendas': (_omieOrders.length / 20 * 100).clamp(0, 100),
      'qtdOS': (_omieOS.length / 30 * 100).clamp(0, 100),
      'retencao': 85.0, // KPI fixo de retenção (BI v8)
    };
  }

  Map<String, Map<String, dynamic>> get omieTeamPerformance {
    final Map<String, double> sales = {};
    for (var order in _omieOrders) {
      final name = order['cabecalho']?['cNomeVendedor'] ?? 'Outros';
      final val = double.tryParse(order['cabecalho']?['valor_total']?.toString() ?? '0') ?? 0;
      sales[name] = (sales[name] ?? 0) + val;
    }
    return {'sales': sales.map((k, v) => MapEntry(k, {'value': v}))};
  }

  Future<bool> payOmieBill(int nCodLanc, double amount) async {
    final omie = OmieService(appKey: _omieKey!, appSecret: _omieSecret!);
    final success = await omie.payBill(nCodLanc, amount);
    if (success) refreshOmieData(fullSync: true);
    return success;
  }

  StreamSubscription<User?>? _authSubscription;
  bool _isInitInProgress = false;

  void notify() {
    notifyListeners();
  }

  TransactionsProvider() {
    startAuthListener();
  }

  void startAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        print('🚪 [AUTH] Usuário deslogado. Limpando sessão...');
        await clearSession();
      } else {
        print('🔑 [AUTH] Usuário logado: ${user.email}. Inicializando dados...');
        if (!_isInitInProgress) {
          _isInitInProgress = true;
          try {
            await init();
          } finally {
            _isInitInProgress = false;
          }
        }
      }
    });
  }

  String _getSyncCacheKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null ? 'omie_sync_cache_v1_$uid' : 'omie_sync_cache_v1';
  }

  String _getAccountsKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null ? 'omie_accounts_v2_$uid' : 'omie_accounts_v2';
  }

  String _getActiveAccountIdKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null ? 'active_account_id_$uid' : 'active_account_id';
  }

  String _getUsingOmieKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null ? 'is_using_omie_$uid' : 'is_using_omie';
  }

  String _getBusinessModeKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null ? 'business_mode_$uid' : 'business_mode';
  }

  Future<void> clearSession() async {
    _transactions = [];
    _wallets = [];
    _creditCards = [];
    _omieAccounts = [];
    _activeAccountId = null;
    _omieSummary = null;
    _omieCategories = {};
    _omieClients = {};
    _omieProjects = {};
    _omieDepartments = {};
    _omieUnits = {};
    _isUsingOmie = false;
    _omieAccountsReceivable = [];
    _omieAccountsPayable = [];
    _omieOS = [];
    _omieOrders = [];
    _omieBankBalances = [];
    _isRefreshingOmie = false;
    _consolidatedSummary = {};
    _billingHistory = [];
    _accountMetrics = {};
    _lastSyncTime = null;
    _accountSyncTimes = {};
    _accountSyncStatuses = {};
    _isConsolidatedMode = false;
    _userName = 'Usuário';
    _clientLogo = null;
    _userRole = 'user';
    _userNiche = 'autonomo';
    _isBusinessMode = false;

    await _transactionSub?.cancel();
    _transactionSub = null;
    await _walletSub?.cancel();
    _walletSub = null;
    await _cardSub?.cancel();
    _cardSub = null;
    await _billingSub?.cancel();
    _billingSub = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getSyncCacheKey());
    await prefs.remove(_getAccountsKey());
    await prefs.remove(_getActiveAccountIdKey());
    await prefs.remove(_getBusinessModeKey());
    await prefs.remove(_getUsingOmieKey());
    
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPrivacyMode = prefs.getBool('privacy_mode') ?? false;
    
    // Buscar perfil para determinar o modo padrão (Pessoal vs Empresarial)
    final profile = await _realtimeService.getUserProfile();
    final String accountType = profile?['accountType'] ?? 'pessoal';
    _userNiche = profile?['niche'] ?? (accountType == 'empresarial' ? 'pme' : 'autonomo');
    
    // Se o usuário nunca escolheu manualmente o modo, seguimos o tipo da conta.
    final currentUser = Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;
    final String name = profile?['name'] ?? currentUser?.displayName?.split(' ').first ?? 'Usuário';
    _userName = name;
    _clientLogo = profile?['logo'];
    _userRole = profile?['role'] ?? 'user';
    
    // Se ele já escolheu, respeitamos a preferência salva localmente.
    _isBusinessMode = prefs.getBool(_getBusinessModeKey()) ?? (accountType == 'empresarial' || _userNiche == 'bpo' || _userNiche == 'pme');
    _isUsingOmie = prefs.getBool(_getUsingOmieKey()) ?? (accountType == 'empresarial' || _userNiche == 'bpo' || _userNiche == 'pme');

    // Resetar estado para nova carga (Importante para trocas de conta/auth)
    _omieAccounts = [];
    _activeAccountId = null;
    _omieKey = null;
    _omieSecret = null;

    print('🔍 [INIT] Iniciando TransactionsProvider Sync...');

    // 1. Tentar carregar do Firebase (Nuvem)
    List<Map<String, dynamic>> cloudAccountsRaw = await _realtimeService.getOmieAccounts();
    String? cloudActiveId = await _realtimeService.getActiveOmieAccountId();

    // 2. Tentar carregar do Local (Cache)
    final accountsJson = prefs.getString(_getAccountsKey());
    List<OmieAccount> localAccounts = [];
    if (accountsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(accountsJson);
        localAccounts = decoded.map((m) => OmieAccount.fromMap(m)).toList();
      } catch (e) { print('❌ [INIT] Erro ao carregar contas locais: $e'); }
    }

    // 3. Lógica de Sincronização e Migração
    if (cloudAccountsRaw.isNotEmpty) {
      // Prioridade para a Nuvem (Multi-Contas)
      _omieAccounts = cloudAccountsRaw.map((m) => OmieAccount.fromMap(m)).toList();
      _activeAccountId = cloudActiveId;
      print('☁️ [SYNC] ${_omieAccounts.length} conta(s) carregada(s) da Nuvem.');
    } else if (localAccounts.isNotEmpty) {
      // Migrar local para Nuvem
      _omieAccounts = localAccounts;
      _activeAccountId = prefs.getString(_getActiveAccountIdKey());
      await _saveAccountsToPrefs(); 
      print('⬆️ [SYNC] Contas locais migradas para a Nuvem.');
    } else {
      // 4. Verificação de Legado (Caso o usuário tenha chaves no formato antigo)
      print('🔍 [SYNC] Buscando credenciais legado no nó de compatibilidade...');
      // Note: O RealtimeDbService retorna um Stream. Buscamos o primeiro evento.
      final legacy = await _realtimeService.getOmieCredentials().first;
      if (legacy != null && legacy['key'] != null && legacy['secret'] != null) {
        print('🔧 [SYNC] Credenciais legado detectadas. Migrando...');
        final legacyAcc = OmieAccount(
          id: 'legacy_primary',
          name: 'Empresa Principal',
          appKey: legacy['key'],
          appSecret: legacy['secret'],
        );
        _omieAccounts = [legacyAcc];
        _activeAccountId = legacyAcc.id;
        await _saveAccountsToPrefs(); // Migra para o formato novo na Nuvem
        print('✅ [SYNC] Credenciais legado migradas com sucesso!');
      } else {
        print('⚠️ [SYNC] Nenhuma conta encontrada em Nuvem, Local ou Legado.');
      }
    }
    
    // Configurar conta ativa definitiva
    final active = _omieAccounts.firstWhereOrNull((a) => a.id == _activeAccountId) ?? _omieAccounts.firstOrNull;
    if (active != null) {
      _activeAccountId = active.id;
      _omieKey = active.appKey;
      _omieSecret = active.appSecret;
      _isUsingOmie = true; // Forçar ativação se houver conta válida
    }

    await _loadCache(); 
    
    _billingSub?.cancel();
    _billingSub = _realtimeService.getBillingHistory().listen((list) {
      _billingHistory = list;
      notifyListeners();
    });
    
    // Iniciar Sincronização em Nuvem em tempo real (Transações Locais)
    _transactionSub?.cancel();
    _transactionSub = _realtimeService.getTransactions().listen((list) {
      _transactions = list;
      notifyListeners();
      WidgetService.updateBalance(totalBalance);
    });

    _walletSub?.cancel();
    _walletSub = _realtimeService.getWallets().listen((list) {
      _wallets = list;
      notifyListeners();
      WidgetService.updateBalance(totalBalance);
    });

    _cardSub?.cancel();
    _cardSub = _realtimeService.getCreditCards().listen((list) {
      _creditCards = list;
      notifyListeners();
      WidgetService.updateBalance(totalBalance);
    });

    if (_isUsingOmie && _omieKey != null) {
      print('🚀 [SYNC] Iniciando refresh de dados Omie para conta ativa...');
      refreshOmieData();
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _transactionSub?.cancel();
    _walletSub?.cancel();
    _cardSub?.cancel();
    _billingSub?.cancel();
    super.dispose();
  }

  Future<void> setUsingOmie(bool val) async {
    _isUsingOmie = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_using_omie', val);
    if (val && _omieKey != null) refreshOmieData();
    notifyListeners();
  }

  // --- HELPERS INTERNOS ---
  double _sumByPeriod(List<dynamic> list) {
    double total = 0;
    for (var item in list) {
      if (isWithinCurrentFilterDetailed(item)) {
        total += double.tryParse(item['valor_documento']?.toString() ?? '0.0') ?? 0.0;
      }
    }
    return total;
  }

  DateTime _safeParseDate(dynamic input) {
    if (input == null) return DateTime(2000);
    try {
      if (input.toString().contains('/')) return DateFormat('dd/MM/yyyy').parse(input.toString());
      return DateTime.tryParse(input.toString()) ?? DateTime(2000);
    } catch (_) { return DateTime(2000); }
  }

  double _getCrmOpportunityDeltaForMonth(DateTime targetDate) {
    double totalCrmFuture = 0;

    // 1. Ordens de Serviço (OS)
    for (var os in _omieOS) {
      final cab = os['Cabecalho'] ?? os['cabecalho'] ?? {};
      final etapa = cab['cEtapa']?.toString() ?? '00';
      
      if (etapa == '60' || etapa == '50') continue;

      final dt = _safeParseDate(cab['dDtPrevisao'] ?? cab['dDtInc']);
      if (dt.month == targetDate.month && dt.year == targetDate.year) {
        final amount = double.tryParse(cab['vlrTotalOS']?.toString() ?? '0') ?? 0;
        
        double weight = 0.1;
        if (etapa == '00' || etapa == '02') weight = 0.3;
        else if (etapa == '10' || etapa == '15') weight = 0.6;
        else if (etapa == '20' || etapa == '30') weight = 0.85;

        totalCrmFuture += amount * weight;
      }
    }

    // 2. Pedidos de Venda
    for (var order in _omieOrders) {
      final cab = order['Cabecalho'] ?? order['cabecalho'] ?? {};
      final etapa = cab['etapa']?.toString() ?? '00';
      
      if (etapa == '60' || etapa == '50') continue;

      final dt = _safeParseDate(cab['dDtPrevisao'] ?? cab['data_previsao'] ?? cab['dDtInc']);
      if (dt.month == targetDate.month && dt.year == targetDate.year) {
        final amount = double.tryParse(cab['valor_total']?.toString() ?? '0') ?? 0;

        double weight = 0.1;
        if (etapa == '00') weight = 0.3;
        else if (etapa == '10') weight = 0.75;
        else if (etapa == '20') weight = 0.95;

        totalCrmFuture += amount * weight;
      }
    }

    return totalCrmFuture;
  }

  // --- MÉTRICAS PARA DASHBOARDS ESPECIALIZADOS (ESTILO POWER BI) ---

  double get avgIncomePerMonth => monthIncome; 
  double get avgExpensePerMonth => monthExpense;

  int get clientCount {
    final Set<String> uniqueClients = {};
    for (var x in _omieAccountsReceivable) {
      if (_isWithinCurrentFilter(_safeParseDate(x['data_vencimento'] ?? x['dDtVenc']))) {
        uniqueClients.add(x['codigo_cliente_fornecedor'].toString());
      }
    }
    return uniqueClients.length;
  }

  int get vendorCount {
    final Set<String> uniqueVendors = {};
    for (var x in _omieAccountsPayable) {
      if (_isWithinCurrentFilter(_safeParseDate(x['data_vencimento'] ?? x['dDtVenc']))) {
        uniqueVendors.add(x['codigo_cliente_fornecedor'].toString());
      }
    }
    return uniqueVendors.length;
  }

  double get avgIncomePerClient => clientCount > 0 ? monthIncome / clientCount : 0.0;
  double get avgExpensePerVendor => vendorCount > 0 ? monthExpense / vendorCount : 0.0;

  Map<String, double> get incomeByCategoryRankBI {
    final Map<String, double> rank = {};
    for (var x in _omieAccountsReceivable) {
      if (!isWithinCurrentFilterDetailed(x)) continue;
      final name = _omieCategories[x['codigo_categoria']] ?? 'Outros';
      rank[name] = (rank[name] ?? 0) + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
    }
    return Map.fromEntries(rank.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  Map<String, double> get expenseByCategoryRankBI {
    final Map<String, double> rank = {};
    for (var x in _omieAccountsPayable) {
      if (!isWithinCurrentFilterDetailed(x)) continue;
      final name = _omieCategories[x['codigo_categoria']] ?? 'Outros';
      rank[name] = (rank[name] ?? 0) + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
    }
    for (var t in _transactions) {
      if (t.type == TransactionType.expense && _isWithinCurrentFilter(t.date)) {
        final name = t.category;
        rank[name] = (rank[name] ?? 0) + t.amount;
      }
    }
    return Map.fromEntries(rank.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  Map<String, double> get incomeByClientRankBI {
    final Map<String, double> rank = {};
    for (var x in _omieAccountsReceivable) {
      if (!isWithinCurrentFilterDetailed(x)) continue;
      final name = _omieClients[x['codigo_cliente_fornecedor'].toString()] ?? 'Cliente ${x['codigo_cliente_fornecedor']}';
      rank[name] = (rank[name] ?? 0) + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
    }
    return Map.fromEntries(rank.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  Map<String, double> get expenseByVendorRank {
    final Map<String, double> rank = {};
    for (var x in _omieAccountsPayable) {
      if (!isWithinCurrentFilterDetailed(x)) continue;
      final name = _omieClients[x['codigo_cliente_fornecedor'].toString()] ?? 'Fornecedor ${x['codigo_cliente_fornecedor']}';
      rank[name] = (rank[name] ?? 0) + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
    }
    return Map.fromEntries(rank.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  List<Map<String, dynamic>> get incomeAndClientVolumeHistory {
    final List<Map<String, dynamic>> history = [];
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final label = DateFormat('MMM/yy').format(monthDate);
        double value = 0;
        Set<String> clients = {};
        for (var x in _omieAccountsReceivable) {
            final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
            if (dt.month == monthDate.month && dt.year == monthDate.year) {
                value += (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
                clients.add(x['codigo_cliente_fornecedor'].toString());
            }
        }
        history.add({'month': label, 'value': value, 'count': clients.length});
    }
    return history.reversed.toList();
  }

  List<Map<String, dynamic>> get expenseAndVendorVolumeHistory {
    final List<Map<String, dynamic>> history = [];
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final label = DateFormat('MMM/yy').format(monthDate);
        double value = 0;
        Set<String> vendors = {};
        for (var x in _omieAccountsPayable) {
            final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
            if (dt.month == monthDate.month && dt.year == monthDate.year) {
                value += (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
                vendors.add(x['codigo_cliente_fornecedor'].toString());
            }
        }
        history.add({'month': label, 'value': value, 'count': vendors.length});
    }
    return history.reversed.toList();
  }

  // --- DRE MATRICIAL E FLUXO MENSAL ---

  Map<String, Map<String, List<double>>> get omieDREMatrix {
    final Map<String, Map<String, List<double>>> matrix = {
      'Receita': {},
      'Despesa': {},
    };

    void process(List<dynamic> list, String type) {
      for (var item in list) {
        final dt = _safeParseDate(item['data_vencimento'] ?? item['dDtVenc']);
        if (dt.year != _selectedYear) continue;
        
        final catName = _omieCategories[item['codigo_categoria']] ?? 'Outros';
        if (!matrix[type]!.containsKey(catName)) {
          matrix[type]![catName] = List.filled(12, 0.0);
        }
        final val = double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0;
        matrix[type]![catName]![dt.month - 1] += val;
      }
    }

    process(_omieAccountsReceivable, 'Receita');
    process(_omieAccountsPayable, 'Despesa');
    return matrix;
  }

  List<double> get omieMonthlyNetProfit {
    final List<double> values = List.filled(12, 0.0);
    final matrix = omieDREMatrix;
    
    for (int m = 0; m < 12; m++) {
      double revenue = 0; double expense = 0;
      matrix['Receita']!.forEach((k, v) => revenue += v[m]);
      matrix['Despesa']!.forEach((k, v) => expense += v[m]);
      values[m] = revenue - expense;
    }
    return values;
  }

  List<double> get omieMonthlyBalanceEvolution {
    final List<double> evolution = List.filled(12, 0.0);
    final netMonthly = omieMonthlyNetProfit;
    double current = totalBalance; 
    
    for (int i = 0; i < 12; i++) {
        evolution[i] = current; 
    }
    return evolution;
  }
  DateTime parseOFXDate(String raw) {
    if (raw.length >= 8) {
      final year = int.parse(raw.substring(0, 4));
      final month = int.parse(raw.substring(4, 6));
      final day = int.parse(raw.substring(6, 8));
      return DateTime(year, month, day);
    }
    return DateTime.now();
  }

  // --- GETTERS OMIE ---
  List<Map<String, dynamic>> get omieBankBalances {
    if (_omieSummary == null) return [];
    final list = _omieSummary!['lista_contas_correntes'] ?? [];
    return List<Map<String, dynamic>>.from(list.map((x) => {
      'name': x['cDescricao'] ?? 'Conta Omie',
      'balance': double.tryParse(x['nSaldoAtual']?.toString() ?? '0') ?? 0,
    }));
  }

  Future<void> updateUserNiche(String niche) async {
    _userNiche = niche;
    await _realtimeService.updateUserProfile({'niche': niche});
    notifyListeners();
  }

  void toggleDemoMode() async {
    _isDemoMode = !_isDemoMode;
    if (_isDemoMode) {
      _injectDemoData();
    } else {
      await _loadCache();
    }
    notifyListeners();
  }

  void _injectDemoData() {
    _omieSummary = {
      "contaCorrente": {"vTotal": 142500.0},
      "contaReceber": {"vTotal": 85000.0},
      "contaPagar": {"vTotal": 31200.0}
    };
    
    _omieAccountsReceivable = [
      {
        "codigo_cliente_fornecedor": 101,
        "numero_documento": "REC-9823",
        "data_vencimento": DateFormat('dd/MM/yyyy').format(DateTime.now()),
        "valor_documento": 1250.00,
        "codigo_categoria": "1.01",
        "descricao": "Licenciamento de Software",
        "status_titulo": "A vencer"
      },
      {
        "codigo_cliente_fornecedor": 102,
        "numero_documento": "REC-9824",
        "data_vencimento": DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 2))),
        "valor_documento": 4800.00,
        "codigo_categoria": "1.01",
        "descricao": "Consultoria BPO Mensal",
        "status_titulo": "A vencer"
      },
      {
        "codigo_cliente_fornecedor": 103,
        "numero_documento": "REC-9825",
        "data_vencimento": DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 5))),
        "valor_documento": 3500.00,
        "codigo_categoria": "1.01",
        "descricao": "Hospedagem & Nuvem SaaS",
        "status_titulo": "A vencer"
      },
      {
        "codigo_cliente_fornecedor": 101,
        "numero_documento": "REC-9820",
        "data_vencimento": DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 30))),
        "valor_documento": 12500.00,
        "codigo_categoria": "1.01",
        "descricao": "Licenciamento ERP Corporativo",
        "status_titulo": "PAGO"
      },
      {
        "codigo_cliente_fornecedor": 104,
        "numero_documento": "REC-9830",
        "data_vencimento": DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 45))),
        "valor_documento": 8900.00,
        "codigo_categoria": "1.01",
        "descricao": "Implantação de Processos BPO",
        "status_titulo": "A vencer"
      },
      {
        "codigo_cliente_fornecedor": 105,
        "numero_documento": "REC-9831",
        "data_vencimento": DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 95))),
        "valor_documento": 15400.00,
        "codigo_categoria": "1.01",
        "descricao": "Desenvolvimento de Software Sob Medida",
        "status_titulo": "A vencer"
      }
    ];

    _omieAccountsPayable = [
      {
        "codigo_cliente_fornecedor": 201,
        "cNomeFornecedor": "Amazon Web Services Brasil",
        "numero_documento": "PAG-1022",
        "data_vencimento": DateFormat('dd/MM/yyyy').format(DateTime.now()),
        "valor_documento": 8500.00,
        "codigo_categoria": "2.01",
        "descricao": "AWS Cloud Hosting Infraestrutura",
        "status_titulo": "A vencer"
      },
      {
        "codigo_cliente_fornecedor": 202,
        "cNomeFornecedor": "Banco Bradesco S/A",
        "numero_documento": "PAG-1023",
        "data_vencimento": DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 5))),
        "valor_documento": 807600.66,
        "codigo_categoria": "2.02",
        "descricao": "Amortização de Empréstimo & Financiamento",
        "status_titulo": "A vencer"
      },
      {
        "codigo_cliente_fornecedor": 203,
        "cNomeFornecedor": "Receita Federal do Brasil (DARF)",
        "numero_documento": "PAG-1024",
        "data_vencimento": DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 1))),
        "valor_documento": 45000.00,
        "codigo_categoria": "2.03",
        "descricao": "Impostos Federais (IRPJ/CSLL/PIS/COFINS)",
        "status_titulo": "A vencer"
      },
      {
        "codigo_cliente_fornecedor": 204,
        "cNomeFornecedor": "Itaú Unibanco S/A",
        "numero_documento": "PAG-1025",
        "data_vencimento": DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 10))),
        "valor_documento": 18500.00,
        "codigo_categoria": "2.04",
        "descricao": "Tarifas Bancárias & Custódia",
        "status_titulo": "A vencer"
      }
    ];

    _omieOS = [
      {
        "Cabecalho": {
          "nCodOS": 101,
          "nCodCli": 101,
          "cEtapaDes": "Faturado",
          "vlrTotalOS": 45000.0,
          "cNomeVendedor": "Carlos Silva (Senior)",
          "dDtPrevisao": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        }
      },
      {
        "Cabecalho": {
          "nCodOS": 102,
          "nCodCli": 102,
          "cEtapaDes": "Negociação",
          "vlrTotalOS": 28000.0,
          "cNomeVendedor": "Ana Souza (Enterprise)",
          "dDtPrevisao": DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 4))),
        }
      },
      {
        "Cabecalho": {
          "nCodOS": 103,
          "nCodCli": 103,
          "cEtapaDes": "Proposta",
          "vlrTotalOS": 15000.0,
          "cNomeVendedor": "Carlos Silva (Senior)",
          "dDtPrevisao": DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 10))),
        }
      },
      {
        "Cabecalho": {
          "nCodOS": 104,
          "nCodCli": 104,
          "cEtapaDes": "Qualificação",
          "vlrTotalOS": 32000.0,
          "cNomeVendedor": "Marcos Lima (Mid-Market)",
          "dDtPrevisao": DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 15))),
        }
      }
    ];

    _omieOrders = [
      {
        "cabecalho": {
          "numero_pedido": "PED-501",
          "codigo_cliente_omie": 101,
          "cNomeVendedor": "Carlos Silva (Senior)",
          "valor_total": 52500.0,
          "etapa_des": "Faturado",
        },
        "det": [
          {
            "prod": {
              "descricao": "Serviço de Consultoria BPO Financeiro",
              "quantidade": 15,
              "valor_total": 52500.0,
            }
          }
        ]
      },
      {
        "cabecalho": {
          "numero_pedido": "PED-502",
          "codigo_cliente_omie": 102,
          "cNomeVendedor": "Ana Souza (Enterprise)",
          "valor_total": 24000.0,
          "etapa_des": "Proposta",
        },
        "det": [
          {
            "prod": {
              "descricao": "Licença Software ERP Cloud",
              "quantidade": 40,
              "valor_total": 24000.0,
            }
          }
        ]
      },
      {
        "cabecalho": {
          "numero_pedido": "PED-503",
          "codigo_cliente_omie": 103,
          "cNomeVendedor": "Marcos Lima (Mid-Market)",
          "valor_total": 12000.0,
          "etapa_des": "Negociação",
        },
        "det": [
          {
            "prod": {
              "descricao": "Treinamento de Equipes de Controladoria",
              "quantidade": 8,
              "valor_total": 12000.0,
            }
          }
        ]
      }
    ];

    _omieBankBalances = [
      {"banco": "Itaú Unibanco", "saldo": 145800.50},
      {"banco": "Bradesco PJ", "saldo": 92300.00},
      {"banco": "Banco Inter", "saldo": 34100.20},
    ];

    _omieCategories = {
      "1.01": "Vendas de Serviço",
      "2.01": "Infraestrutura TI",
      "2.02": "Operações & Empréstimos",
      "2.03": "Impostos & Tributos",
      "2.04": "Despesas Bancárias"
    };

    _omieClients = {
      "101": "TechSolutions Brasil Ltd",
      "102": "Grupo Varejo Global S/A",
      "103": "Indústria Metalúrgica Sul",
      "104": "Comércio de Alimentos Silva",
      "105": "Serviços Médicos Integrados",
      "201": "Amazon Web Services Brasil",
      "202": "Banco Bradesco S/A",
      "203": "Receita Federal do Brasil (DARF)",
      "204": "Itaú Unibanco S/A"
    };

    _omieProjects = {
      "proj1": "Projeto Implantação BPO 2026",
      "proj2": "Projeto Software Mobile Corporativo"
    };

    _omieDepartments = {
      "dep1": "Departamento Técnico & TI",
      "dep2": "Departamento Financeiro & Controladoria"
    };

    _omieUnits = {
      "unit1": "Matriz São Paulo",
      "unit2": "Filial Rio de Janeiro"
    };
  }

  void enableDemoOmieAccount() {
    _isBusinessMode = true;
    _userNiche = 'pme';
    _activeAccountId = 'demo-omie-account';
    
    if (_omieAccounts.every((acc) => acc.id != 'demo-omie-account')) {
      _omieAccounts.add(OmieAccount(
        id: 'demo-omie-account',
        name: 'Empresa Demo Omie (SaaS & BPO)',
        appKey: 'demo_key_omie',
        appSecret: 'demo_secret_omie',
      ));
    }
    
    _injectDemoData();
    _invalidateCache();
    notifyListeners();
  }

  void setUserNiche(String niche) {
    updateUserNiche(niche);
  }
}
