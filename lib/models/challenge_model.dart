import 'package:flutter/material.dart';

class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final double progress;
  final int rewardXp;
  final String colorHex;
  final bool isCompleted;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.progress = 0.0,
    this.rewardXp = 100,
    this.colorHex = '#2196F3', // Default blue
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'progress': progress,
      'rewardXp': rewardXp,
      'colorHex': colorHex,
      'isCompleted': isCompleted,
    };
  }

  factory ChallengeModel.fromMap(Map<String, dynamic> map, String id) {
    return ChallengeModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🎯',
      progress: (map['progress'] ?? 0.0).toDouble(),
      rewardXp: map['rewardXp'] ?? 100,
      colorHex: map['colorHex'] ?? '#2196F3',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
}
