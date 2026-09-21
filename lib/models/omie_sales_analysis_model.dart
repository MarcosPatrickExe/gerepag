enum AbcCategory { a, b, c }
enum RfvSegment { gold, silver, bronze }

class OmieProductSaleItem {
  final String id;
  final String productName;
  final String category;
  final double quantity;
  final double unitPrice;
  final double costPrice;
  final double totalRevenue;
  final String cfop;
  final String cnae;

  OmieProductSaleItem({
    required this.id,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    required this.totalRevenue,
    required this.cfop,
    required this.cnae,
  });

  double get marginAmount => totalRevenue - (costPrice * quantity);
  double get marginPercentage => totalRevenue > 0 ? (marginAmount / totalRevenue) * 100 : 0.0;
  double get markupPercentage => (costPrice * quantity) > 0 ? (marginAmount / (costPrice * quantity)) * 100 : 0.0;

  factory OmieProductSaleItem.fromMap(Map<String, dynamic> map) {
    final qty = (map['nQuantidade'] ?? map['quantity'] ?? 1.0).toDouble();
    final price = (map['nValorUnitario'] ?? map['unitPrice'] ?? 0.0).toDouble();
    final revenue = (map['nValorTotal'] ?? map['totalRevenue'] ?? (qty * price)).toDouble();
    final cost = (map['nPrecoCusto'] ?? map['costPrice'] ?? (price * 0.6)).toDouble();

    return OmieProductSaleItem(
      id: map['nCodProd']?.toString() ?? map['id']?.toString() ?? '',
      productName: map['cDescricao'] ?? map['productName'] ?? 'Produto N/A',
      category: map['cCategoria'] ?? map['category'] ?? 'Geral',
      quantity: qty,
      unitPrice: price,
      costPrice: cost,
      totalRevenue: revenue,
      cfop: map['cCFOP'] ?? map['cfop'] ?? '5102',
      cnae: map['cCNAE'] ?? map['cnae'] ?? 'Geral',
    );
  }
}

class OmieAbcItem {
  final String productName;
  final double revenue;
  final double cumulativePercentage;
  final AbcCategory category;

  OmieAbcItem({
    required this.productName,
    required this.revenue,
    required this.cumulativePercentage,
    required this.category,
  });
}

class OmieRfvClient {
  final String clientName;
  final int daysSinceLastPurchase; // Recência
  final int purchaseFrequency;     // Frequência
  final double totalSpent;          // Valor
  final RfvSegment segment;

  OmieRfvClient({
    required this.clientName,
    required this.daysSinceLastPurchase,
    required this.purchaseFrequency,
    required this.totalSpent,
    required this.segment,
  });
}

class OmieSellerCommission {
  final String sellerName;
  final double totalSales;
  final double commissionRate; // e.g. 5% = 0.05
  final double commissionAmount;

  OmieSellerCommission({
    required this.sellerName,
    required this.totalSales,
    required this.commissionRate,
    required this.commissionAmount,
  });
}
