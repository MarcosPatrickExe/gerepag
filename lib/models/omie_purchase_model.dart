class OmiePurchaseOrder {
  final String id;
  final String supplierName;
  final String category;
  final double requestedAmount;
  final double billedAmount;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String status; // requisitado, faturado, entregue

  OmiePurchaseOrder({
    required this.id,
    required this.supplierName,
    required this.category,
    required this.requestedAmount,
    required this.billedAmount,
    required this.orderDate,
    this.deliveryDate,
    required this.status,
  });

  double get priceVariance => billedAmount - requestedAmount;

  factory OmiePurchaseOrder.fromMap(Map<String, dynamic> map) {
    return OmiePurchaseOrder(
      id: map['nCodOrdem']?.toString() ?? map['id']?.toString() ?? '',
      supplierName: map['cNomeFornecedor'] ?? map['supplierName'] ?? 'Fornecedor N/A',
      category: map['cCategoria'] ?? map['category'] ?? 'Geral',
      requestedAmount: (map['nValorRequisitado'] ?? map['requestedAmount'] ?? 0.0).toDouble(),
      billedAmount: (map['nValorFaturado'] ?? map['billedAmount'] ?? 0.0).toDouble(),
      orderDate: map['dOrdem'] != null
          ? DateTime.tryParse(map['dOrdem']) ?? DateTime.now()
          : DateTime.now(),
      deliveryDate: map['dEntrega'] != null ? DateTime.tryParse(map['dEntrega']) : null,
      status: map['cStatus'] ?? map['status'] ?? 'faturado',
    );
  }
}

class OmieSupplierPerformance {
  final String supplierName;
  final double totalPurchases;
  final int leadTimeDays;
  final double onTimeDeliveryRate; // e.g. 95% = 95.0
  final double dpoDays; // Days Payable Outstanding

  OmieSupplierPerformance({
    required this.supplierName,
    required this.totalPurchases,
    required this.leadTimeDays,
    required this.onTimeDeliveryRate,
    required this.dpoDays,
  });
}
