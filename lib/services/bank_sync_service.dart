import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ocr_service.dart';
import 'anomaly_service.dart';
import '../models/transaction_model.dart';
import '../services/realtime_db_service.dart';
import '../services/omie_service.dart';
import '../screens/bank_sync_inbox_screen.dart';

@pragma('vm:entry-point')
class BankSyncService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final OcrService _ocrService = OcrService();
  static final RealtimeDbService _db = RealtimeDbService();

  static bool _listening = false;
  static bool _localNotificationsInitialized = false;

  // NavigatorKey estático para navegação direta ao clicar na notificação
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const List<String> _bankPackages = [
    'com.nu.production',             // Nubank
    'br.com.inter',                  // Inter
    'br.com.next',                   // Next
    'br.com.bb.android',             // Banco do Brasil
    'com.itau',                      // Itaú
    'br.com.itau.pers',              // Itaú Personnalité
    'com.bradesco',                  // Bradesco
    'br.com.bradesco.netemp',        // Bradesco Net Empresa
    'br.com.santander.teller',       // Santander
    'com.c6bank.app',                // C6 Bank
    'br.com.caixa.mobi',             // Caixa
    'com.mercadopago.wallet',        // Mercado Pago
    'br.com.uol.ps.phone',           // PagBank
    'com.picpay',                    // PicPay
  ];

  @pragma('vm:entry-point')
  static void onNotificationCallback(NotificationEvent evt) async {
    print('🚨 [CALLBACK] Received native event - Package: ${evt.packageName}');
    debugPrint("🚨 [GEREPAG BACKGROUND] Recebeu evento nativo -> Pacote: ${evt.packageName}");
    await _ensureInitialized();
    final send = IsolateNameServer.lookupPortByName("bank_sync_listener_port");
    if (send != null) {
      send.send(evt);
    } else {
      // Processamento direto caso a UI esteja fechada/suspensa
      _processBankNotification(evt);
    }
  }

  static Future<void> _ensureInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    if (!_localNotificationsInitialized) {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/gerepag_logo');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      
      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationAction(response);
        },
      );
      _localNotificationsInitialized = true;
    }
  }

  static Future<void> init() async {
    if (kIsWeb) return;
    
    await _ensureInitialized();

    bool isPermissionGranted = await NotificationsListener.hasPermission ?? false;
    if (!isPermissionGranted) return;

    if (_listening) return; // Evita escutar a porta de notificações múltiplas vezes
    _listening = true;

    // Inicializa o Listener registrando o callback estático de background
    await NotificationsListener.initialize(callbackHandle: onNotificationCallback);

    // Criar e registrar nossa porta para o Isolate de Background se comunicar com a UI
    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping("bank_sync_listener_port");
    IsolateNameServer.registerPortWithName(port.sendPort, "bank_sync_listener_port");
    
    try {
      port.listen((evt) {
        if (evt is NotificationEvent) {
          print('⚡ [PORT LISTENER] Event received from background isolate: ${evt.packageName}');
          debugPrint('⚡ [GEREPAG UI] Evento recebido do Background Isolate -> Pacote: ${evt.packageName} | Título: ${evt.title} | Texto: ${evt.text}');
          if (_bankPackages.contains(evt.packageName)) {
            _processBankNotification(evt);
          } else {
            debugPrint('⚠️ [GEREPAG UI] Pacote ${evt.packageName} não está na lista de bancos.');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) print("Erro ao escutar porta de notificações do Isolate: $e");
    }

    // Ouvir também o ReceivePort padrão do plugin (para eventos via MethodChannel na UI thread)
    try {
      NotificationsListener.receivePort?.listen((evt) {
        if (evt is NotificationEvent) {
          print('⚡ [RECEIVEPORT LISTENER] Event received via plugin ReceivePort: ${evt.packageName}');
          debugPrint("⚡ [GEREPAG UI] Evento recebido via ReceivePort padrão -> Pacote: ${evt.packageName} | Título: ${evt.title} | Texto: ${evt.text}");
          if (_bankPackages.contains(evt.packageName)) {
            _processBankNotification(evt);
          } else {
            debugPrint("⚠️ [GEREPAG UI] Pacote ${evt.packageName} não está na lista de bancos.");
          }
        }
      });
      debugPrint("🔔 [GEREPAG UI] Ouvinte de notificações ativado com sucesso!");
    } catch (e) {
      if (kDebugMode) print("Erro ao escutar receivePort padrão: $e");
    }

    try {
      await NotificationsListener.startService(
        title: "GerePag Ativo ⚡",
        description: "Toque para abrir a Central de Conciliação Bancária",
      );
    } catch (e) {
      if (kDebugMode) print("Erro ao iniciar serviço de notificações: $e");
    }
  }

  static String _generateUniqueKey(NotificationEvent event) {
    return '${event.packageName}_${event.id ?? ''}_${event.title ?? ''}_${event.text ?? ''}_${event.timestamp ?? ''}';
  }

  static Future<bool> _isDuplicate(String uniqueKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history = prefs.getStringList('processed_notifications') ?? [];
      
      if (history.contains(uniqueKey)) {
        return true;
      }
      
      // Registrar no histórico e limitar a 50 itens
      history.add(uniqueKey);
      if (history.length > 50) {
        history.removeAt(0);
      }
      await prefs.setStringList('processed_notifications', history);
      return false;
    } catch (e) {
      if (kDebugMode) print('Erro ao verificar notificação duplicada: $e');
      return false;
    }
  }

  // 🩺 Mapeamento Inteligente por Histórico
  static Future<String?> _suggestCategoryByHistory(String participant, bool isIncome) async {
    try {
      final List<TransactionModel> transactions = await _db.getTransactionsOnce();
      final String query = participant.toLowerCase();
      if (query.isEmpty) return null;

      final Map<String, int> categoryCounts = {};
      
      for (var tx in transactions) {
        if (tx.type == (isIncome ? TransactionType.income : TransactionType.expense)) {
          if (tx.description.toLowerCase().contains(query) || query.contains(tx.description.toLowerCase())) {
            categoryCounts[tx.category] = (categoryCounts[tx.category] ?? 0) + 1;
          }
        }
      }
      
      if (categoryCounts.isEmpty) return null;
      
      String? bestCategory;
      int maxCount = -1;
      categoryCounts.forEach((cat, count) {
        if (count > maxCount) {
          maxCount = count;
          bestCategory = cat;
        }
      });
      
      return bestCategory;
    } catch (e) {
      if (kDebugMode) print('Erro ao sugerir categoria pelo histórico: $e');
      return null;
    }
  }

  // 🤝 Conciliação Inteligente com Títulos do Omie
  static Future<Map<String, dynamic>?> _findMatchingTitle(OcrResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final key = uid != null ? 'omie_sync_cache_v1_$uid' : 'omie_sync_cache_v1';
      final cacheStr = prefs.getString(key);
      if (cacheStr == null) return null;

      final cache = jsonDecode(cacheStr);
      final List<dynamic> receivables = cache['receivable'] ?? [];
      final Map<String, dynamic> clients = Map<String, dynamic>.from(cache['clients'] ?? {});

      final double targetAmount = result.amount ?? 0.0;
      if (targetAmount <= 0) return null;

      final String targetName = result.restaurant?.toLowerCase() ?? '';

      // 1. Tentar match exato por nome + valor
      for (var item in receivables) {
        if (item['status_titulo'] == 'PAGO') continue;

        final double docVal = double.tryParse(item['valor_documento']?.toString() ?? '') ?? 0.0;
        if ((docVal - targetAmount).abs() > 0.05) continue;

        if (targetName.isNotEmpty) {
          final String clientName = clients[item['codigo_cliente_fornecedor']?.toString()]?.toString().toLowerCase() ?? '';
          if (clientName.contains(targetName) || targetName.contains(clientName)) {
            return {
              'item': item,
              'clientName': clients[item['codigo_cliente_fornecedor']?.toString()] ?? 'Cliente',
            };
          }
        }
      }

      // 2. Se não encontrou por nome, mas tem apenas 1 título pendente com o valor exato, faz o match
      final List<dynamic> valueMatches = [];
      for (var item in receivables) {
        if (item['status_titulo'] == 'PAGO') continue;
        final double docVal = double.tryParse(item['valor_documento']?.toString() ?? '') ?? 0.0;
        if ((docVal - targetAmount).abs() < 0.05) {
          valueMatches.add(item);
        }
      }

      if (valueMatches.length == 1) {
        final item = valueMatches.first;
        return {
          'item': item,
          'clientName': clients[item['codigo_cliente_fornecedor']?.toString()] ?? 'Cliente',
        };
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao conciliar título: $e');
    }
    return null;
  }

  static String _getFriendlyAppName(String packageName) {
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

  static void _processBankNotification(NotificationEvent event) async {
    print('🏦 [GEREPAG NOTIFICAÇÃO] Starting processing for bank: ${event.packageName}');
    final String uniqueKey = _generateUniqueKey(event);
    print('🔑 [DEBUG] UniqueKey generated: $uniqueKey');
    debugPrint("🔑 [DEBUG] UniqueKey generated: $uniqueKey");
    if (await _isDuplicate(uniqueKey)) {
      print('🔁 [DEBUG] Duplicate notification detected for key: $uniqueKey');
      debugPrint("🔁 [DEBUG] Duplicate notification detected for key: $uniqueKey");
      debugPrint("♻️ [GEREPAG NOTIFICAÇÃO] Notificação duplicada ignorada (UniqueKey: $uniqueKey).");
      return;
    }

    final String text = '${event.title} ${event.text}';
    print('📝 [DEBUG] Combined notification text: $text');
    debugPrint("📝 [DEBUG] Combined notification text: $text");
    debugPrint("📝 [GEREPAG NOTIFICAÇÃO] Conteúdo textual completo: \"$text\"");
    
    // 1. Tentar parser Regex (mais rápido)
    var result = _ocrService.parseNotification(text);
    print('🔍 [GEREPAG NOTIFICAÇÃO] OCR Regex result -> Valor: R\$ ${result.amount} | Local: ${result.restaurant} | Entrada: ${result.isIncome}');
    debugPrint("🧪 [DEBUG] OCR result amount: ${result.amount}, restaurant: ${result.restaurant}, isIncome: ${result.isIncome}");

    // 2. Fallback Inteligente: Se o Regex não encontrou valor, aciona a IA do Glauber (Gemini)
    if (result.amount == null || result.amount! <= 0) {
      debugPrint("🤖 [GEREPAG NOTIFICAÇÃO] Regex falhou ou valor nulo. Acionando IA do Glauber para análise...");
      final aiResult = await _ocrService.parseNotificationWithAi(text);
      if (aiResult != null && aiResult.amount != null && aiResult.amount! > 0) {
        result = aiResult;
        print('🤖 [GEREPAG NOTIFICAÇÃO] IA result -> Valor: R\$ ${result.amount} | Local: ${result.restaurant} | Entrada: ${result.isIncome}');
        debugPrint("🧠 [DEBUG] AI result amount: ${result.amount}, restaurant: ${result.restaurant}, isIncome: ${result.isIncome}");
      }
    }

    if (result.amount != null && result.amount! > 0) {
      // 1. Carregar histórico e regras do Realtime DB
      await _db.init();
      final List<TransactionModel> history = await _db.getTransactionsOnce();
      final List<Map<String, dynamic>> rules = await _db.getReconciliationRulesOnce();

      String? finalCategory;
      bool ruleAutoApprove = false;
      String? ruleMatched;

      // 2. Motor de Regras: Verificar se o texto, título ou restaurante parseado bate com alguma palavra-chave
      final String lowerText = text.toLowerCase();
      final String lowerTitle = (event.title ?? '').toLowerCase();
      final String lowerRestaurant = (result.restaurant ?? '').toLowerCase();

      // Determinar o UID ativo: cliente BPO ou o próprio usuário
      final String? activeClientUid = RealtimeDbService.bpoActiveClientUid;

      for (var rule in rules) {
        final String kw = (rule['keyword'] ?? '').toString().toLowerCase();
        if (kw.isEmpty) continue;

        // --- Filtro de Escopo: global sempre passa; escopo de cliente filtra pelo UID ativo ---
        final String ruleScope = (rule['clientScope'] ?? 'global').toString();
        if (ruleScope != 'global') {
          // Regra específica de cliente — só aplica se este cliente estiver ativo
          if (activeClientUid == null || activeClientUid != ruleScope) continue;
        }

        bool termMatches = lowerText.contains(kw) || lowerTitle.contains(kw) || lowerRestaurant.contains(kw);

        bool bankMatches = true;
        if (rule['bankFilter'] != null && rule['bankFilter'].toString().isNotEmpty && rule['bankFilter'] != 'Todos') {
          final String friendlyName = _getFriendlyAppName(event.packageName ?? '').toLowerCase();
          final String filterVal = rule['bankFilter'].toString().toLowerCase();
          bankMatches = friendlyName.contains(filterVal) || (event.packageName ?? '').toLowerCase().contains(filterVal);
        }

        if (termMatches && bankMatches) {
          finalCategory = rule['category']?.toString();
          ruleAutoApprove = rule['autoApprove'] == true;
          ruleMatched = rule['keyword']?.toString();
          break; // Primeiro match vence
        }
      }

      // 3. Tentar conciliar com algum título do cache Omie
      Map<String, dynamic>? match;
      if (result.isIncome) {
        match = await _findMatchingTitle(result);
      }

      final int? nCodLanc = match != null ? int.tryParse((match['item']['codigo_lancamento_omie'] ?? match['item']['codigo_lancamento_integracao'] ?? '').toString()) : null;
      final String? dueDate = match != null ? (match['item']['data_vencimento'] ?? match['item']['data_venc'] ?? match['item']['dtVenc']?.toString()) : null;

      // Se nenhuma regra customizada bateu, sugere por histórico ou Omie
      if (finalCategory == null) {
        final String? suggestedCategory = await _suggestCategoryByHistory(result.restaurant ?? '', result.isIncome);
        finalCategory = suggestedCategory ?? (match != null ? (match['item']['cDesCategor'] ?? 'Receitas') : (result.isIncome ? 'Receitas' : 'Geral'));
      }

      final String finalCategoryString = finalCategory ?? (result.isIncome ? 'Receitas' : 'Geral');

      // 4. Sentinela Guard: Detecção de Anomalias antes da reconciliação
      final tempTx = TransactionModel(
        id: '',
        description: result.restaurant ?? 'Reconciliação Automática',
        amount: result.amount!,
        category: finalCategoryString,
        date: result.date ?? DateTime.now(),
        type: result.isIncome ? TransactionType.income : TransactionType.expense,
      );

      final anomalyResult = AnomalyService.check(tempTx, history);
      final bool isSuspect = anomalyResult.isSuspect;
      final String anomalyReason = anomalyResult.reason;
      final double anomalyScore = anomalyResult.score;

      // 5. Determinar se vai autoconciliar
      bool autoReconciled = false;
      if (result.isIncome && match != null && result.restaurant != null && result.restaurant!.isNotEmpty) {
        final String clientName = match['clientName'].toString().toLowerCase();
        final String restaurant = result.restaurant!.toLowerCase();
        if (clientName.contains(restaurant) || restaurant.contains(clientName)) {
          autoReconciled = true;
        }
      }

      // Se a regra definir aprovação automática, ativa autoconciliação
      if (ruleAutoApprove) {
        autoReconciled = true;
      }

      // BLOQUEIO DE SEGURANÇA: Se for suspeito, nunca autoconcilia
      if (isSuspect) {
        autoReconciled = false;
      }

      if (autoReconciled) {
        // Efetuar a quitação no Omie em segundo plano
        if (nCodLanc != null) {
          _payOmieBillInBackground(nCodLanc, result.amount!);
        }

        // Salvar a transação localmente no Realtime DB
        debugPrint("💾 [DEBUG] Saving auto-reconciled transaction to DB with amount: ${result.amount}, category: $finalCategoryString");
        print('💾 [DEBUG] Saving auto-reconciled transaction to DB: amount=${result.amount}, category=$finalCategoryString');
        await _db.addTransaction(TransactionModel(
          id: '',
          description: result.restaurant ?? 'Reconcilação Automática',
          amount: result.amount!,
          category: finalCategoryString,
          date: DateTime.now(),
          type: result.isIncome ? TransactionType.income : TransactionType.expense,
        ));

        // Registrar o log da notificação na Caixa de Entrada como "confirmed" (Conciliado)
        final log = {
          'timestamp': DateTime.now().toIso8601String(),
          'packageName': event.packageName,
          'title': event.title ?? '',
          'text': event.text ?? '',
          'amount': result.amount,
          'restaurant': result.restaurant ?? '',
          'isIncome': result.isIncome,
          'suggestedCategory': finalCategoryString,
          'nCodLanc': nCodLanc,
          'dueDate': dueDate,
          'status': 'confirmed',
          'autoReconciled': true,
          'isSuspect': isSuspect,
          'anomalyReason': anomalyReason,
          'anomalyScore': anomalyScore,
          'ruleMatched': ruleMatched,
        };
        await _db.addNotificationLog(uniqueKey, log);

        // Mostrar notificação local informativa de autoconciliação
        final notificationTitle = 'Conciliado Automaticamente! ⚡';
        final notificationBody = match != null 
            ? 'A fatura "${match['item']['cDesCategor'] ?? 'Sem descrição'}" de R\$ ${result.amount!.toStringAsFixed(2)} foi quitada via Pix!'
            : 'O lançamento de R\$ ${result.amount!.toStringAsFixed(2)} em "$finalCategoryString" foi registrado!';
        
        final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'bank_sync_channel',
          'Sincronização Bancária',
          channelDescription: 'Notificações de gastos automáticos',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
        final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

        await _notificationsPlugin.show(
          id: result.hashCode,
          title: notificationTitle,
          body: notificationBody,
          notificationDetails: platformChannelSpecifics,
          payload: '${result.amount}|${result.restaurant}|${result.date?.toIso8601String()}|${result.isIncome}|${nCodLanc ?? ''}|$finalCategoryString|$uniqueKey',
        );
      } else {
        // Lógica Normal: Registrar log como "suggested" (Pendente)
        final log = {
          'timestamp': DateTime.now().toIso8601String(),
          'packageName': event.packageName,
          'title': event.title ?? '',
          'text': event.text ?? '',
          'amount': result.amount,
          'restaurant': result.restaurant ?? '',
          'isIncome': result.isIncome,
          'suggestedCategory': finalCategoryString,
          'nCodLanc': nCodLanc,
          'dueDate': dueDate,
          'status': 'suggested',
          'autoReconciled': false,
          'isSuspect': isSuspect,
          'anomalyReason': anomalyReason,
          'anomalyScore': anomalyScore,
          'ruleMatched': ruleMatched,
        };
        await _db.addNotificationLog(uniqueKey, log);

        _showSyncSuggestion(
          result,
          finalCategory: finalCategoryString,
          nCodLanc: nCodLanc,
          match: match,
          uniqueKey: uniqueKey,
          isSuspect: isSuspect,
          anomalyReason: anomalyReason,
        );
      }
    }
  }

  static Future<void> _showSyncSuggestion(
    OcrResult result, {
    required String finalCategory,
    int? nCodLanc,
    Map<String, dynamic>? match,
    required String uniqueKey,
    bool isSuspect = false,
    String? anomalyReason,
  }) async {
    final isIncome = result.isIncome;
    final hasMatch = match != null;

    final title = isSuspect
        ? '🛡️ Alerta Sentinela: Gasto Suspeito?'
        : (hasMatch
            ? 'Conciliação Disponível! 📈'
            : (isIncome ? 'Entrada Detectada! 💸' : 'Gasto Detectado! 🏦'));

    final body = isSuspect
        ? 'Suspeito: $anomalyReason. Confirmar R\$ ${result.amount!.toStringAsFixed(2)}?'
        : (hasMatch
            ? 'Vincular recebimento de R\$ ${result.amount!.toStringAsFixed(2)} de ${result.restaurant} ao título "${match['item']['cDesCategor'] ?? 'Sem descrição'}"?'
            : (isIncome 
                ? 'Registrar entrada de R\$ ${result.amount!.toStringAsFixed(2)} de ${result.restaurant}?'
                : 'Registrar R\$ ${result.amount!.toStringAsFixed(2)} em ${result.restaurant}?'));

    final actionLabel = isSuspect
        ? 'RECONHECER GASTO'
        : (hasMatch
            ? 'CONFIRMAR CONCILIAÇÃO'
            : (isIncome ? 'CONFIRMAR ENTRADA' : 'CONFIRMAR GASTO'));

    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'bank_sync_channel',
      'Sincronização Bancária',
      channelDescription: 'Notificações de gastos automáticos',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: [
        AndroidNotificationAction('confirm', actionLabel, showsUserInterface: true),
        AndroidNotificationAction('ignore', 'IGNORAR', showsUserInterface: false),
      ],
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id: result.hashCode,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: '${result.amount}|${result.restaurant}|${result.date?.toIso8601String()}|$isIncome|${nCodLanc ?? ''}|$finalCategory|$uniqueKey',
    );
  }

  static void _handleNotificationAction(NotificationResponse response) async {
    if (response.payload == null) return;
    final parts = response.payload!.split('|');
    if (parts.length < 4) return;

    final amount = double.parse(parts[0]);
    final store = parts[1];
    final date = DateTime.parse(parts[2]);
    final isIncome = parts[3] == 'true';

    final String? nCodLancStr = parts.length > 4 ? parts[4] : null;
    final String category = parts.length > 5 && parts[5].isNotEmpty ? parts[5] : (isIncome ? 'Receitas' : 'Geral');
    final String? uniqueKey = parts.length > 6 ? parts[6] : null;

    if (response.actionId == null || response.actionId!.isEmpty) {
      // O usuário clicou no corpo da notificação. Redirecionar para a Caixa de Entrada Bancária!
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (context) => const BankSyncInboxScreen(),
      ));
      return;
    }

    if (response.actionId == 'confirm') {
      // 1. Salvar no Firebase Realtime DB
      await _db.init(); 
      debugPrint("💾 [DEBUG] Adding transaction from confirmation action: amount=$amount, category=$category, isIncome=$isIncome");
      print('💾 [DEBUG] Adding transaction from confirmation action: amount=$amount, category=$category, isIncome=$isIncome');
      await _db.addTransaction(TransactionModel(
        id: '',
        description: store,
        amount: amount,
        category: category,
        date: date,
        type: isIncome ? TransactionType.income : TransactionType.expense,
      ));

      // 2. Liquidar no Omie se houver título vinculado
      if (nCodLancStr != null && nCodLancStr.isNotEmpty) {
        final int? nCodLanc = int.tryParse(nCodLancStr);
        if (nCodLanc != null) {
          _payOmieBillInBackground(nCodLanc, amount);
        }
      }

      // 3. Atualizar status na Caixa de Entrada
      if (uniqueKey != null && uniqueKey.isNotEmpty) {
        await _db.updateNotificationLogStatus(uniqueKey, 'confirmed');
      }
    } else if (response.actionId == 'ignore') {
      if (uniqueKey != null && uniqueKey.isNotEmpty) {
        await _db.updateNotificationLogStatus(uniqueKey, 'ignored');
      }
    }
  }

  static Future<void> _payOmieBillInBackground(int nCodLanc, double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final accountsKey = uid != null ? 'omie_accounts_v2_$uid' : 'omie_accounts_v2';
      final activeIdKey = uid != null ? 'active_account_id_$uid' : 'active_account_id';

      final accountsJson = prefs.getString(accountsKey);
      if (accountsJson == null) return;

      final List<dynamic> decoded = jsonDecode(accountsJson);
      final activeId = prefs.getString(activeIdKey);
      
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
          if (kDebugMode) print('Título $nCodLanc liquidado via segundo plano.');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao dar baixa em segundo plano: $e');
    }
  }

  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    await NotificationsListener.openPermissionSettings();
  }
}
