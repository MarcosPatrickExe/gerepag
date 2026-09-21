part of '../../transactions_provider.dart';

extension TransactionsProviderSimulation on TransactionsProvider {
  /// Gera uma projeção de fluxo de caixa para os próximos [months] meses.
  /// [additionalMonthlyExpense] é um valor fixo somado às despesas mensais (ex: contratações).
  /// [revenueFactor] é um multiplicador aplicado às receitas previstas (ex: 0.9 para perda de 10%).
  /// [oneTimeInvestment] é um valor pontual descontado no primeiro mês.
  Map<String, dynamic> calculateWhatIfScenario({
    int months = 6,
    double additionalMonthlyExpense = 0.0,
    double revenueFactor = 1.0,
    double oneTimeInvestment = 0.0,
    bool includeLostTopClient = false,
  }) {
    final now = DateTime.now();
    double currentBalance = totalBalance;
    
    final List<String> monthLabels = [];
    final List<double> realScenario = [];
    final List<double> simScenario = [];

    // Identificar o maior cliente para o cenário "Cruel"
    String? topClientId;
    double topClientMonthlyRevenue = 0;
    
    if (includeLostTopClient) {
      final Map<String, double> clientRevenue = {};
      for (var item in _omieAccountsReceivable) {
        final val = double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0;
        final id = item['codigo_cliente_fornecedor'].toString();
        clientRevenue[id] = (clientRevenue[id] ?? 0) + val;
      }
      if (clientRevenue.isNotEmpty) {
        final sorted = clientRevenue.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        topClientId = sorted.first.key;
        // Média mensal desse cliente (estimada por um mês para a simulação)
        topClientMonthlyRevenue = sorted.first.value / 6; // Simplificação: assume que o total em cache é de 6 meses
      }
    }

    // 0. Ponto inicial (Mês atual)
    monthLabels.add(DateFormat('MMM').format(now));
    realScenario.add(currentBalance);
    simScenario.add(currentBalance - oneTimeInvestment);
    
    double runningRealBalance = currentBalance;
    double runningSimBalance = currentBalance - oneTimeInvestment;

    for (int i = 1; i <= months; i++) {
      final targetDate = DateTime(now.year, now.month + i, 1);
      monthLabels.add(DateFormat('MMM').format(targetDate));

      // 1. Calcular Receitas e Despesas previstas para este mês na Omie
      double monthlyReceivables = 0;
      double monthlyPayables = 0;

      for (var item in _omieAccountsReceivable) {
        if (item['status_titulo'] == 'PAGO') continue;
        final dt = _safeParseDate(item['data_vencimento'] ?? item['dDtVenc']);
        if (dt.month == targetDate.month && dt.year == targetDate.year) {
          double val = double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0;
          
          // Se o cenário cruel estiver ativo, removemos este cliente da projeção
          if (includeLostTopClient && item['codigo_cliente_fornecedor'].toString() == topClientId) {
             continue; 
          }
          
          monthlyReceivables += val;
        }
      }

      for (var item in _omieAccountsPayable) {
        if (item['status_titulo'] == 'PAGO') continue;
        final dt = _safeParseDate(item['data_vencimento'] ?? item['dDtVenc']);
        if (dt.month == targetDate.month && dt.year == targetDate.year) {
          monthlyPayables += double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0;
        }
      }

      // Adicionar oportunidades do CRM ao faturamento estimado do mês
      double crmOpportunities = _getCrmOpportunityDeltaForMonth(targetDate);
      monthlyReceivables += crmOpportunities;

      // Se não houver dados futuros na Omie para o mês i, usamos a média dos meses anteriores
      if (monthlyReceivables == 0 && i > 1) monthlyReceivables = (monthIncome > 0 ? monthIncome : 0);
      if (monthlyPayables == 0 && i > 1) monthlyPayables = (monthExpense > 0 ? monthExpense : 0);

      // 2. Aplicar Cenário Real
      runningRealBalance += (monthlyReceivables - monthlyPayables);
      realScenario.add(runningRealBalance);

      // 3. Aplicar Cenário Simulado
      double simIncome = monthlyReceivables * revenueFactor;
      double simExpense = monthlyPayables + additionalMonthlyExpense;
      runningSimBalance += (simIncome - simExpense);
      simScenario.add(runningSimBalance);
    }

    return {
      'labels': monthLabels,
      'real': realScenario,
      'simulated': simScenario,
      'topClientName': includeLostTopClient && topClientId != null ? (_omieClients[topClientId]?.split('|').first ?? 'Maior Cliente') : null,
    };
  }
}

