part of '../../transactions_provider.dart';

extension TransactionsProviderSemesterFlow on TransactionsProvider {
  Future<Map<String, dynamic>> get6MonthFlowData(String accountId) async {
    final acc = _omieAccounts.firstWhereOrNull((a) => a.id == accountId);
    if (acc == null) return {};

    final omie = OmieService(appKey: acc.appKey, appSecret: acc.appSecret);
    
    print('📡 [OMIE FLOW] Iniciando captura total para ${acc.name} ($accountId)...');
    final receivables = await omie.listAccountsReceivable();
    print('🔍 [OMIE FLOW] ${acc.name}: ${receivables.length} recebíveis recebidos da API.');
    await Future.delayed(const Duration(seconds: 1));

    final payables = await omie.listAccountsPayable();
    print('🔍 [OMIE FLOW] ${acc.name}: ${payables.length} pagáveis recebidos da API.');
    await Future.delayed(const Duration(seconds: 1));

    final categories = await omie.listCategories();
    print('🔍 [OMIE FLOW] ${acc.name}: ${categories.length} categorias mapeadas.');

    // Período dinâmico: 6 meses passados a partir do mês atual
    final now = DateTime.now();
    final List<DateTime> months = List.generate(6, (i) {
      return DateTime(now.year, now.month - (5 - i), 1);
    });

    final Map<String, List<double>> incomeMatrix = {};
    final Map<String, List<double>> expenseMatrix = {};

    void process(List<dynamic> list, bool isIncome) {
      for (var item in list) {
        // Filtragem local por data
        final dt = _safeParseDate(item['data_vencimento'] ?? item['dDtVenc'] ?? item['data_vencimento_titulo']);
        int monthIdx = -1;
        for (int i = 0; i < months.length; i++) {
          if (dt.year == months[i].year && dt.month == months[i].month) {
            monthIdx = i;
            break;
          }
        }
        if (monthIdx == -1) continue;

        final val = double.tryParse(item['valor_documento']?.toString() ?? item['nValorTitulo']?.toString() ?? '0') ?? 0;
        final catCode = (item['codigo_categoria'] ?? item['codigo_categoria_receber'] ?? item['cCodCategor'] ?? '').toString();
        
        // Obter apenas o nome da categoria, sem o código (ex: "Vendas")
        String catName = categories[catCode] ?? 'Outros';

        final targetMap = isIncome ? incomeMatrix : expenseMatrix;
        if (!targetMap.containsKey(catName)) {
          targetMap[catName] = List.filled(6, 0.0);
        }
        targetMap[catName]![monthIdx] += val;
      }
    }

    print('📊 [OMIE FLOW] Filtrando por data (6 meses) para ${acc.name}...');
    process(receivables, true);
    process(payables, false);
    print('✅ [OMIE FLOW] ${acc.name} concluído. Categorias com valor: ${incomeMatrix.length} (Receitas), ${expenseMatrix.length} (Despesas).');

    return {
      'income': incomeMatrix,
      'expense': expenseMatrix,
    };
  }
}
