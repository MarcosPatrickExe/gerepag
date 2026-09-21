import 'package:flutter/material.dart';
import '../../../providers/transactions_provider.dart';
import '../../../screens/home_screen.dart';

class AppBottomNavBar extends StatelessWidget {
  final TransactionsProvider provider;
  final DashboardType currentDashboard;
  final Function(DashboardType) onDashboardChanged;

  const AppBottomNavBar({
    super.key,
    required this.provider,
    required this.currentDashboard,
    required this.onDashboardChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: BottomNavigationBar(
        currentIndex: _getDashboardIndex(currentDashboard, provider.isBusinessMode),
        onTap: (index) => onDashboardChanged(_getDashboardTypeFromIndex(index, provider.isBusinessMode)),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        items: _getAvailableDashboards(provider.isBusinessMode).map((type) {
          return BottomNavigationBarItem(
            icon: Icon(_getIconForType(type)),
            label: _getLabelForType(type),
          );
        }).toList(),
      ),
    );
  }

  int _getDashboardIndex(DashboardType type, bool isBusiness) {
    final available = _getAvailableDashboards(isBusiness);
    final idx = available.indexOf(type);
    return idx != -1 ? idx : 0;
  }

  DashboardType _getDashboardTypeFromIndex(int index, bool isBusiness) {
    return _getAvailableDashboards(isBusiness)[index];
  }

  List<DashboardType> _getAvailableDashboards(bool isBusiness) {
    if (isBusiness) {
      return [DashboardType.summary, DashboardType.forecast, DashboardType.dre, DashboardType.os, DashboardType.map];
    } else {
      return [DashboardType.summary, DashboardType.wallets, DashboardType.creditCards, DashboardType.budget, DashboardType.installments];
    }
  }

  IconData _getIconForType(DashboardType type) {
    switch (type) {
      case DashboardType.summary: return Icons.dashboard_rounded;
      case DashboardType.forecast: return Icons.trending_up;
      case DashboardType.dre: return Icons.analytics;
      case DashboardType.os: return Icons.view_kanban;
      case DashboardType.map: return Icons.map;
      case DashboardType.wallets: return Icons.account_balance_wallet;
      case DashboardType.creditCards: return Icons.credit_card;
      case DashboardType.budget: return Icons.pie_chart;
      case DashboardType.installments: return Icons.calendar_month;
      default: return Icons.circle;
    }
  }

  String _getLabelForType(DashboardType type) {
    switch (type) {
      case DashboardType.summary: return 'Home';
      case DashboardType.forecast: return 'Projeção';
      case DashboardType.dre: return 'DRE';
      case DashboardType.os: return 'Kanban';
      case DashboardType.map: return 'Mapa';
      case DashboardType.wallets: return 'Contas';
      case DashboardType.creditCards: return 'Cartões';
      case DashboardType.budget: return 'Metas';
      case DashboardType.installments: return 'Parcelas';
      default: return '';
    }
  }
}
