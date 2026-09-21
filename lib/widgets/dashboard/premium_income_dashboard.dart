import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/transactions_provider.dart';
import 'omie/omie_shared_components.dart';
import 'omie/omie_expense_donut.dart';

class PremiumIncomeDashboard extends StatelessWidget {
  final TransactionsProvider provider;

  const PremiumIncomeDashboard({
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
                        title: 'RECEITA POR CATEGORIA',
                        data: provider.incomeByCategoryRank,
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(height: 24),
                      OmieExpenseDonut(
                        provider: provider,
                        onCategoryTap: (cat) {},
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
                        title: 'EXTRATO DE RECEITAS',
                        items: provider.omieAccountsReceivable,
                        color: Colors.greenAccent,
                      ),
                    ],
                  ),
                ),
                if (isWide) ...[
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: RankingCard(
                      title: 'RECEITA POR CLIENTE',
                      data: provider.incomeByClientRank,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
