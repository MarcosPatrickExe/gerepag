import 'package:flutter/material.dart';

enum GoalIcon {
  car(Icons.directions_car),
  house(Icons.home),
  travel(Icons.flight),
  savings(Icons.savings),
  phone(Icons.smartphone),
  other(Icons.stars);

  final IconData iconData;
  const GoalIcon(this.iconData);
}

class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final GoalIcon icon;
  final DateTime deadline;

  GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.icon = GoalIcon.other,
    required this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'icon': icon.name,
      'deadline': deadline.toIso8601String(),
    };
  }

  factory GoalModel.fromMap(String id, Map<String, dynamic> map) {
    return GoalModel(
      id: id,
      title: map['title'] ?? '',
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num).toDouble(),
      icon: GoalIcon.values.firstWhere(
        (e) => e.name == map['icon'],
        orElse: () => GoalIcon.other,
      ),
      deadline: DateTime.parse(map['deadline']),
    );
  }

  double get progress {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  bool get isReached => currentAmount >= targetAmount;
}
