import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_theme.dart';
import '../models/challenge_model.dart';
import '../services/realtime_db_service.dart';

class ChallengesSection extends StatelessWidget {
  const ChallengesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final db = RealtimeDbService();

    return StreamBuilder<List<ChallengeModel>>(
      stream: db.getChallenges(),
      builder: (context, snapshot) {
        final challenges = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('DESAFIOS DA SEMANA 🔥', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primary),
                  onPressed: () => _showChallengeDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (challenges.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Nenhum desafio ativo. Clique no + para criar!', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ),
              ),
            ...challenges.map((c) => _buildChallengeCard(context, c)).toList(),
          ],
        );
      }
    );
  }

  void _showChallengeDialog(BuildContext context, {ChallengeModel? challenge}) {
    final titleController = TextEditingController(text: challenge?.title);
    final descController = TextEditingController(text: challenge?.description);
    final iconController = TextEditingController(text: challenge?.icon ?? '🎯');
    final xpController = TextEditingController(text: challenge?.rewardXp.toString() ?? '100');
    final db = RealtimeDbService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(challenge == null ? 'Novo Desafio' : 'Editar Desafio', style: const TextStyle(color: AppTheme.primary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: AppTheme.inputDecoration('Título (ex: Sem Delivery)', Icons.title)),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: AppTheme.inputDecoration('Descrição', Icons.description)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: iconController, decoration: AppTheme.inputDecoration('Ícone', Icons.emoji_emotions))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: xpController, decoration: AppTheme.inputDecoration('Recompensa XP', Icons.bolt), keyboardType: TextInputType.number)),
                ],
              ),
              if (challenge != null && !challenge.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      final completed = ChallengeModel(
                        id: challenge.id,
                        title: challenge.title,
                        description: challenge.description,
                        icon: challenge.icon,
                        rewardXp: challenge.rewardXp,
                        progress: 1.0,
                        isCompleted: true,
                      );
                      db.updateChallenge(completed);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🎉 Desafio Concluído! +${challenge.rewardXp} XP'),
                          backgroundColor: AppTheme.income,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.income),
                    child: const Text('MARCAR COMO CONCLUÍDO'),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (challenge != null)
            TextButton(
              onPressed: () {
                db.deleteChallenge(challenge.id);
                Navigator.pop(context);
              },
              child: const Text('EXCLUIR', style: TextStyle(color: AppTheme.expense)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final newChallenge = ChallengeModel(
                id: challenge?.id ?? '',
                title: titleController.text,
                description: descController.text,
                icon: iconController.text,
                rewardXp: int.tryParse(xpController.text) ?? 100,
                progress: challenge?.progress ?? 0.0,
                isCompleted: challenge?.isCompleted ?? false,
              );
              if (challenge == null) {
                db.addChallenge(newChallenge);
              } else {
                db.updateChallenge(newChallenge);
              }
              Navigator.pop(context);
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, ChallengeModel c) {
    return GestureDetector(
      onLongPress: () => _showChallengeDialog(context, challenge: c),
      child: Opacity(
        opacity: c.isCompleted ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.isCompleted ? AppTheme.income.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.isCompleted ? AppTheme.income.withValues(alpha: 0.1) : c.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(c.isCompleted ? '✅' : c.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                        decoration: c.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(c.description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.progress,
                        minHeight: 6,
                        backgroundColor: (c.isCompleted ? AppTheme.income : c.color).withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(c.isCompleted ? AppTheme.income : c.color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text(
                    c.isCompleted ? 'FEITO' : '+${c.rewardXp} XP', 
                    style: TextStyle(
                      color: c.isCompleted ? AppTheme.income : c.color, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 10,
                    ),
                  ),
                  const Icon(Icons.more_vert, color: AppTheme.textMuted, size: 14),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideX(),
    );
  }
}
