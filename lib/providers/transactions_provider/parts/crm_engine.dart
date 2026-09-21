part of '../../transactions_provider.dart';

extension TransactionsProviderCRM on TransactionsProvider {
  // 🔍 Motor de Busca Universal de Histórico (Timeline)
  List<Map<String, dynamic>> getClientTimeline(String clientId) {
    if (clientId.isEmpty) return [];
    
    // Normalização para ignorar zeros à esquerda e espaços
    final cleanQueryId = clientId.trim().replaceFirst(RegExp(r'^0+'), '');
    final List<Map<String, dynamic>> events = [];

    // 1. Buscar em Ordens de Serviço
    for (var os in _omieOS) {
      final cab = os['Cabecalho'] ?? os['cabecalho'] ?? {};
      final String id = (cab['nCodCli'] ?? cab['codigo_cliente'] ?? '').toString().trim().replaceFirst(RegExp(r'^0+'), '');
      if (id == cleanQueryId) {
        events.add({
          'date': _safeParseDate(cab['dDtPrevisao'] ?? cab['dDtInc']),
          'type': 'ORDEM SERVIÇO',
          'title': "OS #${cab['nCodOS']} - ${cab['cEtapaDes'] ?? 'Aberta'}",
          'value': double.tryParse(cab['vlrTotalOS']?.toString() ?? '0') ?? 0,
          'color': 'purple',
        });
      }
    }

    // 2. Buscar em Pedidos de Venda
    for (var order in _omieOrders) {
      final cab = order['Cabecalho'] ?? order['cabecalho'] ?? {};
      final String id = (cab['nCodCli'] ?? cab['codigo_cliente'] ?? order['codigo_cliente_omie'] ?? '').toString().trim().replaceFirst(RegExp(r'^0+'), '');
      if (id == cleanQueryId) {
        events.add({
          'date': _safeParseDate(cab['dDtPrevisao'] ?? cab['data_previsao']),
          'type': 'PEDIDO VENDA',
          'title': "Pedido #${cab['numero_pedido']} - ${cab['etapa_des'] ?? 'Iniciado'}",
          'value': double.tryParse(cab['valor_total']?.toString() ?? '0') ?? 0,
          'color': 'cyan',
        });
      }
    }

    // 3. Buscar em Títulos (Financeiro)
    for (var item in _omieAccountsReceivable) {
      final String id = (item['codigo_cliente_fornecedor'] ?? '').toString().trim().replaceFirst(RegExp(r'^0+'), '');
      if (id == cleanQueryId) {
        events.add({
          'date': _safeParseDate(item['data_vencimento'] ?? item['dDtVenc']),
          'type': item['status_titulo'] == 'PAGO' ? 'RECEBIDO' : 'A RECEBER',
          'title': item['cDesCategor'] ?? 'Faturamento',
          'value': double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0,
          'color': item['status_titulo'] == 'PAGO' ? 'green' : 'orange',
        });
      }
    }

    // Ordenar por data (mais recente primeiro)
    events.sort((a, b) => b['date'].compareTo(a['date']));
    return events;
  }

  // 🩺 Radar de Churn (Saúde do Cliente)
  List<String> getChurnAlerts() {
    final List<String> churnIds = [];
    final now = DateTime.now();
    final Map<String, DateTime> lastActivity = {};
    final Map<String, int> transactionCount = {};

    for (var os in _omieOS) {
      final cab = os['Cabecalho'] ?? os['cabecalho'] ?? {};
      final String id = (cab['nCodCli'] ?? cab['codigo_cliente']).toString();
      final dt = _safeParseDate(cab['dDtPrevisao'] ?? cab['dDtInc']);
      transactionCount[id] = (transactionCount[id] ?? 0) + 1;
      if (lastActivity[id] == null || dt.isAfter(lastActivity[id]!)) {
        lastActivity[id] = dt;
      }
    }

    lastActivity.forEach((id, dt) {
      // Cliente inativo há mais de 60 dias e que já comprou pelo menos 3 vezes
      if (now.difference(dt).inDays > 60 && (transactionCount[id] ?? 0) >= 3) {
        churnIds.add(id);
      }
    });
    return churnIds;
  }

  // 📲 Automação de Cobrança WhatsApp
  String generateWhatsAppMessage(String clientName, Map<String, dynamic> event) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final String valueStr = currency.format(event['value'] ?? 0);
    final String dateStr = DateFormat('dd/MM/yyyy').format(event['date'] as DateTime);
    
    return "Olá, $clientName! 👋\n\nIdentificamos uma pendência de $valueStr vencida em $dateStr. Seria possível nos enviar o comprovante ou confirmar a previsão de pagamento? Obrigado!";
  }
}
