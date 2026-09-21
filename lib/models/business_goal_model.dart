import 'package:flutter/material.dart';

enum BusinessGoalType { annual, semestral, quarterly, monthly }
enum BusinessMetricType { 
  grossRevenue, 
  taxes, 
  costs, 
  grossResult, 
  expenses, 
  ebitda, 
  netIncome, 
  avgPaymentTerm, 
  avgReceiptTerm, 
  delinquencyRate 
}

class BusinessGoalModel {
  final String id;
  final String title;
  final BusinessGoalType type;
  final int year;
  final int? month;
  final Map<BusinessMetricType, double> targets;
  final String? projectId;
  final String? departmentId;
  final String? clientId;
  final String? supplierId;

  BusinessGoalModel({
    required this.id,
    required this.title,
    required this.type,
    required this.year,
    this.month,
    required this.targets,
    this.projectId,
    this.departmentId,
    this.clientId,
    this.supplierId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type.name,
      'year': year,
      'month': month,
      'targets': targets.map((k, v) => MapEntry(k.name, v)),
      'projectId': projectId,
      'departmentId': departmentId,
      'clientId': clientId,
      'supplierId': supplierId,
    };
  }

  factory BusinessGoalModel.fromMap(String id, Map<String, dynamic> map) {
    return BusinessGoalModel(
      id: id,
      title: map['title'] ?? '',
      type: BusinessGoalType.values.firstWhere((e) => e.name == map['type'], orElse: () => BusinessGoalType.monthly),
      year: map['year'] ?? DateTime.now().year,
      month: map['month'],
      targets: (map['targets'] as Map? ?? {}).map((k, v) => MapEntry(
        BusinessMetricType.values.firstWhere((e) => e.name == k),
        (v as num).toDouble(),
      )),
      projectId: map['projectId'],
      departmentId: map['departmentId'],
      clientId: map['clientId'],
      supplierId: map['supplierId'],
    );
  }
}
