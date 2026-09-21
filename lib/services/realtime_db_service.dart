import 'dart:async';
import 'package:firebase_core/firebase_core.dart'; // Adicionado
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../models/wallet_model.dart';
import '../models/credit_card_model.dart';
import '../models/challenge_model.dart';
import '../models/badge_model.dart';

class RealtimeDbService {
  // Usar getters para evitar erro caso o Firebase não esteja pronto no momento da instanciação
  FirebaseDatabase get _db => FirebaseDatabase.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  String? _familyId;
  static String? bpoActiveClientUid;

  void setBpoActiveClient(String? clientUid) {
    bpoActiveClientUid = clientUid;
  }

  String? get _effectiveUid {
    if (bpoActiveClientUid != null) {
      return bpoActiveClientUid;
    }
    return _auth.currentUser?.uid;
  }

  // Inicializar e buscar se o usuário pertence a uma família
  Future<void> init() async {
    if (Firebase.apps.isEmpty) return;
    String? uid = _effectiveUid;
    if (uid == null) return;
    
    final snapshot = await _db.ref('users/$uid/familyId').get();
    if (snapshot.exists) {
      _familyId = snapshot.value.toString();
    }
    
    // Atualizar último login para controle do admin
    await _db.ref('users/$uid/profile').update({
      'lastLoginAt': ServerValue.timestamp,
    });
  }

  // Define o caminho raiz dos dados (Individual ou Família)
  String get _rootPath {
    String? uid = _effectiveUid;
    if (uid == null) return 'unknown';
    if (_familyId != null && bpoActiveClientUid == null) return 'families/$_familyId';
    return 'users/$uid';
  }

  // --- FAMÍLIA CONTROLLER ---

  Future<String> createFamily() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return '';

    // 1. Gerar um novo ID de família
    final newFamilyRef = _db.ref('families').push();
    final familyId = newFamilyRef.key!;

    // 2. Vincular usuário à família
    await _db.ref('users/$uid/familyId').set(familyId);
    
    // 3. Migrar dados atuais
    await _migrateToFamily(uid, familyId);
    
    _familyId = familyId;
    return familyId;
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/profile').update(data);
  }

  Future<void> saveClientLogo(String base64) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/profile/logo').set(base64);
  }

  Future<String?> getClientLogo() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snapshot = await _db.ref('users/$uid/profile/logo').get();
    return snapshot.value?.toString();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snapshot = await _db.ref('users/$uid/profile').get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  // Inicializa a estrutura de dados para um novo usuário
  Future<void> initializeNewUser(String email, {required String niche}) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userRef = _db.ref('users/$uid');
    
    String accountType = 'pessoal';
    if (niche == 'autonomo' || niche == 'empresa' || niche == 'bpo' || niche == 'contador') {
      accountType = 'juridica';
    }

    // 1. Criar Perfil Inicial
    await userRef.child('profile').set({
      'email': email,
      'name': email.split('@')[0], // Nome provisório baseado no e-mail
      'joinedAt': ServerValue.timestamp,
      'balance': 0.0,
      'accountType': accountType,
      'niche': niche,
      'role': email == 'empresa@gmail.com.br' ? 'admin' : 'user', // Define admin inicial
    });

    // 2. Injetar Categorias Padrão
    final List<String> defaultCategories = [
      'Alimentação 🍔',
      'Transporte 🚗',
      'Moradia 🏠',
      'Lazer 🍿',
      'Saúde 💊',
      'Educação 📚',
      'Outros ⚙️',
    ];

    for (var cat in defaultCategories) {
      await userRef.child('categories').push().set(cat);
    }
  }

  Future<void> _migrateToFamily(String uid, String familyId) async {
    final userRef = _db.ref('users/$uid');
    final familyRef = _db.ref('families/$familyId');

    final snapshot = await userRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.remove('familyId'); // Não queremos o familyId dentro da pasta da família
      await familyRef.update(data);
      // Opcional: deletar dados antigos do usuário? No momento vou manter por segurança.
    }
  }

  Future<bool> joinFamily(String familyId) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    // Verificar se família existe
    final snapshot = await _db.ref('families/$familyId').get();
    if (!snapshot.exists) return false;

    await _db.ref('users/$uid/familyId').set(familyId);
    _familyId = familyId;
    return true;
  }

  // --- TRANSAÇÕES ---

  Stream<List<TransactionModel>> getTransactions() {
    return _db.ref('$_rootPath/transactions').onValue.map((event) {
      final List<TransactionModel> transactions = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          transactions.add(TransactionModel.fromMap(key, Map<String, dynamic>.from(value)));
        });
      }
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    });
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _db.ref('$_rootPath/transactions').push().set(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _db.ref('$_rootPath/transactions/$id').remove();
  }

  // --- CATEGORIAS ---

  Stream<List<String>> getCategories() {
    return _db.ref('$_rootPath/categories').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.values.map((v) => v.toString()).toList();
    });
  }

  Future<void> addCategory(String category) async {
    await _db.ref('$_rootPath/categories').push().set(category);
  }

  // --- ORÇAMENTOS ---

  Stream<Map<String, double>> getBudgets() {
    return _db.ref('$_rootPath/budgets').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      return Map<String, double>.from(data.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())));
    });
  }

  Future<void> setBudget(String category, double amount) async {
    await _db.ref('$_rootPath/budgets/$category').set(amount);
  }

  Future<void> deleteBudget(String category) async {
    await _db.ref('$_rootPath/budgets/$category').remove();
  }

  // --- METAS ---

  Stream<List<GoalModel>> getGoals() {
    return _db.ref('$_rootPath/goals').onValue.map((event) {
      final List<GoalModel> goals = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          goals.add(GoalModel.fromMap(key, Map<String, dynamic>.from(value)));
        });
      }
      return goals;
    });
  }

  Future<void> addGoal(GoalModel goal) async {
    final ref = _db.ref('$_rootPath/goals');
    if (goal.id.isEmpty) {
      await ref.push().set(goal.toMap());
      await unlockBadge('first_goal');
    } else {
      await ref.child(goal.id).set(goal.toMap());
    }
  }

  Future<void> updateGoalProgress(String goalId, double newAmount) async {
    await _db.ref('$_rootPath/goals/$goalId/currentAmount').set(newAmount);
  }

  Future<void> deleteGoal(String goalId) async {
    await _db.ref('$_rootPath/goals/$goalId').remove();
  }

  // --- CARTEIRAS (WALLETS) ---

  Stream<List<WalletModel>> getWallets() {
    return _db.ref('$_rootPath/wallets').onValue.map((event) {
      final List<WalletModel> wallets = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          wallets.add(WalletModel.fromMap(key, Map<String, dynamic>.from(value)));
        });
      }
      return wallets;
    });
  }

  Future<void> addWallet(WalletModel wallet) async {
    await _db.ref('$_rootPath/wallets').push().set(wallet.toMap());
  }

  Future<void> updateWallet(String walletId, Map<String, dynamic> data) async {
    await _db.ref('$_rootPath/wallets/$walletId').update(data);
  }

  Future<void> deleteWallet(String walletId) async {
    await _db.ref('$_rootPath/wallets/$walletId').remove();
  }

  // --- CARTÕES DE CRÉDITO ---

  Stream<List<CreditCardModel>> getCreditCards() {
    return _db.ref('$_rootPath/credit_cards').onValue.map((event) {
      final List<CreditCardModel> cards = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          cards.add(CreditCardModel.fromMap(key, Map<String, dynamic>.from(value)));
        });
      }
      return cards;
    });
  }

  Future<void> addCreditCard(CreditCardModel card) async {
    await _db.ref('$_rootPath/credit_cards').push().set(card.toMap());
  }

  Future<void> updateCreditCard(String cardId, Map<String, dynamic> data) async {
    await _db.ref('$_rootPath/credit_cards/$cardId').update(data);
  }

  Future<void> deleteCreditCard(String cardId) async {
    await _db.ref('$_rootPath/credit_cards/$cardId').remove();
  }

  // --- ASSINATURAS ---

  Stream<List<Map<String, dynamic>>> getSubscriptions() {
    return _db.ref('$_rootPath/subscriptions').onValue.map((event) {
      final List<Map<String, dynamic>> subs = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value);
          map['id'] = key;
          subs.add(map);
        });
      }
      return subs;
    });
  }

  Future<void> addSubscription(Map<String, dynamic> subscription) async {
    await _db.ref('$_rootPath/subscriptions').push().set(subscription);
  }

  Future<void> deleteSubscription(String id) async {
    await _db.ref('$_rootPath/subscriptions/$id').remove();
  }

  // --- BADGES ---

  Stream<Map<String, DateTime>> getUnlockedBadges() {
    return _db.ref('$_rootPath/badges').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      return Map<String, DateTime>.from(data.map((k, v) => MapEntry(k.toString(), DateTime.parse(v['unlockedAt']))));
    });
  }

  Future<void> unlockBadge(String badgeId) async {
    await _db.ref('$_rootPath/badges/$badgeId').set({
      'unlockedAt': DateTime.now().toIso8601String(),
    });
  }

  // --- OMIE CREDENTIALS (Sincronizado) ---

  Future<void> saveOmieCredentials(String key, String secret) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _db.ref('users/$uid/omie').set({
      'key': key,
      'secret': secret,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Stream<Map<String, dynamic>?> getOmieCredentials() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    
    return _db.ref('users/$uid/omie').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  // --- SINCRONIZAÇÃO OMIE (LONG-TERM CACHE) ---

  Future<void> saveOmieSyncData(String type, List<dynamic> items) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    DatabaseReference ref = _db.ref('omie_sync/$uid/$type');
    
    // Salvar cada item usando seu código único da Omie como chave para evitar duplicidade
    Map<String, dynamic> updates = {};
    for (var item in items) {
      String? code = item['codigo_lancamento_omie']?.toString() ?? 
                    item['codigo_lancamento_integracao']?.toString();
      if (code != null) {
        updates[code] = item;
      }
    }

    if (updates.isNotEmpty) {
      await ref.update(updates);
    }
  }

  Stream<List<dynamic>> getOmieSyncData(String type) {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db.ref('omie_sync/$uid/$type').onValue.map((event) {
      if (event.snapshot.value == null) return [];
      Map map = event.snapshot.value as Map;
      return map.values.toList();
    });
  }

  Future<void> saveOmieCategories(Map<String, String> categories) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    // Firebase Realtime DB keys não suportam '.', '#', '$', '[', ou ']'
    // A API Omie retorna categorias como '0.01', então precisamos mascarar o '.' no sync
    final safeMap = categories.map((k, v) => MapEntry(k.replaceAll('.', '_dot_'), v));
    await _db.ref('omie_sync/$uid/categories').set(safeMap);
  }

  Stream<Map<String, String>> getOmieCategories() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db.ref('omie_sync/$uid/categories').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      final rawMap = Map<String, String>.from(event.snapshot.value as Map);
      return rawMap.map((k, v) => MapEntry(k.replaceAll('_dot_', '.'), v));
    });
  }

  Future<void> saveOmieClients(Map<String, String> clients) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('omie_sync/$uid/clients').set(clients);
  }

  Stream<Map<String, String>> getOmieClients() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('omie_sync/$uid/clients').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      return Map<String, String>.from(event.snapshot.value as Map);
    });
  }

  Future<void> saveOmieProjects(Map<String, String> projects) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('omie_sync/$uid/projects').set(projects);
  }

  Stream<Map<String, String>> getOmieProjects() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('omie_sync/$uid/projects').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      return Map<String, String>.from(event.snapshot.value as Map);
    });
  }

  Future<void> saveOmieSummary(Map<String, dynamic> summary) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('omie_sync/$uid/summary').set(summary);
  }

  Stream<Map<String, dynamic>> getOmieSummary() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('omie_sync/$uid/summary').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  Future<void> saveOmieOS(List<dynamic> items) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    DatabaseReference ref = _db.ref('omie_sync/$uid/os');
    Map<String, dynamic> updates = {};
    for (var item in items) {
      String? code = item['nCodOS']?.toString();
      if (code != null) updates[code] = item;
    }
    if (updates.isNotEmpty) await ref.update(updates);
  }

  Stream<List<dynamic>> getOmieOS() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('omie_sync/$uid/os').onValue.map((event) {
      if (event.snapshot.value == null) return [];
      Map map = event.snapshot.value as Map;
      return map.values.toList();
    });
  }

  Future<void> saveOmieOrders(List<dynamic> items) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    DatabaseReference ref = _db.ref('omie_sync/$uid/orders');
    Map<String, dynamic> updates = {};
    for (var item in items) {
      String? code = item['cabecalho']?['nCodPedido']?.toString();
      if (code != null) updates[code] = item;
    }
    if (updates.isNotEmpty) await ref.update(updates);
  }

  Stream<List<dynamic>> getOmieOrders() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('omie_sync/$uid/orders').onValue.map((event) {
      if (event.snapshot.value == null) return [];
      Map map = event.snapshot.value as Map;
      return map.values.toList();
    });
  }

  // --- OMIE MULTI-ACCOUNTS (Sincronizado) ---

  Future<void> saveOmieAccounts(List<Map<String, dynamic>> accounts) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/omie_accounts_v2').set(accounts);
  }

  Future<List<Map<String, dynamic>>> getOmieAccounts() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      print('⚠️ [REALTIME] Tentativa de buscar contas sem UID logado.');
      return [];
    }
    
    final snapshot = await _db.ref('users/$uid/omie_accounts_v2').get();
    if (snapshot.exists) {
      try {
        final val = snapshot.value;
        if (val is List) {
          return List<Map<String, dynamic>>.from(
            val.where((i) => i != null).map((i) => Map<String, dynamic>.from(i as Map)),
          );
        } else if (val is Map) {
          // Firebase às vezes retorna Map se os índices não forem contínuos
          return List<Map<String, dynamic>>.from(
            val.values.map((i) => Map<String, dynamic>.from(i as Map)),
          );
        }
      } catch (e) {
        print('❌ [REALTIME] Erro ao processar contas: $e');
      }
    }
    return [];
  }

  Future<void> setActiveOmieAccountId(String id) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/active_account_id').set(id);
  }

  Future<String?> getActiveOmieAccountId() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snapshot = await _db.ref('users/$uid/active_account_id').get();
    return snapshot.value?.toString();
  }

  Future<void> saveOmieGoal(double goal) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('omie_sync/$uid/goal').set(goal);
  }

  Stream<double> getOmieGoal() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('omie_sync/$uid/goal').onValue.map((event) {
      if (event.snapshot.value == null) return 0.0;
      return double.tryParse(event.snapshot.value.toString()) ?? 0.0;
    });
  }

  // --- DESAFIOS ---

  Stream<List<ChallengeModel>> getChallenges() {
    return _db.ref('$_rootPath/challenges').onValue.map((event) {
      final List<ChallengeModel> challenges = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          challenges.add(ChallengeModel.fromMap(Map<String, dynamic>.from(value), key));
        });
      }
      return challenges;
    });
  }

  Future<void> addChallenge(ChallengeModel challenge) async {
    await _db.ref('$_rootPath/challenges').push().set(challenge.toMap());
  }

  Future<void> updateChallenge(ChallengeModel challenge) async {
    await _db.ref('$_rootPath/challenges/${challenge.id}').set(challenge.toMap());
  }

  Future<void> deleteChallenge(String id) async {
    await _db.ref('$_rootPath/challenges/$id').remove();
  }

  // --- SUPER ADMIN ---

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _db.ref('users').get();
    if (!snapshot.exists) return [];
    
    final Map<dynamic, dynamic> data = snapshot.value as Map;
    final List<Map<String, dynamic>> users = [];
    
    data.forEach((uid, userData) {
      if (userData is Map && userData['profile'] != null) {
        final profile = Map<String, dynamic>.from(userData['profile']);
        profile['uid'] = uid;
        users.add(profile);
      }
    });
    
    return users;
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _db.ref('users/$uid/profile/role').set(role);
  }

  /// Promove um usuário a Super Admin pelo e-mail
  Future<void> makeUserSuperAdminByEmail(String email) async {
    final snapshot = await _db.ref('users').get();
    if (!snapshot.exists) return;
    
    final Map<dynamic, dynamic> data = snapshot.value as Map;
    for (var entry in data.entries) {
      final uid = entry.key;
      final userData = entry.value;
      if (userData is Map && userData['profile'] != null) {
        final profile = userData['profile'];
        if (profile['email'] == email) {
          await _db.ref('users/$uid/profile/role').set('admin');
          print('✅ Usuário $email promovido a ADMIN com sucesso!');
          return;
        }
      }
    }
    print('❌ Usuário com e-mail $email não encontrado.');
  }

  /// Promove o usuário logado atualmente a Super Admin
  Future<void> promoteCurrentUserToAdmin() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/profile/role').set('admin');
    print('✅ Você agora é um ADMIN!');
  }

  /// Remove um usuário completamente do banco de dados (CUIDADO!)
  Future<void> deleteUser(String uid) async {
    await _db.ref('users/$uid').remove();
    await _db.ref('omie_sync/$uid').remove();
  }

  // --- SEGMENTAÇÃO E REGIME FISCAL DOS CLIENTES BPO ---

  Future<void> saveBpoClientTaxRegime(String clientUid, String regime) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_clients/$clientUid').update({
      'taxRegime': regime,
    });
  }

  Future<void> saveBpoClientTags(String clientUid, List<String> tags) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_clients/$clientUid').update({
      'tags': tags,
    });
  }

  // --- CALENDÁRIO FISCAL BPO ---

  Future<void> addBpoClientFiscalEvent(String clientUid, Map<String, dynamic> event) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_clients/$clientUid/fiscal_calendar').push().set({
      ...event,
      'createdAt': ServerValue.timestamp,
    });
  }

  Stream<List<Map<String, dynamic>>> getBpoClientFiscalCalendar(String clientUid) {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return const Stream.empty();
    return _db.ref('users/$bpoUid/bpo_clients/$clientUid/fiscal_calendar').onValue.map((event) {
      final List<Map<String, dynamic>> list = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            map['id'] = key;
            list.add(map);
          }
        });
      }
      return list;
    });
  }

  Future<void> toggleBpoClientFiscalEventStatus(String clientUid, String eventId, bool isDone) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_clients/$clientUid/fiscal_calendar/$eventId').update({
      'isDone': isDone,
    });
  }

  Future<void> deleteBpoClientFiscalEvent(String clientUid, String eventId) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_clients/$clientUid/fiscal_calendar/$eventId').remove();
  }

  // --- MENSAGEM DO BPO PARA O CLIENTE ---

  Future<void> setBpoClientMessage(String clientUid, String message) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    
    // Obter o perfil do BPO para exibir o nome no aviso
    final bpoSnap = await _db.ref('users/$bpoUid/profile').get();
    final bpoName = bpoSnap.exists && bpoSnap.value != null 
        ? (bpoSnap.value as Map)['name']?.toString() ?? 'Seu BPO Financeiro'
        : 'Seu BPO Financeiro';

    await _db.ref('users/$clientUid/profile/bpo_message').set({
      'message': message,
      'bpoName': bpoName,
      'sentAt': ServerValue.timestamp,
    });
  }

  Stream<Map<String, dynamic>?> getBpoMessageForClient() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('users/$uid/profile/bpo_message').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  // --- ANOTAÇÃO DO CLIENTE BPO ---

  Future<void> saveBpoClientNote(String clientUid, String note) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_clients/$clientUid/note').set(note);
  }

  Stream<String?> getClientNote(String clientUid) {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return const Stream.empty();
    return _db.ref('users/$bpoUid/bpo_clients/$clientUid/note').onValue.map(
      (event) => event.snapshot.value?.toString(),
    );
  }

  // --- LOG DE AUDITORIA BPO ---

  Future<void> addAuditLog(Map<String, dynamic> entry) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/audit_log').push().set({
      ...entry,
      'ts': ServerValue.timestamp,
    });
  }

  Stream<List<Map<String, dynamic>>> getAuditLogs() {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return const Stream.empty();
    return _db.ref('users/$bpoUid/audit_log').limitToLast(200).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      final list = <Map<String, dynamic>>[];
      data.forEach((key, val) {
        if (val is Map) {
          final map = Map<String, dynamic>.from(val);
          map['id'] = key;
          list.add(map);
        }
      });
      list.sort((a, b) {
        final tA = (a['ts'] as num?)?.toInt() ?? 0;
        final tB = (b['ts'] as num?)?.toInt() ?? 0;
        return tB.compareTo(tA);
      });
      return list;
    });
  }

  // --- FEED UNIFICADO DE TRANSAÇÕES DE CLIENTES ---

  Future<List<Map<String, dynamic>>> getClientRecentTransactions(
    String clientUid, {
    int limit = 6,
  }) async {
    try {
      final snap = await _db.ref('users/$clientUid/transactions').limitToLast(limit).get();
      if (!snap.exists || snap.value == null) return [];
      final data = snap.value as Map<dynamic, dynamic>;
      final list = <Map<String, dynamic>>[];
      data.forEach((key, val) {
        if (val is Map) {
          final map = Map<String, dynamic>.from(val);
          map['id'] = key;
          map['clientUid'] = clientUid;
          list.add(map);
        }
      });
      list.sort((a, b) {
        final dA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
        final dB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
        return dB.compareTo(dA);
      });
      return list.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  // --- CLIENTES BPO GERAL ---

  Stream<List<Map<String, dynamic>>> getBpoClients() {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return const Stream.empty();
    return _db.ref('users/$bpoUid/bpo_clients').onValue.map((event) {
      final List<Map<String, dynamic>> list = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            map['id'] = key;
            list.add(map);
          }
        });
      }
      return list;
    });
  }

  // --- SAVING GOALS ---

  Stream<List<Map<String, dynamic>>> getSavingGoals() {
    return _db.ref('$_rootPath/saving_goals').onValue.map((event) {
      final List<Map<String, dynamic>> goals = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value);
          map['id'] = key;
          goals.add(map);
        });
      }
      return goals;
    });
  }

  Future<void> addSavingGoal(Map<String, dynamic> goal) async {
    await _db.ref('$_rootPath/saving_goals').push().set(goal);
  }

  Future<void> updateGoalAmount(String id, double newAmount) async {
    await _db.ref('$_rootPath/saving_goals/$id/currentAmount').set(newAmount);
  }

  Future<void> deleteSavingGoal(String id) async {
    await _db.ref('$_rootPath/saving_goals/$id').remove();
  }

  // --- BILLING HISTORY ---

  Future<void> saveBillingRecord({
    required String contactName,
    required double amount,
    required String dueDate,
    required String description,
    required String whatsappText,
    required String clientId,
  }) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    final now = DateTime.now().toIso8601String();
    await _db.ref('users/$bpoUid/billing_history').push().set({
      'contactName': contactName,
      'amount': amount,
      'dueDate': dueDate,
      'description': description,
      'whatsappText': whatsappText,
      'sentAt': now,
      'status': 'sent',
      'clientId': clientId,
    });
  }

  Stream<List<Map<String, dynamic>>> getBillingHistory() {
    return _db.ref('$_rootPath/billing_history').onValue.map((event) {
      final List<Map<String, dynamic>> list = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          map['id'] = key;
          list.add(map);
        });
      }
      return list;
    });
  }

  // --- CONTROLE DE CLIENTES LOCAL (FREELANCER) ---

  Future<void> saveLocalClient(String id, Map<String, dynamic> client) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/local_clients/$id').set(client);
  }

  Future<void> deleteLocalClient(String id) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/local_clients/$id').remove();
  }

  // --- BANK NOTIFICATION LOGS ---

  Future<List<TransactionModel>> getTransactionsOnce() async {
    await init();
    final snapshot = await _db.ref('$_rootPath/transactions').get();
    if (!snapshot.exists) return [];
    
    final List<TransactionModel> list = [];
    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      data.forEach((key, value) {
        list.add(TransactionModel.fromMap(key, Map<String, dynamic>.from(value)));
      });
    }
    return list;
  }

  Future<void> addNotificationLog(String logId, Map<String, dynamic> log) async {
    await init();
    final safeId = logId.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
    await _db.ref('$_rootPath/bank_notification_logs/$safeId').set(log);
  }

  Stream<List<Map<String, dynamic>>> getNotificationLogs() {
    return _db.ref('$_rootPath/bank_notification_logs').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      final List<Map<String, dynamic>> logs = [];
      data.forEach((key, val) {
        final map = Map<String, dynamic>.from(val as Map);
        map['id'] = key;
        logs.add(map);
      });
      logs.sort((a, b) {
        final tA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });
      return logs;
    });
  }

  Future<void> updateNotificationLogStatus(String logId, String status) async {
    await init();
    final safeId = logId.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
    await _db.ref('$_rootPath/bank_notification_logs/$safeId').update({
      'status': status,
    });
  }

  Future<void> updateNotificationLogStatusAndFlags(String logId, {required String status, required bool autoReconciled}) async {
    await init();
    final safeId = logId.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
    await _db.ref('$_rootPath/bank_notification_logs/$safeId').update({
      'status': status,
      'autoReconciled': autoReconciled,
    });
  }

  // --- REGRAS DE CONCILIAÇÃO ---

  Stream<List<Map<String, dynamic>>> getReconciliationRules() {
    return _db.ref('$_rootPath/reconciliation_rules').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      final List<Map<String, dynamic>> rules = [];
      data.forEach((key, val) {
        if (val is Map) {
          final map = Map<String, dynamic>.from(val);
          map['id'] = key;
          rules.add(map);
        }
      });
      return rules;
    });
  }

  Future<List<Map<String, dynamic>>> getReconciliationRulesOnce() async {
    await init();
    final snapshot = await _db.ref('$_rootPath/reconciliation_rules').get();
    if (!snapshot.exists) return [];
    final List<Map<String, dynamic>> rules = [];
    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      data.forEach((key, val) {
        if (val is Map) {
          final map = Map<String, dynamic>.from(val);
          map['id'] = key;
          rules.add(map);
        }
      });
    }
    return rules;
  }

  Future<void> addReconciliationRule(Map<String, dynamic> rule) async {
    await init();
    await _db.ref('$_rootPath/reconciliation_rules').push().set(rule);
  }

  Future<void> deleteReconciliationRule(String ruleId) async {
    await init();
    await _db.ref('$_rootPath/reconciliation_rules/$ruleId').remove();
  }

  // --- CONTROLE DE SERVIÇOS/PROJETOS LOCAL (FREELANCER) ---

  Future<void> saveLocalService(String id, Map<String, dynamic> service) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/local_services/$id').set(service);
  }

  Future<void> deleteLocalService(String id) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/local_services/$id').remove();
  }

  Future<void> updateLocalServiceStatus(String id, String status) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/local_services/$id/status').set(status);
  }

  Stream<List<Map<String, dynamic>>> getLocalServices() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('users/$uid/local_services').onValue.map((event) {
      final List<Map<String, dynamic>> list = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          if (value != null) {
            final map = Map<String, dynamic>.from(value as Map);
            map['id'] = key;
            list.add(map);
          }
        });
      }
      return list;
    });
  }

  // --- CONFIGURAÇÃO E MEMÓRIA DO GLAUBER ---

  Future<void> saveGlauberProfile(Map<String, dynamic> profile) async {
    String? uid = _effectiveUid;
    if (uid == null) return;
    await _db.ref('users/$uid/glauber_profile').update(profile);
  }

  Future<void> addGlauberMemory(String memory) async {
    String? uid = _effectiveUid;
    if (uid == null) return;
    final ref = _db.ref('users/$uid/glauber_profile/memories');
    final snapshot = await ref.get();
    List<dynamic> memories = [];
    if (snapshot.exists && snapshot.value is List) {
      memories = List.from(snapshot.value as List);
    }
    if (!memories.contains(memory)) {
      memories.add(memory);
      await ref.set(memories);
    }
  }

  Future<void> deleteGlauberMemory(int index) async {
    String? uid = _effectiveUid;
    if (uid == null) return;
    final ref = _db.ref('users/$uid/glauber_profile/memories');
    final snapshot = await ref.get();
    if (snapshot.value != null) {
      List<dynamic> memories = List.from(snapshot.value as List);
      if (index >= 0 && index < memories.length) {
        memories.removeAt(index);
        await ref.set(memories);
      }
    }
  }

  Stream<Map<String, dynamic>> getGlauberProfile() {
    String? uid = _effectiveUid;
    if (uid == null) return const Stream.empty();
    return _db.ref('users/$uid/glauber_profile').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  // --- CHAVE PIX DO USUÁRIO ---

  Future<void> savePixKey(String key) async {
    String? uid = _effectiveUid;
    if (uid == null) return;
    await _db.ref('users/$uid/pix_key').set(key);
  }

  Stream<String> getPixKey() {
    String? uid = _effectiveUid;
    if (uid == null) return const Stream.empty();
    return _db.ref('users/$uid/pix_key').onValue.map((event) {
      return (event.snapshot.value ?? '').toString();
    });
  }

  // --- BPO ADICIONAIS ---

  Future<bool> linkClientToBpo(String clientUid, String clientName, {String? phone}) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return false;

    final clientSnap = await _db.ref('users/$clientUid/profile').get();
    if (!clientSnap.exists) return false;

    await _db.ref('users/$clientUid/profile/assignedBpoId').set(bpoUid);

    await _db.ref('users/$bpoUid/bpo_clients/$clientUid').set({
      'name': clientName,
      'phone': phone,
      'linkedAt': ServerValue.timestamp,
    });
    return true;
  }

  Future<void> saveClientNote(String clientUid, String note) async {
    await saveBpoClientNote(clientUid, note);
  }

  Future<void> saveBpoClientRegimeAndTags(String clientUid, String regime, List<String> tags, {String? phone}) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_clients/$clientUid').update({
      'regime': regime,
      'tags': tags,
      if (phone != null) 'phone': phone,
    });
  }

  String? get currentUserUid => _auth.currentUser?.uid;

  Future<void> saveBpoClientMessage(String clientUid, String message, bool visibleToClient) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    
    final payload = {
      'message': message,
      'visible': visibleToClient,
      'updatedAt': ServerValue.timestamp,
      'bpoUid': bpoUid,
    };

    await _db.ref('users/$bpoUid/bpo_clients/$clientUid/client_message').set(payload);

    if (visibleToClient) {
      await _db.ref('users/$clientUid/profile/bpo_message').set({
        'message': message,
        'updatedAt': ServerValue.timestamp,
        'bpoName': _auth.currentUser?.email?.split('@')[0] ?? 'Contador',
      });
    } else {
      await _db.ref('users/$clientUid/profile/bpo_message').remove();
    }
  }

  Stream<Map<String, dynamic>?> getBpoClientMessage(String clientUid) {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return const Stream.empty();
    return _db.ref('users/$bpoUid/bpo_clients/$clientUid/client_message').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    });
  }

  Future<void> saveBpoFee(String clientUid, double amount, int dueDay, String status, {String? phone}) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_fees/$clientUid').set({
      'amount': amount,
      'dueDay': dueDay,
      'status': status,
      'phone': phone,
    });
  }

  Stream<Map<String, dynamic>> getBpoFees() {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return const Stream.empty();
    return _db.ref('users/$bpoUid/bpo_fees').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  Stream<List<TransactionModel>> getClientTransactions(String clientUid) {
    return _db.ref('users/$clientUid/transactions').onValue.map((event) {
      final List<TransactionModel> list = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          list.add(TransactionModel.fromMap(key, Map<String, dynamic>.from(value)));
        });
      }
      return list;
    });
  }

  Stream<Map<String, dynamic>> getBpoDocuments() {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return const Stream.empty();
    return _db.ref('users/$bpoUid/bpo_documents').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  Future<void> saveBpoDocumentStatus(String clientUid, String docType, bool value) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_documents/$clientUid/$docType').set(value);
  }

  Stream<List<Map<String, dynamic>>> getLocalClients() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('users/$uid/local_clients').onValue.map((event) {
      final List<Map<String, dynamic>> list = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          if (value != null) {
            final map = Map<String, dynamic>.from(value as Map);
            map['id'] = key;
            list.add(map);
          }
        });
      }
      return list;
    });
  }

  // --- BPO NOTAS DO ESCRITÓRIO ---

  Stream<Map<String, dynamic>> getBpoNotes() {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return const Stream.empty();
    return _db.ref('users/$bpoUid/bpo_notes').onValue.map((event) {
      if (event.snapshot.value == null) return {};
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  Future<void> addBpoNote(String text) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_notes').push().set({
      'text': text,
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> deleteBpoNote(String noteId) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_notes/$noteId').remove();
  }

  // --- TRANSAÇÕES ADICIONAIS ---

  Future<void> addManualTransaction(String targetUid, TransactionModel transaction) async {
    await _db.ref('users/$targetUid/transactions').push().set(transaction.toMap());
  }

  Future<List<TransactionModel>> getClientTransactionsOnce(String clientUid) async {
    final snapshot = await _db.ref('users/$clientUid/transactions').get();
    final List<TransactionModel> list = [];
    if (snapshot.exists && snapshot.value != null) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        list.add(TransactionModel.fromMap(key, Map<String, dynamic>.from(value)));
      });
    }
    return list;
  }

  // --- COBRANÇA NATIVA DE HONORÁRIOS BPO PELO APP ---

  Stream<Map<String, dynamic>?> getClientPendingBpoFee() async* {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      yield null;
      return;
    }
    
    await for (final profileEvent in _db.ref('users/$uid/profile').onValue) {
      final data = profileEvent.snapshot.value as Map? ?? {};
      final bpoUid = data['assignedBpoId']?.toString();
      if (bpoUid == null) {
        yield null;
        continue;
      }
      
      await for (final feeEvent in _db.ref('users/$bpoUid/bpo_fees/$uid').onValue) {
        final fee = feeEvent.snapshot.value as Map? ?? {};
        if (fee.isEmpty || fee['status'] == 'Pago') {
          yield null;
        } else {
          yield {
            ...Map<String, dynamic>.from(fee),
            'bpoUid': bpoUid,
          };
        }
      }
    }
  }

  Future<String> getBpoPixKey(String bpoUid) async {
    final snap = await _db.ref('users/$bpoUid/pix_key').get();
    return (snap.value ?? '').toString();
  }

  Future<void> payBpoFee(String bpoUid, double amount, int dueDay) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    // 1. Atualizar status na visão do BPO
    await _db.ref('users/$bpoUid/bpo_fees/$uid/status').set('Pago');

    // 2. Registrar despesa local no caixa do cliente
    final clientTx = TransactionModel(
      id: '',
      amount: amount,
      category: 'Serviços Contábeis 🏢',
      description: 'Pagamento Honorários BPO',
      date: DateTime.now(),
      type: TransactionType.expense,
    );
    await _db.ref('users/$uid/transactions').push().set(clientTx.toMap());

    // 3. Registrar receita local no caixa do BPO
    final bpoTx = TransactionModel(
      id: '',
      amount: amount,
      category: 'Honorário BPO 💰',
      description: 'Recebimento Honorário: Cliente BPO',
      date: DateTime.now(),
      type: TransactionType.income,
    );
    await _db.ref('users/$bpoUid/transactions').push().set(bpoTx.toMap());
  }

  // --- METAS DE FATURAMENTO E MURAL DE RECADOS BPO ---

  Future<void> saveBpoClientRevenueGoal(String clientUid, double targetAmount) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    await _db.ref('users/$bpoUid/bpo_clients/$clientUid/revenue_goal').set(targetAmount);
  }

  Stream<double> getBpoClientRevenueGoal() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    
    final controller = StreamController<double>();
    _db.ref('users/$uid/profile/assignedBpoId').onValue.listen((event) {
      final bpoId = event.snapshot.value?.toString() ?? '';
      if (bpoId.isEmpty) {
        controller.add(0.0);
        return;
      }
      _db.ref('users/$bpoId/bpo_clients/$uid/revenue_goal').onValue.listen((goalEvent) {
        final val = double.tryParse(goalEvent.snapshot.value?.toString() ?? '0') ?? 0.0;
        controller.add(val);
      });
    });
    return controller.stream;
  }

  Future<void> sendBpoMessageToMural(String clientUid, String messageText) async {
    String? bpoUid = _auth.currentUser?.uid;
    if (bpoUid == null) return;
    
    final bpoSnap = await _db.ref('users/$bpoUid/profile').get();
    final bpoName = bpoSnap.exists && bpoSnap.value != null 
        ? (bpoSnap.value as Map)['name']?.toString() ?? 'Seu Contador BPO'
        : 'Seu Contador BPO';

    final ref = _db.ref('users/$clientUid/profile/bpo_messages').push();
    await ref.set({
      'id': ref.key,
      'message': messageText,
      'bpoName': bpoName,
      'bpoUid': bpoUid,
      'sentAt': ServerValue.timestamp,
      'isRead': false,
    });
  }

  Future<void> markBpoMessageAsRead(String messageId) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/profile/bpo_messages/$messageId/isRead').set(true);
  }

  Stream<List<Map<String, dynamic>>> getBpoMessagesForClient() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    
    return _db.ref('users/$uid/profile/bpo_messages').onValue.map((event) {
      final List<Map<String, dynamic>> list = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            if (map['isRead'] != true) {
              list.add(map);
            }
          }
        });
      }
      list.sort((a, b) {
        final tA = a['sentAt'] as num? ?? 0;
        final tB = b['sentAt'] as num? ?? 0;
        return tB.compareTo(tA);
      });
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> getBpoClientSentMessages(String clientUid) {
    return _db.ref('users/$clientUid/profile/bpo_messages').onValue.map((event) {
      final List<Map<String, dynamic>> list = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            list.add(Map<String, dynamic>.from(value));
          }
        });
      }
      list.sort((a, b) {
        final tA = a['sentAt'] as num? ?? 0;
        final tB = b['sentAt'] as num? ?? 0;
        return tB.compareTo(tA);
      });
      return list;
    });
  }

  // --- MÉTODOS DO PORTAL DO CONTADOR ---

  Stream<List<Map<String, dynamic>>> getContadorClients() {
    String? contadorUid = _auth.currentUser?.uid;
    if (contadorUid == null) return const Stream.empty();
    return _db.ref('users/$contadorUid/contador_clients').onValue.map((event) {
      final List<Map<String, dynamic>> list = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            map['id'] = key;
            list.add(map);
          }
        });
      }
      return list;
    });
  }

  Future<void> saveContadorClientNote(String clientUid, String note) async {
    String? contadorUid = _auth.currentUser?.uid;
    if (contadorUid == null) return;
    await _db.ref('users/$contadorUid/contador_clients/$clientUid/note').set(note);
  }

  Stream<String?> getContadorClientNote(String clientUid) {
    String? contadorUid = _auth.currentUser?.uid;
    if (contadorUid == null) return const Stream.empty();
    return _db.ref('users/$contadorUid/contador_clients/$clientUid/note').onValue.map(
      (event) => event.snapshot.value?.toString(),
    );
  }

  Future<void> setContadorMessage(String clientUid, String message) async {
    String? contadorUid = _auth.currentUser?.uid;
    if (contadorUid == null) return;
    
    final contSnap = await _db.ref('users/$contadorUid/profile').get();
    final contName = contSnap.exists && contSnap.value != null 
        ? (contSnap.value as Map)['name']?.toString() ?? 'Seu Contador'
        : 'Seu Contador';
        
    await _db.ref('users/$clientUid/profile/contador_message').set({
      'contadorName': contName,
      'message': message,
      'sentAt': ServerValue.timestamp,
    });
  }

  Stream<Map<String, dynamic>?> getContadorMessageForClient() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('users/$uid/profile/contador_message').onValue.map((event) {
      final val = event.snapshot.value;
      if (val is Map) return Map<String, dynamic>.from(val);
      return null;
    });
  }

  Future<void> toggleTransactionTaxAudit(String clientUid, String txId, bool isAudited) async {
    await _db.ref('users/$clientUid/transactions/$txId/auditedByContador').set(isAudited);
  }

  Future<bool> linkAccountant(String accountantUid) async {
    String? clientUid = _auth.currentUser?.uid;
    if (clientUid == null || accountantUid.isEmpty) return false;

    // 1. Validar se o UID corresponde a um Contador Parceiro
    final profileSnap = await _db.ref('users/$accountantUid/profile').get();
    if (!profileSnap.exists || profileSnap.value == null) return false;

    final profileMap = Map<String, dynamic>.from(profileSnap.value as Map);
    final niche = profileMap['niche']?.toString();
    if (niche != 'contador') return false;

    // 2. Obter dados do cliente
    final clientSnap = await _db.ref('users/$clientUid/profile').get();
    String clientName = 'Cliente';
    String clientEmail = '';
    if (clientSnap.exists && clientSnap.value != null) {
      final clientMap = Map<String, dynamic>.from(clientSnap.value as Map);
      clientName = clientMap['name']?.toString() ?? 'Cliente';
      clientEmail = clientMap['email']?.toString() ?? '';
    }

    // 3. Registrar o vínculo bi-direcional no RTDB
    await _db.ref('users/$accountantUid/contador_clients/$clientUid').set({
      'name': clientName,
      'email': clientEmail,
      'linkedAt': ServerValue.timestamp,
    });

    await _db.ref('users/$clientUid/profile/contadorUid').set(accountantUid);
    return true;
  }

  Future<void> unlinkAccountant() async {
    String? clientUid = _auth.currentUser?.uid;
    if (clientUid == null) return;

    final contadorUidSnap = await _db.ref('users/$clientUid/profile/contadorUid').get();
    final String? contadorUid = contadorUidSnap.value?.toString();

    if (contadorUid != null && contadorUid.isNotEmpty) {
      await _db.ref('users/$contadorUid/contador_clients/$clientUid').remove();
    }

    await _db.ref('users/$clientUid/profile/contadorUid').remove();
  }

  Stream<Map<String, dynamic>?> getLinkedAccountant() {
    String? clientUid = _auth.currentUser?.uid;
    if (clientUid == null) return const Stream.empty();

    return _db.ref('users/$clientUid/profile/contadorUid').onValue.asyncMap((event) async {
      final String? contadorUid = event.snapshot.value?.toString();
      if (contadorUid == null || contadorUid.isEmpty) return null;

      final snap = await _db.ref('users/$contadorUid/profile').get();
      if (snap.exists && snap.value != null) {
        final map = Map<String, dynamic>.from(snap.value as Map);
        map['uid'] = contadorUid;
        return map;
      }
      return {'uid': contadorUid, 'name': 'Contador Parceiro', 'email': 'Vínculo Ativo'};
    });
  }

  Future<void> clearContadorMessage() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/profile/contador_message').remove();
  }

  // --- MÉTODOS DE PORTFÓLIO PÚBLICO INTEGRADO ---

  Future<bool> savePortfolioProfile(Map<String, dynamic> profile) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final String slug = profile['slug']?.toString().trim().replaceAll(' ', '-') ?? '';
    if (slug.isEmpty) return false;

    // 1. Verificar se o slug já está em uso por outro usuário
    final slugCheckSnap = await _db.ref('portfolio_slugs/$slug').get();
    if (slugCheckSnap.exists && slugCheckSnap.value.toString() != uid) {
      return false; // Slug ocupado
    }

    // 2. Remover slug antigo se houver
    final oldProfileSnap = await _db.ref('users/$uid/portfolio_profile/slug').get();
    final String? oldSlug = oldProfileSnap.value?.toString();
    if (oldSlug != null && oldSlug != slug) {
      await _db.ref('portfolio_slugs/$oldSlug').remove();
    }

    // 3. Salvar perfil e mapeamento global
    await _db.ref('users/$uid/portfolio_profile').set(profile);
    await _db.ref('portfolio_slugs/$slug').set(uid);
    return true;
  }

  Stream<Map<String, dynamic>?> getPortfolioProfile() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.ref('users/$uid/portfolio_profile').onValue.map((event) {
      final val = event.snapshot.value;
      if (val is Map) return Map<String, dynamic>.from(val);
      return null;
    });
  }

  Future<void> addPortfolioProject(Map<String, dynamic> project) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _db.ref('users/$uid/portfolio_projects').push();
    final String id = ref.key!;
    await ref.set({
      ...project,
      'id': id,
      'createdAt': ServerValue.timestamp,
    });
  }

  Stream<List<Map<String, dynamic>>> getPortfolioProjects(String uid) {
    return _db.ref('users/$uid/portfolio_projects').onValue.map((event) {
      final List<Map<String, dynamic>> list = [];
      final val = event.snapshot.value as Map<dynamic, dynamic>?;
      if (val != null) {
        val.forEach((key, value) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            map['id'] = key;
            list.add(map);
          }
        });
      }
      list.sort((a, b) {
        final String dA = a['date'] ?? '';
        final String dB = b['date'] ?? '';
        return dB.compareTo(dA);
      });
      return list;
    });
  }

  Future<Map<String, dynamic>?> getPublicPortfolioBySlug(String slug) async {
    final slugSnap = await _db.ref('portfolio_slugs/$slug').get();
    if (!slugSnap.exists || slugSnap.value == null) return null;

    final String uid = slugSnap.value.toString();
    final profileSnap = await _db.ref('users/$uid/portfolio_profile').get();
    if (!profileSnap.exists || profileSnap.value == null) return null;

    final profileMap = Map<String, dynamic>.from(profileSnap.value as Map);

    final projectsSnap = await _db.ref('users/$uid/portfolio_projects').get();
    final List<Map<String, dynamic>> projectsList = [];
    if (projectsSnap.exists && projectsSnap.value != null) {
      final val = projectsSnap.value as Map<dynamic, dynamic>;
      val.forEach((key, value) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          map['id'] = key;
          projectsList.add(map);
        }
      });
    }

    projectsList.sort((a, b) {
      final String dA = a['date'] ?? '';
      final String dB = b['date'] ?? '';
      return dB.compareTo(dA);
    });

    return {
      'uid': uid,
      'profile': profileMap,
      'projects': projectsList,
    };
  }

  Future<void> deletePortfolioProject(String projectId) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/portfolio_projects/$projectId').remove();
  }

  Future<void> saveProposal(String id, Map<String, dynamic> proposalData) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/proposals/$id').set(proposalData);
  }

  Future<Map<String, dynamic>?> getProposals() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snapshot = await _db.ref('users/$uid/proposals').get();
    if (!snapshot.exists) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  Future<void> deleteProposal(String id) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.ref('users/$uid/proposals/$id').remove();
  }

  // --- BUSINESS GOALS CONTROLLER ---
  Future<void> saveBusinessGoal(String id, Map<String, dynamic> data) async {
    await _db.ref('$_rootPath/businessGoals/$id').set(data);
  }

  Future<void> deleteBusinessGoal(String id) async {
    await _db.ref('$_rootPath/businessGoals/$id').remove();
  }

  Future<Map<String, dynamic>?> getBusinessGoals() async {
    final snapshot = await _db.ref('$_rootPath/businessGoals').get();
    if (!snapshot.exists) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }
}
