import 'package:flutter/material.dart';
import '../../../providers/transactions_provider.dart';
import '../../../screens/home_screen.dart';
import '../../budget_dashboard_view.dart';
import '../premium_income_dashboard.dart';
import '../premium_expense_dashboard.dart';
import '../dre_matrix_dashboard.dart';
import '../comparison_dashboard.dart';
import '../geographic_dashboard.dart';
import '../os_kanban_board.dart';
import '../../../screens/crystal_ball_screen.dart';
import '../premium_summary_dashboard.dart';
import 'bpo_control_tower_view.dart';

class OmieBusinessDashboard extends StatelessWidget {
  final TransactionsProvider provider;
  final DashboardType currentDashboard;
  final VoidCallback onShowSyncCenter;
  final ValueChanged<DashboardType> onDashboardChanged;

  const OmieBusinessDashboard({
    super.key,
    required this.provider,
    required this.currentDashboard,
    required this.onShowSyncCenter,
    required this.onDashboardChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentDashboard) {
      case DashboardType.bpoTower:
        return BpoControlTowerView(
          onManageAccount: () => onDashboardChanged(DashboardType.summary),
        );
      case DashboardType.income:
        return PremiumIncomeDashboard(provider: provider);
      case DashboardType.expense:
        return PremiumExpenseDashboard(provider: provider);
      case DashboardType.dre:
        return DREMatrixDashboard(provider: provider);
      case DashboardType.comparison:
        return ComparisonDashboard(provider: provider);
      case DashboardType.map:
        return GeographicDashboard(provider: provider);
      case DashboardType.os:
        return OSKanbanBoard(provider: provider);
      case DashboardType.forecast:
        return CrystalBallScreen(provider: provider);
      case DashboardType.budget:
        return BudgetDashboardView();
      default:
        return PremiumSummaryDashboard(
          provider: provider,
          onShowSyncCenter: onShowSyncCenter,
        );
    }
  }
}
