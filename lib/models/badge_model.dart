import 'package:flutter/material.dart';

class BadgeModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final DateTime? unlockedAt;

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory BadgeModel.fromMap(String id, Map<String, dynamic> map, BadgeModel template) {
    return BadgeModel(
      id: id,
      title: template.title,
      description: template.description,
      icon: template.icon,
      unlockedAt: map['unlockedAt'] != null ? DateTime.parse(map['unlockedAt']) : null,
    );
  }
}

// Lista estática de badges disponíveis no sistema
final List<BadgeModel> systemBadges = [
  BadgeModel(
    id: 'first_goal',
    title: 'Primeiro Passo',
    description: 'Criou sua primeira caixinha de sonhos.',
    icon: Icons.flag,
  ),
  BadgeModel(
    id: 'goal_reached',
    title: 'Realizador',
    description: 'Completou 100% de um objetivo!',
    icon: Icons.emoji_events,
  ),
  BadgeModel(
    id: 'organized',
    title: 'Organizado',
    description: 'Registrou suas primeiras 5 transações.',
    icon: Icons.checklist,
  ),
  BadgeModel(
    id: 'premium_user',
    title: 'Investidor Elite',
    description: 'Assinou o plano Premium.',
    icon: Icons.workspace_premium,
  ),
  BadgeModel(
    id: 'survivor_3',
    title: 'Sobrevivente Urbano',
    description: 'Ficou 3 dias seguidos dentro do limite do Radar.',
    icon: Icons.local_fire_department,
  ),
  BadgeModel(
    id: 'survivor_7',
    title: 'Mestre da Economia',
    description: 'Uma semana inteira dominando seus gastos!',
    icon: Icons.auto_awesome,
  ),
  BadgeModel(
    id: 'cash_master_3',
    title: 'Mestre do Caixa',
    description: 'Fechou 3 meses seguidos com saldo positivo.',
    icon: Icons.account_balance,
  ),
  BadgeModel(
    id: 'subscription_hunter',
    title: 'Caçador de Assinaturas',
    description: 'Cancelou um serviço recorrente desnecessário.',
    icon: Icons.content_cut,
  ),
];
