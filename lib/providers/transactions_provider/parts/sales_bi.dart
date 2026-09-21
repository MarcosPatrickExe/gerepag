part of '../../transactions_provider.dart';

extension TransactionsProviderSalesBI on TransactionsProvider {
  
  // --- CURVA ABC DE PRODUTOS ---
  
  List<Map<String, dynamic>> get abcCurveProducts {
    if (_biCache.containsKey('abcCurveProducts')) return _biCache['abcCurveProducts'];

    final Map<String, double> sales = {};
    double totalSales = 0;

    for (var order in _omieOrders) {
      final itens = order['det'] ?? [];
      for (var item in itens) {
        final prodName = item['prod']?['descricao']?.toString() ?? 'Produto Indefinido';
        final total = double.tryParse(item['prod']?['valor_total']?.toString() ?? '0') ?? 0;
        sales[prodName] = (sales[prodName] ?? 0) + total;
        totalSales += total;
      }
    }

    final sorted = sales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    double cumulative = 0;
    final result = sorted.map((e) {
      cumulative += e.value;
      final percent = totalSales > 0 ? (e.value / totalSales) * 100 : 0.0;
      final cumPercent = totalSales > 0 ? (cumulative / totalSales) * 100 : 0.0;
      
      String classification = 'C';
      if (cumPercent <= 80) classification = 'A';
      else if (cumPercent <= 95) classification = 'B';

      return {
        'name': e.key,
        'value': e.value,
        'percent': percent,
        'cumPercent': cumPercent,
        'class': classification,
      };
    }).toList();

    _biCache['abcCurveProducts'] = result;
    return result;
  }

  // --- ANALISE RFV (RECENCIA, FREQUENCIA, VALOR) ---

  List<Map<String, dynamic>> get rfvAnalysis {
    if (_biCache.containsKey('rfvAnalysis')) return _biCache['rfvAnalysis'];

    final Map<String, Map<String, dynamic>> clientStats = {};

    for (var x in _omieAccountsReceivable) {
      final clientId = x['codigo_cliente_fornecedor'].toString();
      final clientName = _omieClients[clientId] ?? 'Cliente $clientId';
      final date = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
      final amount = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;

      if (!clientStats.containsKey(clientId)) {
        clientStats[clientId] = {
          'name': clientName,
          'lastDate': date,
          'frequency': 0,
          'totalValue': 0.0,
        };
      }

      final stats = clientStats[clientId]!;
      if (date.isAfter(stats['lastDate'])) stats['lastDate'] = date;
      stats['frequency'] += 1;
      stats['totalValue'] += amount;
    }

    final now = DateTime.now();
    final result = clientStats.values.map((s) {
      final recencyDays = now.difference(s['lastDate']).inDays;
      
      // Scores simplificados (1 a 5)
      int rScore = recencyDays <= 30 ? 5 : (recencyDays <= 90 ? 4 : (recencyDays <= 180 ? 3 : (recencyDays <= 365 ? 2 : 1)));
      int fScore = s['frequency'] >= 10 ? 5 : (s['frequency'] >= 5 ? 4 : (s['frequency'] >= 3 ? 3 : (s['frequency'] >= 2 ? 2 : 1)));
      int vScore = s['totalValue'] >= 10000 ? 5 : (s['totalValue'] >= 5000 ? 4 : (s['totalValue'] >= 2000 ? 3 : (s['totalValue'] >= 1000 ? 2 : 1)));

      String segment = 'Inativo';
      if (rScore >= 4 && fScore >= 4) segment = 'Campeão';
      else if (rScore >= 3 && fScore >= 3) segment = 'Fiel';
      else if (rScore >= 4) segment = 'Novo';
      else if (rScore <= 2) segment = 'Em Risco';

      return {
        'name': s['name'],
        'lastDate': s['lastDate'],
        'frequency': s['frequency'],
        'totalValue': s['totalValue'],
        'recency': recencyDays,
        'rScore': rScore,
        'fScore': fScore,
        'vScore': vScore,
        'segment': segment,
      };
    }).toList();

    _biCache['rfvAnalysis'] = result;
    return result;
  }

  // --- ANÁLISE DE COMISSÕES REAL ---
  
  List<Map<String, dynamic>> get commissionAnalysis {
    final Map<String, double> salesByVendor = {};
    const double commissionRate = 0.03; // 3% de comissão padrão

    // 1. Processar Pedidos de Venda
    for (var order in _omieOrders) {
      final cab = order['cabecalho'] ?? order['Cabecalho'] ?? {};
      final vendorName = cab['cNomeVendedor'] ?? 
                         cab['cContato'] ?? 
                         cab['cCodVendedor']?.toString() ?? 
                         (_omieClients[cab['nCodVend']?.toString()] ?? 'Vendedor Omie');
      final total = double.tryParse(cab['valor_total']?.toString() ?? '0') ?? 0;
      salesByVendor[vendorName] = (salesByVendor[vendorName] ?? 0) + total;
    }

    // 2. Processar Ordens de Serviço (OS)
    for (var os in _omieOS) {
      final cab = os['Cabecalho'] ?? os['cabecalho'] ?? {};
      final vendorName = cab['cNomeVendedor'] ?? cab['cEmailVendedor'] ?? 'Vendedor OS';
      final total = double.tryParse(cab['vlrTotalOS']?.toString() ?? '0') ?? 0;
      salesByVendor[vendorName] = (salesByVendor[vendorName] ?? 0) + total;
    }

    if (salesByVendor.isEmpty) return [];

    return salesByVendor.entries.map((e) {
      return {
        'vendor': e.key,
        'totalSales': e.value,
        'commission': e.value * commissionRate,
        'rate': commissionRate * 100,
      };
    }).toList()..sort((a, b) => (b['totalSales'] as double).compareTo(a['totalSales'] as double));
  }
}
