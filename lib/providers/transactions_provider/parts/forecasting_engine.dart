part of '../../transactions_provider.dart';

extension TransactionsProviderForecasting on TransactionsProvider {
  // 🔮 Forecasting com Inteligência Sazonal (v8)
  List<Map<String, dynamic>> get omieForecasting {
    final List<Map<String, dynamic>> projection = [];
    final now = DateTime.now();
    
    // Saldo atual como ponto de partida
    double currentBalance = totalBalance;
    
    // Média base de entradas e saídas (últimos 6 meses)
    double baseIn = 0;
    double baseOut = 0;
    for (var item in _omieAccountsReceivable) if (_applyGlobalFilters(item)) baseIn += double.tryParse(item['valor_documento']?.toString() ?? '0.0') ?? 0.0;
    for (var item in _omieAccountsPayable) if (_applyGlobalFilters(item)) baseOut += double.tryParse(item['valor_documento']?.toString() ?? '0.0') ?? 0.0;
    baseIn /= 6;
    baseOut /= 6;

    // Calcular pesos sazonais
    final seasonality = _calculateSeasonalityIndices();

    for (int i = 0; i <= 3; i++) {
      final date = DateTime(now.year, now.month + i, now.day);
      final factor = seasonality[date.month] ?? 1.0;
      
      // No mês 0 usamos o saldo atual, nos meses seguintes aplicamos a variação sazonal + oportunidades CRM
      if (i > 0) {
        final crmOpportunityIncome = _getCrmOpportunityDeltaForMonth(date);
        currentBalance += (baseIn * factor) + crmOpportunityIncome - (baseOut * factor);
      }
      
      projection.add({
        'month': DateFormat('MMM').format(date),
        'date': date,
        'value': currentBalance,
        'factor': factor,
      });
    }

    return projection;
  }
  // 🔮 Forecasting Diário (Micro-Projeção Dinâmica por Filtro Ativo)
  List<Map<String, dynamic>> get omieDailyForecast {
    final List<Map<String, dynamic>> dailyCurve = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 1. Determinar a data de início e os dias a projetar com base no modo de filtro ativo
    final DateTime startDate;
    final int daysToProject;
    
    if (_filterMode == OmieFilterMode.yearly) {
      startDate = DateTime(_selectedYear, 1, 1);
      final bool isLeap = (_selectedYear % 4 == 0 && _selectedYear % 100 != 0) || (_selectedYear % 400 == 0);
      daysToProject = isLeap ? 366 : 365;
    } else if (_filterMode == OmieFilterMode.monthly) {
      startDate = DateTime(_selectedYear, _selectedMonth, 1);
      daysToProject = DateTime(_selectedYear, _selectedMonth + 1, 1).subtract(const Duration(days: 1)).day;
    } else if (_filterMode == OmieFilterMode.daily) {
      startDate = _selectedSpecificDate ?? today;
      daysToProject = 1;
    } else if (_filterMode == OmieFilterMode.custom && _rangeStart != null) {
      startDate = _rangeStart!;
      final diff = _rangeEnd != null ? _rangeEnd!.difference(_rangeStart!).inDays + 1 : 30;
      daysToProject = diff.clamp(1, 90); // Limita a 90 dias por performance
    } else {
      startDate = today;
      daysToProject = 30;
    }
    
    // 2. Agrupar AR e AP por data exata (ignorando horas)
    final Map<DateTime, double> dailyDelta = {};
    
    for (var x in _omieAccountsReceivable) {
      if (x['status_titulo'] == 'PAGO') continue;
      final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
      final dateKey = DateTime(dt.year, dt.month, dt.day);
      final val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      dailyDelta[dateKey] = (dailyDelta[dateKey] ?? 0) + val;
    }

    // Integrar oportunidades de Ordens de Serviço (OS) com peso de probabilidade
    for (var os in _omieOS) {
      final cab = os['Cabecalho'] ?? os['cabecalho'] ?? {};
      final etapa = cab['cEtapa']?.toString() ?? '00';
      if (etapa == '60' || etapa == '50') continue;

      final dt = _safeParseDate(cab['dDtPrevisao'] ?? cab['dDtInc']);
      final dateKey = DateTime(dt.year, dt.month, dt.day);
      final amount = double.tryParse(cab['vlrTotalOS']?.toString() ?? '0') ?? 0;

      double weight = 0.1;
      if (etapa == '00' || etapa == '02') weight = 0.3;
      else if (etapa == '10' || etapa == '15') weight = 0.6;
      else if (etapa == '20' || etapa == '30') weight = 0.85;

      dailyDelta[dateKey] = (dailyDelta[dateKey] ?? 0) + (amount * weight);
    }

    // Integrar oportunidades de Pedidos de Venda com peso de probabilidade
    for (var order in _omieOrders) {
      final cab = order['Cabecalho'] ?? order['cabecalho'] ?? {};
      final etapa = cab['etapa']?.toString() ?? '00';
      if (etapa == '60' || etapa == '50') continue;

      final dt = _safeParseDate(cab['dDtPrevisao'] ?? cab['data_previsao'] ?? cab['dDtInc']);
      final dateKey = DateTime(dt.year, dt.month, dt.day);
      final amount = double.tryParse(cab['valor_total']?.toString() ?? '0') ?? 0;

      double weight = 0.1;
      if (etapa == '00') weight = 0.3;
      else if (etapa == '10') weight = 0.75;
      else if (etapa == '20') weight = 0.95;

      dailyDelta[dateKey] = (dailyDelta[dateKey] ?? 0) + (amount * weight);
    }

    for (var x in _omieAccountsPayable) {
      if (x['status_titulo'] == 'PAGO') continue;
      final dt = _safeParseDate(x['data_vencimento'] ?? x['dDtVenc']);
      final dateKey = DateTime(dt.year, dt.month, dt.day);
      final val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0;
      dailyDelta[dateKey] = (dailyDelta[dateKey] ?? 0) - val;
    }

    // Processar Local (Manual)
    for (var t in _transactions) {
      final dateKey = DateTime(t.date.year, t.date.month, t.date.day);
      final val = t.type == TransactionType.income ? t.amount : -t.amount;
      dailyDelta[dateKey] = (dailyDelta[dateKey] ?? 0) + val;
    }

    // Média de gastos diários estimada (baseada no mês selecionado se monthly, ou anual / 12)
    final double referenceExpense = _filterMode == OmieFilterMode.yearly ? (monthExpense * 12) : monthExpense;
    final avgDailyBurn = referenceExpense / 365;

    // 3. Reconstruir/caminhar até o saldo inicial no dia 1 de startDate
    double runningBalance = totalBalance;
    if (startDate.isBefore(today)) {
      DateTime d = today;
      while (d.isAfter(startDate)) {
        d = d.subtract(const Duration(days: 1));
        final delta = dailyDelta[d] ?? -avgDailyBurn;
        runningBalance -= delta;
      }
    } else if (startDate.isAfter(today)) {
      DateTime d = today;
      while (d.isBefore(startDate)) {
        final delta = dailyDelta[d] ?? -avgDailyBurn;
        runningBalance += delta;
        d = d.add(const Duration(days: 1));
      }
    }

    // 4. Projetar os dias
    for (int i = 0; i < daysToProject; i++) {
      final currentDay = startDate.add(Duration(days: i));
      
      if (i > 0) {
        if (dailyDelta.containsKey(currentDay)) {
          runningBalance += dailyDelta[currentDay]!;
        } else {
          runningBalance -= avgDailyBurn;
        }
      }

      dailyCurve.add({
        'date': currentDay,
        'balance': runningBalance,
        'isReal': dailyDelta.containsKey(currentDay),
      });
    }

    return dailyCurve;
  }

  // 🚨 Alerta Predictivo de Liquidez
  Map<String, dynamic>? get omiePredictiveAlert {
    final forecast = omieDailyForecast;
    final firstHole = forecast.firstWhereOrNull((d) => d['balance'] < 0);
    
    if (firstHole == null) return null;

    final dateStr = DateFormat('dd/MM/yyyy').format(firstHole['date']);
    final valorAprox = (firstHole['balance'] as double).abs();
    
    return {
      'date': firstHole['date'],
      'message': "⚠️ Alerta de Caixa: Projeção negativa em $dateStr no valor de ${NumberFormat.simpleCurrency(locale: 'pt_BR').format(valorAprox)}.",
      'suggestion': "Sugestão: Verifique se há faturas de clientes próximos a esta data que podem ser antecipadas ou renegocie pagamentos de fornecedores.",
      'severity': 'high'
    };
  }

  // 📂 Algoritmo de Análise Histórica de Sazonalidade
  Map<int, double> _calculateSeasonalityIndices() {
    final Map<int, List<double>> monthData = {};
    final Map<String, double> history = {};

    // Agrupar recebíveis por mês/ano para criar uma base histórica
    for (var item in _omieAccountsReceivable) {
      if (!_applyGlobalFilters(item)) continue;
      try {
        final dt = DateFormat('dd/MM/yyyy').parse(item['data_vencimento'] ?? item['dDtVenc']);
        final key = "${dt.month}/${dt.year}";
        history[key] = (history[key] ?? 0) + (double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0);
      } catch (_) {}
    }

    if (history.isEmpty) return {};

    // Organizar faturamentos por mês do calendário
    history.forEach((key, val) {
      final month = int.parse(key.split('/')[0]);
      monthData[month] = (monthData[month] ?? [])..add(val);
    });

    // Média global de faturamento mensal
    double globalAvg = history.values.fold(0.0, (sum, v) => sum + v) / history.length;

    final Map<int, double> indices = {};
    for (int i = 1; i <= 12; i++) {
      if (monthData.containsKey(i)) {
        double monthAvg = monthData[i]!.fold(0.0, (sum, v) => sum + v) / monthData[i]!.length;
        // O índice é quanto este mês é maior ou menor que a média global
        indices[i] = (monthAvg / globalAvg).clamp(0.5, 2.0); 
      } else {
        indices[i] = 1.0; // Neutro se não houver dados
      }
    }
    return indices;
  }
}
