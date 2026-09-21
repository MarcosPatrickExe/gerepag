import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class AnalysisService {
  static String getQuickInsight(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return 'Comece a registrar para ganhar insights! 🚀';

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Filtrar transações dos últimos 7 dias
    final recentTransactions = transactions.where((t) => t.date.isAfter(sevenDaysAgo)).toList();
    if (recentTransactions.isEmpty) return 'Nenhuma atividade recente nos últimos 7 dias.';

    // Total gasto nos últimos 7 dias
    final totalSpentSevenDays = recentTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // Insight por categoria mais frequente
    final categories = recentTransactions.map((t) => t.category).toSet();
    String topCategory = '';
    double topAmount = 0;

    for (var cat in categories) {
      final catTotal = recentTransactions
          .where((t) => t.category == cat && t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      if (catTotal > topAmount) {
        topAmount = catTotal;
        topCategory = cat;
      }
    }

    if (topAmount > 0) {
      return 'Você gastou ${currency.format(topAmount)} em $topCategory esta semana. Fique de olho! 🧐';
    }

    return 'Seus gastos estão sob controle esta semana. Bom trabalho! ✅';
  }

  static List<double> getWeeklyData(List<TransactionModel> transactions) {
    // Retorna uma lista de 7 valores representando os gastos diários da última semana
    final now = DateTime.now();
    List<double> dailyData = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: i));
        dailyData[6 - i] = transactions
            .where((t) => t.type == TransactionType.expense && 
                          t.date.day == day.day && 
                          t.date.month == day.month && 
                          t.date.year == day.year)
            .fold(0.0, (sum, t) => sum + t.amount);
    }
    return dailyData;
  }
}
