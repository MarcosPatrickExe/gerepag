import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'providers/transactions_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/user_stats_provider.dart';
import 'providers/business_bi_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/global_settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/bank_sync_service.dart';
import 'services/widget_service.dart';
import 'services/push_notification_service.dart';
import 'services/budget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:convert';
import 'models/omie_account.dart';
import 'services/omie_service.dart';

const String bpoSyncTaskName = "com.gerepague.bpoSyncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("🔄 [BACKGROUND WORKER] Iniciando tarefa: $task");
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? accountsStr = prefs.getString('omie_accounts_v2');
      if (accountsStr == null || accountsStr.isEmpty) {
        debugPrint("⚠️ [BACKGROUND WORKER] Nenhuma conta configurada. Saindo.");
        return true;
      }

      final List<dynamic> accountsRaw = jsonDecode(accountsStr);
      final List<OmieAccount> accounts = accountsRaw.map((a) => OmieAccount.fromMap(Map<String, dynamic>.from(a))).toList();
      
      double totalBanco = 0;
      double totalReceber = 0;
      double totalPagar = 0;
      
      List<dynamic> allReceivables = [];
      List<dynamic> allPayables = [];
      List<dynamic> allOS = [];
      List<dynamic> allOrders = [];
      
      Map<String, String> allCategories = {};
      Map<String, String> allClients = {};
      Map<String, String> allProjects = {};
      Map<String, String> allDepartments = {};
      Map<String, String> allUnits = {};

      for (var acc in accounts) {
        debugPrint("🔄 [BACKGROUND WORKER] Sincronizando conta: ${acc.name}");
        final omie = OmieService(appKey: acc.appKey, appSecret: acc.appSecret);
        
        try {
          final summary = await omie.getFinancialSummary();
          if (summary != null) {
            totalBanco += double.tryParse(summary['contaCorrente']?['vTotal']?.toString() ?? '0') ?? 0;
            totalReceber += double.tryParse(summary['contaReceber']?['vTotal']?.toString() ?? '0') ?? 0;
            totalPagar += double.tryParse(summary['contaPagar']?['vTotal']?.toString() ?? '0') ?? 0;
          }

          final receivables = await omie.listAccountsReceivable();
          final payables = await omie.listAccountsPayable();

          allReceivables.addAll(receivables);
          allPayables.addAll(payables);
          allOS.addAll(await omie.listServiceOrders());
          allOrders.addAll(await omie.listSalesOrders());
          allCategories.addAll(await omie.listCategories());
          allClients.addAll(await omie.listClients());
          allProjects.addAll(await omie.listProjects());
          allDepartments.addAll(await omie.listDepartments());
          allUnits.addAll(await omie.listBusinessUnits());
        } catch (e) {
          debugPrint("⚠️ [BACKGROUND WORKER] Erro ao sincronizar ${acc.name}: $e");
        }
      }

      final cache = {
        'summary': {
          "contaCorrente": {"vTotal": totalBanco},
          "contaReceber": {"vTotal": totalReceber},
          "contaPagar": {"vTotal": totalPagar},
        },
        'receivable': allReceivables,
        'payable': allPayables,
        'os': allOS,
        'orders': allOrders,
        'bankBalances': [],
        'categories': allCategories,
        'clients': allClients,
        'projects': allProjects,
        'departments': allDepartments,
        'units': allUnits,
        'lastSync': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString('omie_sync_cache_v1', jsonEncode(cache));
      debugPrint("✅ [BACKGROUND WORKER] Sincronização concluída e salva no cache!");
    } catch (e) {
      debugPrint("❌ [BACKGROUND WORKER] Erro crítico na tarefa de background: $e");
    }

    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // 1. Inicialização do Firebase com Retry para Hot Restarts
  bool firebaseReady = false;
  int retryCount = 0;
  
  // Garantir que os canais de plataforma nativos estejam totalmente estabelecidos
  await Future.delayed(const Duration(milliseconds: 800));

  while (!firebaseReady && retryCount < 4) {
    try {
      debugPrint('LOG: Inicializando Firebase (Tentativa ${retryCount + 1})...');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      firebaseReady = true;
      debugPrint('LOG: Firebase inicializado com sucesso!');
    } catch (e) {
      debugPrint('AVISO: Falha ao inicializar Firebase (tentativa ${retryCount + 1}): $e');
      if (e.toString().contains('duplicate-app') || e.toString().contains('already-exists') || Firebase.apps.isNotEmpty) {
        firebaseReady = true;
      } else {
        retryCount++;
        if (retryCount < 4) {
          await Future.delayed(Duration(milliseconds: 1000 * retryCount));
        }
      }
    }
  }

  // 2. Carregar preferências
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;

  // Inicialização do Workmanager
  if (!kIsWeb) {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      await Workmanager().registerPeriodicTask(
        "1",
        bpoSyncTaskName,
        frequency: const Duration(hours: 4),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      debugPrint('LOG: Workmanager inicializado com sucesso!');
    } catch (e) {
      debugPrint('AVISO: Falha ao inicializar Workmanager: $e');
    }
  }

  // 3. Registrar serviços secundários apenas se o Firebase estiver pronto
  if (firebaseReady) {
    try {
      FirebaseMessaging.onBackgroundMessage(PushNotificationService.firebaseMessagingBackgroundHandler);
      
      if (!kIsWeb) {
        debugPrint('LOG: Iniciando serviços secundários...');
        BankSyncService.init().catchError((e) => debugPrint('Erro BankSync: $e'));
        WidgetService.initLaunchListener((payload) => debugPrint('Widget: $payload')).catchError((e) => debugPrint('Erro Widget: $e'));
        PushNotificationService.init().catchError((e) => debugPrint('Erro Push: $e'));
      }
    } catch (e) {
      debugPrint('AVISO: Falha em serviço secundário (não crítico): $e');
    }
  }


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionsProvider()..init()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => UserStatsProvider()..init()),
        ChangeNotifierProvider(create: (_) => BudgetService()),
        ChangeNotifierProvider(create: (_) => BusinessBiProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => GlobalSettingsProvider()),
      ],
      child: ControleFinanceiroApp(showOnboarding: !onboardingDone),
    ),
  );
}

class ControleFinanceiroApp extends StatelessWidget {
  final bool showOnboarding;
  const ControleFinanceiroApp({ super.key, required this.showOnboarding });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GerePag',
      navigatorKey: BankSyncService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: showOnboarding 
          ? const OnboardingScreen() 
          : const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const AuthSessionLoader();
        }
        return const LoginScreen();
      },
    );
  }
}

class AuthSessionLoader extends StatefulWidget {
  const AuthSessionLoader({super.key});

  @override
  State<AuthSessionLoader> createState() => _AuthSessionLoaderState();
}

class _AuthSessionLoaderState extends State<AuthSessionLoader> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      final provider = Provider.of<TransactionsProvider>(context, listen: false);
      await provider.init();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Erro ao inicializar sessão financeira',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                    _initSession();
                  },
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Carregando dados financeiros...',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return const HomeScreen();
  }
}
