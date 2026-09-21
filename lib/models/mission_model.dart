import 'package:flutter/material.dart';

enum MissionStatus { pending, completed, failed }

class MissionModel {
  final String id;
  final String title;
  final String description;
  final int rewardXp;
  final MissionStatus status;
  final String categoryFilter; // ex: 'Alimentação'
  final String? keywordFilter; // ex: 'ifood'

  MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardXp,
    this.status = MissionStatus.pending,
    this.categoryFilter = '',
    this.keywordFilter,
  });

  MissionModel copyWith({MissionStatus? status}) {
    return MissionModel(
      id: id,
      title: title,
      description: description,
      rewardXp: rewardXp,
      status: status ?? this.status,
      categoryFilter: categoryFilter,
      keywordFilter: keywordFilter,
    );
  }
}
