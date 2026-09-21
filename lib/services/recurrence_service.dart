import '../models/transaction_model.dart';

class RecurringPattern {
  final String category;
  final double amount;
  final int averageDay;
  final int frequency; // Quantas vezes apareceu no histórico

  RecurringPattern({
    required this.category,
    required this.amount,
    required this.averageDay,
    required this.frequency,
  });
}

class RecurrenceService {
  static List<RecurringPattern> detectPatterns(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return [];

    final Map<String, List<TransactionModel>> groups = {};
    
    // Agrupar gastos por Categoria e Valor aproximado (margem de 5%)
    for (var t in transactions) {
      if (t.type != TransactionType.expense) continue;
      
      String key = '${t.category}_${(t.amount / 10).round() * 10}';
      groups.putIfAbsent(key, () => []).add(t);
    }

    final List<RecurringPattern> patterns = [];

    groups.forEach((key, list) {
      // Se aparecer 2 ou mais vezes, pode ser recorrente
      if (list.length >= 2) {
        // Calcular o dia médio do mês
        double totalDay = list.fold(0, (sum, t) => sum + t.date.day);
        int avgDay = (totalDay / list.length).round();
        
        patterns.add(RecurringPattern(
          category: list.first.category,
          amount: list.first.amount,
          averageDay: avgDay,
          frequency: list.length,
        ));
      }
    });

    return patterns;
  }
}
