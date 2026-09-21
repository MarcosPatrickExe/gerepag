class WalletModel {
  final String id;
  final String name;
  final double initialBalance;
  final String colorHex;
  final int iconCodePoint;

  WalletModel({
    required this.id,
    required this.name,
    this.initialBalance = 0.0,
    this.colorHex = '#1E3A8A', // Cor padrão
    this.iconCodePoint = 0xe040, // account_balance_wallet
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'initialBalance': initialBalance,
      'colorHex': colorHex,
      'iconCodePoint': iconCodePoint,
    };
  }

  factory WalletModel.fromMap(String id, Map<String, dynamic> map) {
    return WalletModel(
      id: id,
      name: map['name'] ?? 'Conta',
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
      colorHex: map['colorHex'] ?? '#1E3A8A',
      iconCodePoint: map['iconCodePoint'] ?? 0xe040,
    );
  }
}
