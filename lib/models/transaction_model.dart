enum TransactionType { expense, income }

class TransactionModel {
  final String id;
  final double amount;
  final String category;
  final String description; // Usamos como título/descrição
  final DateTime date;
  final TransactionType type;
  final String? accountId; // NOVO: Relacionamento com Wallet/Account
  
  // NOVO: Cartão de Crédito e Parcelamento
  final String? creditCardId;
  final int? currentInstallment;
  final int? totalInstallments;
  final bool auditedByContador; // Flag de Auditoria Fiscal

  String get title => description.isNotEmpty ? description : category;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    this.description = '',
    required this.date,
    required this.type,
    this.accountId,
    this.creditCardId,
    this.currentInstallment,
    this.totalInstallments,
    this.auditedByContador = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(), // RTDB prefere Strings para datas
      'type': type.name,
      'accountId': accountId,
      'creditCardId': creditCardId,
      'currentInstallment': currentInstallment,
      'totalInstallments': totalInstallments,
      'auditedByContador': auditedByContador,
    };
  }

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? 'Geral',
      description: map['description'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      accountId: map['accountId'],
      creditCardId: map['creditCardId'],
      currentInstallment: map['currentInstallment'],
      totalInstallments: map['totalInstallments'],
      auditedByContador: map['auditedByContador'] ?? false,
    );
  }
}
