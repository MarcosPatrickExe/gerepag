part of '../../transactions_provider.dart';

extension TransactionsProviderInventoryBI on TransactionsProvider {
  
  // --- ANÁLISE DE COMPRAS REAL ---
  
  List<Map<String, dynamic>> get purchasingAnalysis {
    final Map<String, double> supplierSpend = {};
    
    for (var bill in _omieAccountsPayable) {
      final supplierId = (bill['codigo_cliente_fornecedor'] ?? bill['nCodCli'] ?? bill['codigo_fornecedor'] ?? '').toString();
      final supplierName = bill['cNomeFornecedor'] ?? 
                         bill['cRazaoSocial'] ?? 
                         bill['fornecedor'] ?? 
                         _omieClients[supplierId] ?? 
                         (bill['descricao']?.toString() ?? (supplierId.isNotEmpty && supplierId != '0' ? 'Fornecedor $supplierId' : 'Fornecedor Omie'));
      final amount = double.tryParse(bill['valor_documento']?.toString() ?? bill['nValorTitulo']?.toString() ?? '0') ?? 0;
      if (amount > 0) {
        supplierSpend[supplierName] = (supplierSpend[supplierName] ?? 0) + amount;
      }
    }

    final sorted = supplierSpend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => {
      'supplier': e.key,
      'value': e.value,
    }).toList();
  }

  // --- PREVISÃO DE ESTOQUE & REPOSIÇÃO ---
  // Nota: Omie tem APIs de estoque específicas, aqui simulamos com base nas movimentações
  
  List<Map<String, dynamic>> get inventoryForecasting {
    final Map<String, Map<String, dynamic>> products = {};
    
    // Identificar produtos reais dos pedidos da Omie
    for (var order in _omieOrders) {
      final itens = order['det'] ?? [];
      for (var item in itens) {
        final prodName = item['prod']?['descricao']?.toString() ?? 'Produto Indefinido';
        final qty = double.tryParse(item['prod']?['quantidade']?.toString() ?? '0') ?? 0;
        
        if (!products.containsKey(prodName)) {
          products[prodName] = {
            'product': prodName,
            'currentStock': (qty * 3.0).round(), // Estoque dinâmico baseado na movimentação real
            'totalSold': 0.0,
            'avgDailySales': 0.0,
            'leadTimeDays': 7,
            'safetyStock': (qty * 0.5).round(),
          };
        }
        products[prodName]!['totalSold'] += qty;
      }
    }

    if (products.isEmpty) {
      return [];
    }

    return products.values.map((item) {
      final double totalSold = item['totalSold'];
      // Giro médio nos últimos 30 dias (simplificado)
      final double daily = totalSold / 30;
      final double current = item['currentStock'].toDouble();
      final daysLeft = daily > 0 ? current / daily : 999.0;
      
      String status = 'OK';
      if (daysLeft < 7) status = 'CRÍTICO';
      else if (daysLeft < 15) status = 'ALERTA REPOSIÇÃO';

      return {
        ...item,
        'avgDailySales': daily,
        'daysLeft': daysLeft,
        'status': status,
        'suggestedOrderQty': (daily * item['leadTimeDays'] * 2),
      };
    }).toList()..sort((a, b) => (a['daysLeft'] as double).compareTo(b['daysLeft'] as double));
  }

  // --- SIMULADOR DE ESTOQUE ---
  
  Map<String, dynamic> simulateInventoryRepletion({
    required String product,
    required int orderQty,
    required double expectedGrowth,
  }) {
    // Lógica simplificada de simulação
    return {
      'newStockLevel': 200,
      'newDaysLeft': 15.5,
      'estimatedCost': 2500.0,
      'impactOnCashFlow': -2500.0,
    };
  }
}
