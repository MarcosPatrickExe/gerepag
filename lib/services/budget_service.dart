import 'package:flutter/material.dart';
import 'realtime_db_service.dart';

class BudgetService extends ChangeNotifier {
  final RealtimeDbService _realtimeService = RealtimeDbService();
  Map<String, double> _budgets = {};

  BudgetService() {
    _init();
  }

  void _init() {
    _realtimeService.getBudgets().listen((data) {
      _budgets = data;
      notifyListeners();
    });
  }

  Map<String, double> get budgets => _budgets;

  Future<void> setBudget(String category, double amount) async {
    await _realtimeService.setBudget(category, amount);
  }

  Future<void> deleteBudget(String category) async {
    await _realtimeService.deleteBudget(category);
  }

  double getProgress(String category, double currentSpent) {
    final limit = _budgets[category] ?? 0.0;
    if (limit == 0) return 0.0;
    return currentSpent / limit;
  }

  bool isOverBudget(String category, double currentSpent) {
    final limit = _budgets[category] ?? 0.0;
    if (limit == 0) return false;
    return currentSpent >= limit;
  }

  bool isNearLimit(String category, double currentSpent) {
    final limit = _budgets[category] ?? 0.0;
    if (limit == 0) return false;
    return currentSpent >= (limit * 0.8); // 80% do limite
  }
}
