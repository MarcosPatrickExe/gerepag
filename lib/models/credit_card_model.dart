class CreditCardModel {
  final String id;
  final String name;
  final double limit;
  final int closingDay;
  final int dueDay;
  final String colorHex;

  CreditCardModel({
    required this.id,
    required this.name,
    required this.limit,
    required this.closingDay,
    required this.dueDay,
    this.colorHex = '#8B0000', // Padrão: Vermelho escuro
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'limit': limit,
      'closingDay': closingDay,
      'dueDay': dueDay,
      'colorHex': colorHex,
    };
  }

  factory CreditCardModel.fromMap(String id, Map<String, dynamic> map) {
    return CreditCardModel(
      id: id,
      name: map['name'] ?? 'Cartão',
      limit: (map['limit'] as num?)?.toDouble() ?? 0.0,
      closingDay: map['closingDay'] ?? 1,
      dueDay: map['dueDay'] ?? 10,
      colorHex: map['colorHex'] ?? '#8B0000',
    );
  }
}
