part of '../../transactions_provider.dart';

extension TransactionsProviderBI on TransactionsProvider {
  // --- MOTOR DE DRE COMPARATIVO ---
  
  Map<String, Map<String, dynamic>> get omieDREComparison {
    final Map<String, Map<String, dynamic>> comparison = {
      'Receita': {},
      'Despesa': {},
    };

    final year1 = _selectedYear;
    final year2 = _selectedYear - 1; // Comparação com ano anterior por padrão

    void process(List<dynamic> list, String type) {
      for (var item in list) {
        final dt = _safeParseDate(item['data_vencimento'] ?? item['dDtVenc']);
        final val = double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0;
        final catName = _omieCategories[item['codigo_categoria']] ?? 'Outros';

        if (!comparison[type]!.containsKey(catName)) {
          comparison[type]![catName] = {'val1': 0.0, 'val2': 0.0};
        }

        if (dt.year == year1) {
          comparison[type]![catName]!['val1'] += val;
        } else if (dt.year == year2) {
          comparison[type]![catName]!['val2'] += val;
        }
      }
    }

    process(_omieAccountsReceivable, 'Receita');
    process(_omieAccountsPayable, 'Despesa');

    return comparison;
  }

  // --- MOTOR DE GEOLOCALIZAÇÃO ---

  Map<String, double> get incomeByCityRank {
    final Map<String, double> cityRank = {};
    for (var x in _omieAccountsReceivable) {
      if (!_isWithinCurrentFilter(_safeParseDate(x['data_vencimento'] ?? x['dDtVenc']))) continue;
      
      final clientData = _omieClients[x['codigo_cliente_fornecedor'].toString()] ?? '';
      final city = clientData.contains('|') ? clientData.split('|').last : 'Desconhecido';
      
      cityRank[city] = (cityRank[city] ?? 0) + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
    }
    return Map.fromEntries(cityRank.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  Map<String, double> get incomeByStateRank {
    final Map<String, double> stateRank = {};
    for (var x in _omieAccountsReceivable) {
      if (!_isWithinCurrentFilter(_safeParseDate(x['data_vencimento'] ?? x['dDtVenc']))) continue;
      
      final clientData = _omieClients[x['codigo_cliente_fornecedor'].toString()] ?? '';
      
      // Tenta extrair (UF) do formato "Cidade (UF)" ou "| UF"
      String? uf;
      final match = RegExp(r'\(([A-Z]{2})\)').firstMatch(clientData);
      if (match != null) {
        uf = match.group(1);
      } else if (clientData.contains('|')) {
        final parts = clientData.split('|');
        if (parts.length >= 3) {
          final loc = parts[2].trim(); // Formato: Nome | CPF | Cidade (UF)
          final ufMatch = RegExp(r'([A-Z]{2})$').firstMatch(loc);
          uf = ufMatch?.group(1);
        }
      }
      
      final finalUf = uf ?? '??';
      stateRank[finalUf] = (stateRank[finalUf] ?? 0) + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0);
    }
    return stateRank;
  }

  // --- MOTOR DE ANÁLISE POR PRODUTO ---

  Map<String, double> get scoreByProductRank {
    final Map<String, double> productRank = {};
    for (var order in _omieOrders) {
      final itens = order['det'] ?? [];
      for (var item in itens) {
        final prodName = item['prod']?['descricao']?.toString() ?? 'Produto Indefinido';
        final total = double.tryParse(item['prod']?['valor_total']?.toString() ?? '0') ?? 0;
        productRank[prodName] = (productRank[prodName] ?? 0) + total;
      }
    }
    return Map.fromEntries(productRank.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  // --- MOTOR DE ANÁLISE POR LOJA (PROJETO) ---

  Map<String, double> get resultByStoreRank {
    final Map<String, double> storeRank = {};
    
    // Receitas por Projeto
    for (var x in _omieAccountsReceivable) {
      final projId = x['codigo_projeto']?.toString() ?? '';
      if (projId.isEmpty) continue;
      final projName = _omieProjects[projId] ?? 'Loja $projId';
      final val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      storeRank[projName] = (storeRank[projName] ?? 0) + val;
    }

    // Despesas por Projeto (Subtraindo do resultado)
    for (var x in _omieAccountsPayable) {
      final projId = x['codigo_projeto']?.toString() ?? '';
      if (projId.isEmpty) continue;
      final projName = _omieProjects[projId] ?? 'Loja $projId';
      final val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      storeRank[projName] = (storeRank[projName] ?? 0) - val;
    }

    return Map.fromEntries(storeRank.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  // --- MOTOR DE DRE EM ÁRVORE (NÍVEIS 1, 2, 3) ---

  Map<String, DreNode> get omieDreTree {
    final Map<String, DreNode> rootNodes = {};

    void addToTree(String? catCode, double amount) {
      if (catCode == null || catCode.isEmpty) return;

      final parts = catCode.split('.');
      String currentPath = '';

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        currentPath = currentPath.isEmpty ? part : '$currentPath.$part';
        final int level = i + 1;

        if (level > 3) break; // Limitamos a 3 níveis conforme solicitado

        // Garantir que o nó existe na árvore
        DreNode? node;
        if (level == 1) {
          node = rootNodes[currentPath] ??= DreNode(
            code: currentPath,
            name: _omieCategories[currentPath] ?? 'Categoria $currentPath',
            level: 1,
          );
        } else {
          final parentPath = parts.getRange(0, i).join('.');
          final parentNode = _findNode(rootNodes, parentPath);
          if (parentNode != null) {
            node = parentNode.children[currentPath] ??= DreNode(
              code: currentPath,
              name: _omieCategories[currentPath] ?? 'Categoria $currentPath',
              level: level,
            );
          }
        }

        if (node != null) {
          node.total += amount;
        }
      }
    }

    // Processar Receitas (Positivas)
    for (var x in _omieAccountsReceivable) {
      if (!isWithinCurrentFilterDetailed(x)) continue;
      final val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      addToTree(x['codigo_categoria']?.toString(), val);
    }

    // Processar Despesas (Negativas para o resultado)
    for (var x in _omieAccountsPayable) {
      if (!isWithinCurrentFilterDetailed(x)) continue;
      final val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      addToTree(x['codigo_categoria']?.toString(), -val);
    }

    return rootNodes;
  }

  DreNode? _findNode(Map<String, DreNode> nodes, String targetPath) {
    if (nodes.containsKey(targetPath)) return nodes[targetPath];
    
    for (var node in nodes.values) {
      final found = _findNode(node.children, targetPath);
      if (found != null) return found;
    }
    return null;
  }
}

