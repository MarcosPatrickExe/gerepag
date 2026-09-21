import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/widgets.dart'; 
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class OmieService {
  final String appKey;
  final String appSecret;

  // Cache para evitar erro de "Consumo Redundante" da Omie
  Map<String, dynamic>? _lastSummary;
  DateTime? _lastFetchTime;

  OmieService({required this.appKey, required this.appSecret});

  static String get _baseUrl {
    if (kIsWeb || kReleaseMode) {
      return 'https://adm.gestaobi.com.br/proxy.php?endpoint=';
    }
    return 'https://app.omie.com.br/api/v1';
  }

  Future<http.Response?> _postWithRetry(Uri url, Map<String, dynamic> body, {int remainingRetries = 3}) async {
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) return response;

      final isBlocked = response.statusCode == 425 || 
                        (response.statusCode == 500 && (response.body.contains('REDUNDANT') || response.body.contains('MISUSE')));

      if (isBlocked && remainingRetries > 0) {
        final data = json.decode(response.body);
        final String faultString = data['faultstring'] ?? '';
        
        final RegExp regExp = RegExp(r'(\d+)\s+segundos');
        final match = regExp.firstMatch(faultString);
        
        int secondsToWait = 60; 
        if (match != null) {
          secondsToWait = int.parse(match.group(1)!) + 3;
        }
        
        print('⏳ [OMIE] API bloqueada. Aguardando $secondsToWait segundos (Restam $remainingRetries tentativas)...');
        await Future.delayed(Duration(seconds: secondsToWait));
        
        return _postWithRetry(url, body, remainingRetries: remainingRetries - 1);
      }

      return response;
    } catch (e) {
      print('🔥 [OMIE] Erro de conexão: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFinancialSummary() async {
    if (_lastSummary != null && _lastFetchTime != null) {
      final difference = DateTime.now().difference(_lastFetchTime!);
      if (difference.inSeconds < 60) return _lastSummary;
    }

    final url = Uri.parse('$_baseUrl/financas/resumo/');
    final body = {
      "call": "ObterResumoFinancas",
      "app_key": appKey,
      "app_secret": appSecret,
      "param": [{"dDia": DateFormat('dd/MM/yyyy').format(DateTime.now())}]
    };

    final response = await _postWithRetry(url, body);
    if (response != null && response.statusCode == 200) {
      _lastSummary = json.decode(response.body);
      _lastFetchTime = DateTime.now();
      return _lastSummary;
    }
    return null;
  }

  Future<List<dynamic>> listAccountsReceivable() async {
    List<dynamic> allItems = [];
    int currentPage = 1;
    int totalPages = 1;

    do {
      final url = Uri.parse('$_baseUrl/financas/contareceber/');
      final body = {
        "call": "ListarContasReceber",
        "app_key": appKey,
        "app_secret": appSecret,
        "param": [
          {
            "pagina": currentPage,
            "registros_por_pagina": 100,
            "apenas_importado_api": "N",
          }
        ]
      };

      final response = await _postWithRetry(url, body);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['conta_receber_cadastro'] ?? data['lista_contas_receber'] ?? [];
        allItems.addAll(list);
        totalPages = data['total_de_paginas'] ?? 1;
        currentPage++;
      } else {
        break;
      }
    } while (currentPage <= totalPages);

    print('✅ [OMIE DEBUG] Sucesso Receber: ${allItems.length} títulos encontrados.');
    return allItems;
  }

  Future<List<dynamic>> listAccountsPayable() async {
    List<dynamic> allItems = [];
    int currentPage = 1;
    int totalPages = 1;

    do {
      final url = Uri.parse('$_baseUrl/financas/contapagar/');
      final body = {
        "call": "ListarContasPagar",
        "app_key": appKey,
        "app_secret": appSecret,
        "param": [
          {
            "pagina": currentPage,
            "registros_por_pagina": 100,
            "apenas_importado_api": "N",
          }
        ]
      };

      final response = await _postWithRetry(url, body);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['conta_pagar_cadastro'] ?? [];
        allItems.addAll(list);
        totalPages = data['total_de_paginas'] ?? 1;
        currentPage++;
      } else {
        break;
      }
    } while (currentPage <= totalPages);

    print('✅ [OMIE DEBUG] Sucesso Pagar: ${allItems.length} títulos encontrados.');
    return allItems;
  }

  Future<Map<String, String>> listCategories() async {
    Map<String, String> categoryMap = {};
    int currentPage = 1;
    int totalPages = 1;

    do {
      final url = Uri.parse('$_baseUrl/geral/categorias/');
      final body = {
        "call": "ListarCategorias",
        "app_key": appKey,
        "app_secret": appSecret,
        "param": [{"pagina": currentPage, "registros_por_pagina": 100}]
      };

      final response = await _postWithRetry(url, body);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['categoria_cadastro'] ?? [];
        for (var item in list) {
          String code = item['codigo_categoria']?.toString() ?? item['codigo']?.toString() ?? '';
          String name = item['descricao']?.toString() ?? 'Sem Nome';
          if (code.isNotEmpty) categoryMap[code] = name;
        }
        totalPages = data['total_de_paginas'] ?? 1;
        currentPage++;
      } else {
        break;
      }
    } while (currentPage <= totalPages);

    print('✅ [OMIE DEBUG] Sucesso Categorias: ${categoryMap.length} mapeamentos.');
    return categoryMap;
  }

  Future<Map<String, String>> listClients() async {
    Map<String, String> clientMap = {};
    int currentPage = 1;
    int totalPages = 1;

    do {
      final url = Uri.parse('$_baseUrl/geral/clientes/');
      final body = {
        "call": "ListarClientes",
        "app_key": appKey,
        "app_secret": appSecret,
        "param": [{"pagina": currentPage, "registros_por_pagina": 100, "apenas_importado_api": "N"}]
      };

      final response = await _postWithRetry(url, body);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['clientes_cadastro'] ?? [];
        for (var item in list) {
          String code = item['codigo_cliente_omie']?.toString() ?? '';
          String name = item['nome_fantasia']?.toString() ?? item['razao_social']?.toString() ?? 'Sem Nome';
          String city = item['cidade']?.toString() ?? 'Desconhecido';
          if (code.isNotEmpty) clientMap[code] = '$name|$city';
        }
        totalPages = data['total_de_paginas'] ?? 1;
        currentPage++;
      } else {
        break;
      }
    } while (currentPage <= totalPages);

    print('✅ [OMIE DEBUG] Sucesso Clientes: ${clientMap.length} mapeamentos.');
    return clientMap;
  }

  Future<Map<String, String>> listProjects() async {
    Map<String, String> projectMap = {};
    int currentPage = 1;
    int totalPages = 1;

    do {
      final url = Uri.parse('$_baseUrl/geral/projetos/');
      final body = {
        "call": "ListarProjetos",
        "app_key": appKey,
        "app_secret": appSecret,
        "param": [{"pagina": currentPage, "registros_por_pagina": 100}]
      };

      final response = await _postWithRetry(url, body);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['lista_projetos'] ?? [];
        for (var item in list) {
          String code = item['nCodProj']?.toString() ?? '';
          String name = item['cNomeProj']?.toString() ?? 'Sem Nome';
          if (code.isNotEmpty) projectMap[code] = name;
        }
        totalPages = data['total_de_paginas'] ?? 1;
        currentPage++;
      } else {
        break;
      }
    } while (currentPage <= totalPages);

    print('✅ [OMIE DEBUG] Sucesso Projetos: ${projectMap.length} mapeamentos.');
    return projectMap;
  }

  Future<Map<String, String>> listDepartments() async {
    Map<String, String> deptMap = {};
    int currentPage = 1;
    int totalPages = 1;

    do {
      final url = Uri.parse('$_baseUrl/geral/departamentos/');
      final body = {
        "call": "ListarDepartamentos",
        "app_key": appKey,
        "app_secret": appSecret,
        "param": [{"pagina": currentPage, "registros_por_pagina": 100}]
      };

      final response = await _postWithRetry(url, body);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['lista_departamentos'] ?? [];
        for (var item in list) {
          String code = item['codigo']?.toString() ?? '';
          String name = item['descricao']?.toString() ?? 'Sem Nome';
          if (code.isNotEmpty) deptMap[code] = name;
        }
        totalPages = data['total_de_paginas'] ?? 1;
        currentPage++;
      } else {
        break;
      }
    } while (currentPage <= totalPages);

    print('✅ [OMIE DEBUG] Sucesso Departamentos: ${deptMap.length} mapeamentos.');
    return deptMap;
  }

  Future<Map<String, String>> listBusinessUnits() async {
    Map<String, String> unitMap = {};
    int currentPage = 1;
    int totalPages = 1;

    do {
      final url = Uri.parse('$_baseUrl/geral/unidades/');
      final body = {
        "call": "ListarUnidadesNegocio",
        "app_key": appKey,
        "app_secret": appSecret,
        "param": [{"pagina": currentPage, "registros_por_pagina": 100}]
      };

      final response = await _postWithRetry(url, body);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['lista_unidades_negocio'] ?? [];
        for (var item in list) {
          String code = item['codigo']?.toString() ?? '';
          String name = item['nome']?.toString() ?? 'Sem Nome';
          if (code.isNotEmpty) unitMap[code] = name;
        }
        totalPages = data['total_de_paginas'] ?? 1;
        currentPage++;
      } else {
        break;
      }
    } while (currentPage <= totalPages);

    print('✅ [OMIE DEBUG] Sucesso Unidades: ${unitMap.length} mapeamentos.');
    return unitMap;
  }

  Future<List<dynamic>> listServiceOrders() async {
    List<dynamic> allOS = [];
    int currentPage = 1;
    int totalPages = 1;

    do {
      final url = Uri.parse('$_baseUrl/servicos/os/');
      final body = {
        "call": "ListarOS",
        "app_key": appKey,
        "app_secret": appSecret,
        "param": [{"pagina": currentPage, "registros_por_pagina": 100}]
      };

      final response = await _postWithRetry(url, body);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['osListarResposta'] ?? data['osCadastro'] ?? [];
        allOS.addAll(list);
        totalPages = data['total_de_paginas'] ?? 1;
        currentPage++;
      } else {
        break;
      }
    } while (currentPage <= totalPages);

    print('✅ [OMIE DEBUG] Sucesso OS: ${allOS.length} ordens encontradas.');
    return allOS;
  }

  Future<List<dynamic>> listSalesOrders() async {
    List<dynamic> allOrders = [];
    int currentPage = 1;
    int totalPages = 1;

    do {
      final url = Uri.parse('$_baseUrl/produtos/pedido/');
      final body = {
        "call": "ListarPedidos",
        "app_key": appKey,
        "app_secret": appSecret,
        "param": [{"pagina": currentPage, "registros_por_pagina": 100}]
      };

      final response = await _postWithRetry(url, body);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['pedido_venda_produto'] ?? data['lista_pedidos'] ?? [];
        allOrders.addAll(list);
        totalPages = data['total_de_paginas'] ?? 1;
        currentPage++;
      } else {
        break;
      }
    } while (currentPage <= totalPages);

    print('✅ [OMIE DEBUG] Sucesso Vendas: ${allOrders.length} pedidos encontrados.');
    return allOrders;
  }

  Future<String?> getCompanyCnpj() async {
    final url = Uri.parse('$_baseUrl/geral/empresas/');
    final body = {
      "call": "ListarEmpresas",
      "app_key": appKey,
      "app_secret": appSecret,
      "param": [{"pagina": 1, "registros_por_pagina": 1}]
    };

    final response = await _postWithRetry(url, body);
    if (response != null && response.statusCode == 200) {
      final data = json.decode(response.body);
      final list = data['empresas_cadastro'] ?? [];
      if (list.isNotEmpty) {
        return list[0]['cnpj']?.toString().replaceAll(RegExp(r'[^0-9]'), '');
      }
    }
    return null;
  }

  Future<bool> payBill(int nCodLanc, double amount) async {
    final url = Uri.parse('$_baseUrl/financas/contapagar/');
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    final body = {
      "call": "LancarPagamento",
      "app_key": appKey,
      "app_secret": appSecret,
      "param": [{"codigo_lancamento": nCodLanc, "data_pagamento": today, "valor_pagamento": amount}]
    };

    final response = await _postWithRetry(url, body);
    return (response != null && response.statusCode == 200);
  }

  Future<bool> addAccountReceivable({
    required int clientCode,
    required String dueDate,
    required double amount,
    required String categoryCode,
    required String description,
  }) async {
    final url = Uri.parse('$_baseUrl/financas/contareceber/');
    final body = {
      "call": "IncluirContaReceber",
      "app_key": appKey,
      "app_secret": appSecret,
      "param": [
        {
          "codigo_lancamento_integracao": DateTime.now().millisecondsSinceEpoch.toString(),
          "codigo_cliente_fornecedor": clientCode,
          "data_vencimento": dueDate,
          "valor_documento": amount,
          "codigo_categoria": categoryCode,
          "observacao": description,
        }
      ]
    };

    final response = await _postWithRetry(url, body);
    return (response != null && response.statusCode == 200);
  }

  Future<List<dynamic>> listCrmOpportunities() async {
    List<dynamic> allOpps = [];
    int currentPage = 1;
    int totalPages = 1;

    do {
      final url = Uri.parse('$_baseUrl/crm/oportunidades/');
      final body = {
        "call": "ListarOportunidades",
        "app_key": appKey,
        "app_secret": appSecret,
        "param": [{"pagina": currentPage, "registros_por_pagina": 100}]
      };

      final response = await _postWithRetry(url, body);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['cadastros'] ?? data['oportunidades'] ?? [];
        allOpps.addAll(list);
        totalPages = data['total_de_paginas'] ?? 1;
        currentPage++;
      } else {
        break;
      }
    } while (currentPage <= totalPages);

    print('✅ [OMIE DEBUG] Sucesso CRM: ${allOpps.length} oportunidades encontradas.');
    return allOpps;
  }

  Future<List<dynamic>> listPurchaseOrders() async {
    List<dynamic> allPurchases = [];
    int currentPage = 1;
    int totalPages = 1;

    do {
      final url = Uri.parse('$_baseUrl/produtos/pedidocompra/');
      final body = {
        "call": "ListarPedidosCompra",
        "app_key": appKey,
        "app_secret": appSecret,
        "param": [{"pagina": currentPage, "registros_por_pagina": 100}]
      };

      final response = await _postWithRetry(url, body);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['pedido_compra_produto'] ?? data['compras'] ?? [];
        allPurchases.addAll(list);
        totalPages = data['total_de_paginas'] ?? 1;
        currentPage++;
      } else {
        break;
      }
    } while (currentPage <= totalPages);

    print('✅ [OMIE DEBUG] Sucesso Compras: ${allPurchases.length} compras encontradas.');
    return allPurchases;
  }
}

