part of '../../transactions_provider.dart';

extension TransactionsProviderCheckPanel on TransactionsProvider {
  
  // --- DIAGNOSTICO DE PREENCHIMENTO OMIE ---

  List<Map<String, dynamic>> get omieDiagnostic {
    final List<Map<String, dynamic>> issues = [];

    // 1. Verificar lançamentos sem categoria
    int noCategoryCount = 0;
    double noCategoryValue = 0;
    for (var x in _omieAccountsReceivable) {
      if (x['codigo_categoria'] == null || x['codigo_categoria'].toString().isEmpty) {
        noCategoryCount++;
        noCategoryValue += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      }
    }
    for (var x in _omieAccountsPayable) {
      if (x['codigo_categoria'] == null || x['codigo_categoria'].toString().isEmpty) {
        noCategoryCount++;
        noCategoryValue += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      }
    }

    if (noCategoryCount > 0) {
      issues.add({
        'type': 'CRITICO',
        'title': '$noCategoryCount lançamentos sem categoria',
        'description': 'Atenção: Estes lançamentos estão sem categoria de custo e estão distorcendo seu EBITDA e DRE. Valor total: R\$ ${noCategoryValue.toStringAsFixed(2)}',
        'severity': 3, // 1 a 3
        'icon': 'category',
      });
    }

    // 2. Verificar lançamentos sem Cliente/Fornecedor
    int noEntityCount = 0;
    for (var x in _omieAccountsReceivable) {
      if (x['codigo_cliente_fornecedor'] == null || x['codigo_cliente_fornecedor'].toString() == '0') {
        noEntityCount++;
      }
    }
    if (noEntityCount > 0) {
      issues.add({
        'type': 'ALERTA',
        'title': '$noEntityCount receitas sem cliente identificado',
        'description': 'Isso impede a análise de Curva ABC de clientes e ranking de faturamento.',
        'severity': 2,
        'icon': 'person_off',
      });
    }

    // 3. Verificar datas retroativas excessivas (Potencial erro de competência)
    int backdatedCount = 0;
    final now = DateTime.now();
    for (var x in _omieOrders) {
      final date = _safeParseDate(x['cabecalho']?['data_previsao'] ?? x['cabecalho']?['dDtPrevisao']);
      if (date.isBefore(now.subtract(const Duration(days: 365)))) {
        backdatedCount++;
      }
    }

    if (backdatedCount > 0) {
      issues.add({
        'type': 'SUGESTAO',
        'title': 'Pedidos com data muito antiga',
        'description': 'Existem $backdatedCount pedidos com data de previsão de mais de 1 ano atrás. Verifique se precisam ser cancelados ou faturados.',
        'severity': 1,
        'icon': 'history',
      });
    }

    // 4. Saldo Bancário Negativo
    final balances = omieBankBalances;
    int negativeAccounts = balances.where((b) => b['balance'] < 0).length;
    if (negativeAccounts > 0) {
      issues.add({
        'type': 'ALERTA',
        'title': '$negativeAccounts contas com saldo negativo',
        'description': 'Contas negativas geram despesas financeiras (juros/mora) que podem não estar mapeadas.',
        'severity': 2,
        'icon': 'account_balance',
      });
    }

    return issues;
  }
}
