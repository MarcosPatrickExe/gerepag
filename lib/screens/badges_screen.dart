import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/badge_model.dart';
import '../models/mission_model.dart';
import '../providers/user_stats_provider.dart';
import '../providers/transactions_provider.dart';
import '../services/realtime_db_service.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RealtimeDbService db = RealtimeDbService();
    final statsProvider = Provider.of<UserStatsProvider>(context);
    final transactionsProvider = Provider.of<TransactionsProvider>(context);
    final isBusiness = transactionsProvider.isBusinessMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBusiness ? 'Performance Corporativa' : 'Gamificação', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<Map<String, DateTime>>(
        stream: db.getUnlockedBadges(),
        builder: (context, snapshot) {
          final unlocked = snapshot.data ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildXpBar(statsProvider, isBusiness),
                const SizedBox(height: 32),
                
                Text(
                  isBusiness ? 'OBJETIVOS OPERACIONAIS 📈' : 'MISSÕES DO DIA 🕹️',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppTheme.primary),
                ),
                const SizedBox(height: 16),
                ...statsProvider.dailyMissions.map((m) => _MissionTile(mission: m, isBusiness: isBusiness)),
                
                const SizedBox(height: 40),
                Text(
                  isBusiness ? 'MÉTRICAS DE SUCESSO 🚀' : 'GALERIA DE TROFÉUS 🏆',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: systemBadges.length,
                  itemBuilder: (context, index) {
                    final template = systemBadges[index];
                    final isUnlocked = unlocked.containsKey(template.id);

                    return _BadgeCard(
                      badge: template,
                      isUnlocked: isUnlocked,
                      unlockedAt: unlocked[template.id],
                      isBusiness: isBusiness,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildXpBar(UserStatsProvider stats, bool isBusiness) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isBusiness ? 'Status de Eficiência' : stats.levelTitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(isBusiness ? 'Nível de Maturidade: ${stats.level}' : 'Nível ${stats.level}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ),
              Icon(isBusiness ? Icons.insights : Icons.stars, color: Colors.white, size: 32),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: stats.progressToNextLevel,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isBusiness ? 'Faltam ${stats.xpToNextLevel} pontos para a próxima graduação' : 'Faltam ${stats.xpToNextLevel} XP para o próximo nível',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final MissionModel mission;
  final bool isBusiness;
  const _MissionTile({required this.mission, required this.isBusiness});

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = mission.status == MissionStatus.completed;
    final bool isFailed = mission.status == MissionStatus.failed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? AppTheme.income.withValues(alpha: 0.3) : (isFailed ? AppTheme.expense.withValues(alpha: 0.3) : Colors.white10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : (isFailed ? Icons.cancel : Icons.radio_button_unchecked),
            color: isCompleted ? AppTheme.income : (isFailed ? AppTheme.expense : AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: (isCompleted || isFailed) ? TextDecoration.lineThrough : null,
                    color: (isCompleted || isFailed) ? AppTheme.textMuted : AppTheme.textBody,
                  ),
                ),
                Text(mission.description, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(
            isBusiness ? '+${mission.rewardXp} Pontos' : '+${mission.rewardXp} XP',
            style: TextStyle(fontWeight: FontWeight.bold, color: isFailed ? AppTheme.textMuted : AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool isBusiness;

  const _BadgeCard({
    required this.badge,
    required this.isUnlocked,
    required this.isBusiness,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? AppTheme.surface : AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUnlocked ? AppTheme.primary.withValues(alpha: 0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked ? AppTheme.primary.withValues(alpha: 0.1) : Colors.grey.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              badge.icon,
              size: 40,
              color: isUnlocked ? AppTheme.primary : AppTheme.textMuted.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.black : AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isUnlocked) ...[
            const Spacer(),
            Text(
              isBusiness ? 'CONQUISTADO' : 'CONQUISTADO', // Or change to something more corporate if needed
              style: const TextStyle(
                color: AppTheme.income,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
