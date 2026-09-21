import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/transactions_provider.dart';
import 'omie/omie_shared_components.dart';
import 'omie/omie_expense_donut.dart';

class PremiumExpenseDashboard extends StatelessWidget {
  final TransactionsProvider provider;

  const PremiumExpenseDashboard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 900;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      RankingCard(
                        title: 'DESPESAS POR CATEGORIA',
                        data: provider.expenseByCategoryRank,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 24),
                      OmieExpenseDonut(
                        provider: provider,
                        onCategoryTap: (cat) {}, // Empty callback for now
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      ExtratoTable(
                        title: 'EXTRATO DE DESPESAS',
                        items: provider.omieAccountsPayable,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
