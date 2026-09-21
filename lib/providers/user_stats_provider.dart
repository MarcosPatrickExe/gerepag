import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/badge_model.dart';
import '../models/mission_model.dart';
import '../services/widget_service.dart';
import '../services/realtime_db_service.dart';

class UserStatsProvider with ChangeNotifier {
  int _xp = 0;
  int _level = 1;
  int _streak = 0;
  List<BadgeModel> _systemBadges = [];
  List<MissionModel> _dailyMissions = [];
  final RealtimeDbService _db = RealtimeDbService();

  int get xp => _xp;
  int get level => _level;
  int get streak => _streak;
  List<BadgeModel> get badges => _systemBadges;
  List<MissionModel> get dailyMissions => _dailyMissions;

  String get levelTitle {
    if (_level >= 20) return 'Lenda das Finanças 👑';
    if (_level >= 15) return 'Mestre Financeiro 💎';
    if (_level >= 10) return 'Estrategista Senior 📈';
    if (_level >= 5) return 'Analista Próspero 👔';
    return 'Estagiário do Dinheiro 🌱';
  }

  double get progressToNextLevel => (_xp % 1000) / 1000;
  int get xpToNextLevel => 1000 - (_xp % 1000);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar se mudou o mês (Temporada)
    final lastSeasonDay = prefs.getString('last_season_reset') ?? '';
    final now = DateTime.now();
    final currentSeasonKey = '${now.year}-${now.month}';

    if (lastSeasonDay != currentSeasonKey) {
      _xp = 0; // Reset de temporada
      _level = 1;
      await prefs.setString('last_season_reset', currentSeasonKey);
    } else {
      _xp = prefs.getInt('user_xp') ?? 0;
      _level = (_xp / 1000).floor() + 1;
    }

    _streak = prefs.getInt('user_streak') ?? 0;
    _loadBadges();
    _initMissions();
    WidgetService.updateStats(_level, _xp);
    notifyListeners();
  }

  void _initMissions() {
    // Missões fixas por enquanto (exemplo do usuário)
    _dailyMissions = [
      MissionModel(
        id: 'mission_ifood',
        title: 'Zero Ifood hoje 🍔',
        description: 'Não gaste com aplicativos de comida hoje.',
        rewardXp: 50,
        keywordFilter: 'ifood',
        categoryFilter: 'Alimentação',
      ),
      MissionModel(
        id: 'mission_coffee',
        title: 'Cafézinho em Casa ☕',
        description: 'Evite gastos em padarias ou cafeterias.',
        rewardXp: 30,
        categoryFilter: 'Lazer',
      ),
      MissionModel(
        id: 'mission_radar',
        title: 'Sobrevivência Máxima 🎯',
        description: 'Termine o dia com sobra no Radar de Sobrevivência.',
        rewardXp: 100,
      ),
    ];
  }

  void _loadBadges() {
    if (Firebase.apps.isEmpty) return;
    
    _db.getUnlockedBadges().listen((unlocked) {
      _systemBadges = systemBadges.map((badge) {
        if (unlocked.containsKey(badge.id)) {
          return BadgeModel(
            id: badge.id,
            title: badge.title,
            description: badge.description,
            icon: badge.icon,
            unlockedAt: unlocked[badge.id],
          );
        }
        return badge;
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addXp(int amount) async {
    _xp += amount;
    _level = (_xp / 1000).floor() + 1;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_xp', _xp);
    WidgetService.updateStats(_level, _xp);
    notifyListeners();
  }

  // Nova lógica: Sobrevivência ao Radar
  Future<void> reportRadarSurvival(bool survived) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastReportDate = prefs.getString('last_radar_report') ?? '';

    if (lastReportDate != today) {
      if (survived) {
        _streak++;
        await addXp(100); // Bônus por sobreviver ao dia
        
        // Completar missão do radar se ativa
        final missionIdx = _dailyMissions.indexWhere((m) => m.id == 'mission_radar');
        if (missionIdx != -1 && _dailyMissions[missionIdx].status == MissionStatus.pending) {
          _dailyMissions[missionIdx] = _dailyMissions[missionIdx].copyWith(status: MissionStatus.completed);
          await addXp(_dailyMissions[missionIdx].rewardXp);
        }

        if (_streak >= 3) _db.unlockBadge('survivor_3');
        if (_streak >= 7) _db.unlockBadge('survivor_7');
      } else {
        _streak = 0; // Perdeu o streak
        
        final missionIdx = _dailyMissions.indexWhere((m) => m.id == 'mission_radar');
        if (missionIdx != -1) {
          _dailyMissions[missionIdx] = _dailyMissions[missionIdx].copyWith(status: MissionStatus.failed);
        }
      }
      
      await prefs.setInt('user_streak', _streak);
      await prefs.setString('last_radar_report', today);
      notifyListeners();
    }
  }

  void processTransaction(TransactionModel t, int totalTransactions, bool isPremium) {
    // Verificar missões "negativas" (não gastar com X)
    for (int i = 0; i < _dailyMissions.length; i++) {
      final mission = _dailyMissions[i];
      if (mission.status != MissionStatus.pending) continue;

      bool failed = false;
      if (mission.keywordFilter != null && t.description.toLowerCase().contains(mission.keywordFilter!.toLowerCase())) {
        failed = true;
      }
      if (mission.categoryFilter.isNotEmpty && t.category.contains(mission.categoryFilter)) {
        failed = true;
      }

      if (failed) {
        _dailyMissions[i] = mission.copyWith(status: MissionStatus.failed);
      }
    }

    int points = (t.amount.abs() / 10).floor();
    if (points > 0) {
      addXp(points);
    }

    if (totalTransactions >= 5) _db.unlockBadge('organized');
    if (isPremium) _db.unlockBadge('premium_user');
    notifyListeners();
  }

  // Método para reportar cancelamento de assinatura
  void reportSubscriptionDeleted() {
    _db.unlockBadge('subscription_hunter');
    addXp(200); // Bônus alto por economia real
    notifyListeners();
  }

  // Verificar se fechou o mês no azul para o Mestre do Caixa
  void checkMonthlyPerformance(double balance, int positiveMonthsStreak) {
    if (balance > 0 && positiveMonthsStreak >= 3) {
      _db.unlockBadge('cash_master_3');
    }
  }

  void recordDailyLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastLogin = prefs.getString('last_login_date') ?? '';

    if (lastLogin != today) {
      // O login diário agora dá XP, mas o streak é do Radar
      await prefs.setString('last_login_date', today);
      await addXp(50); 
      notifyListeners();
    }
  }
}
