import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/transactions_provider.dart';
import '../models/transaction_model.dart';
import 'dart:math' as math;
import '../services/anomaly_service.dart';

class PdfReportService {
  static Future<void> generateExecutiveReport(TransactionsProvider provider) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dre = provider.omieDRE;
    final aging = provider.omieAgingData;
    final taxes = provider.omieTaxSummary;
    final monthStr = DateFormat('MMMM yyyy', 'pt_BR').format(DateTime(provider.selectedYear, provider.selectedMonth));

    // Calcular Margem e Score
    double income = 0;
    double expense = 0;
    if (provider.isBusinessMode) {
      income = provider.monthIncome;
      expense = provider.monthExpense;
    } else {
      income = provider.transactions.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
      expense = provider.transactions.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
    }
    double marginPercent = income > 0 ? ((income - expense) / income) * 100 : 0.0;
    double rawScore = 50.0;
    if (income > 0) {
      if (marginPercent > 30) {
        rawScore = 80 + (marginPercent - 30) * 0.28;
      } else if (marginPercent > 0) {
        rawScore = 60 + marginPercent * 0.66;
      } else {
        rawScore = 30 + (100 + marginPercent).clamp(0.0, 30.0);
      }
    } else if (expense > 0) {
      rawScore = 25.0;
    }
    final double finalScore = rawScore.clamp(10.0, 100.0);
    PdfColor scoreColor = PdfColors.red900;
    String scoreStatus = 'CRÍTICO';
    if (finalScore >= 80) {
      scoreColor = PdfColors.green900;
      scoreStatus = 'EXCELENTE';
    } else if (finalScore >= 60) {
      scoreColor = PdfColors.blue900;
      scoreStatus = 'SAUDÁVEL';
    } else if (finalScore >= 40) {
      scoreColor = PdfColors.amber900;
      scoreStatus = 'ATENÇÃO';
    }

    // Obter Maiores Despesas
    final sortedExpenses = provider.categoricalExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topExpenses = sortedExpenses.take(5).toList();
    final double totalExpenses = sortedExpenses.fold(0.0, (sum, e) => sum + e.value);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('RELATÓRIO EXECUTIVO FINANCEIRO', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text('GESTÃO INTELIGENTE OMIE v5', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(monthStr.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 2, color: PdfColors.blue900),
          pw.SizedBox(height: 15),

          // Score de Saúde Card
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SAÚDE FINANCEIRA DO CAIXA', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      marginPercent >= 0 
                          ? 'Sua margem de sobra operacional está em ${marginPercent.toStringAsFixed(1)}% este mês.'
                          : 'Suas despesas superaram receitas em ${marginPercent.abs().toStringAsFixed(1)}% este mês.',
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '${finalScore.toStringAsFixed(0)}/100',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: scoreColor),
                    ),
                    pw.Text(
                      scoreStatus,
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: scoreColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          // KPIs Block
          pw.Text('SUMÁRIO DE PERFORMANCE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildKpiCard('Receita Total', currency.format(dre['revenue']), PdfColors.green900),
              _buildKpiCard('Despesa Total', currency.format(dre['expenses']), PdfColors.red900),
              _buildKpiCard('Lucro Líquido', currency.format(dre['profit']), PdfColors.blue900),
            ],
          ),
          pw.SizedBox(height: 15),

          // Maiores Despesas
          if (topExpenses.isNotEmpty) ...[
            pw.Text('DETALHAMENTO DE CUSTOS (TOP 5 CATEGORIAS)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: null,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              headers: ['Categoria de Custo / Despesa', 'Valor Total Consumido', 'Representatividade (%)'],
              data: topExpenses.map((e) {
                final percent = totalExpenses > 0 ? (e.value / totalExpenses) * 100 : 0.0;
                return [e.key.toUpperCase(), currency.format(e.value), '${percent.toStringAsFixed(1)}%'];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 15),
          ],

          // Aging section
          pw.Text('DÍVIDA POR IDADE (AGING RECEBÍVEIS)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: null,
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            headers: ['Faixa de Atraso', 'Valor Total em Aberto'],
            data: aging.entries.map((e) => [e.key, currency.format(e.value)]).toList(),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 15),

          // Taxes & MRR
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('IMPOSTOS RETIDOS (CAIXA INVISÍVEL)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Valor total retido em OS/Pedidos: ${currency.format(taxes)}', style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RECEITA RECORRENTE (MRR)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Volume via Contratos Omie: ${currency.format(provider.omieMRRStats['MRR'] ?? 0)}', style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),

          // Strategic Note
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border(left: pw.BorderSide(color: PdfColors.blue900, width: 4))),
            child: pw.Text(
              'Nota Estratégica: Este relatório consolida dados sincronizados via API Omie. A projeção de lucro para o período é de ${((dre['profit']! / (dre['revenue']! > 0 ? dre['revenue']! : 1)) * 100).toStringAsFixed(1)}% sobre a receita bruta.',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
            ),
          ),

          // Footer
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 24),
            child: pw.Center(child: pw.Text('Documento para uso gerencial interno. Dados protegidos por criptografia.', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey))),
          ),
        ],
      ),
    );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> generateCustomExecutiveReport(
    TransactionsProvider provider, {
    required String title,
    required String subtitle,
    required bool showKpis,
    required bool showAging,
    required bool showTaxes,
    required bool showNotes,
    bool showTopExpenses = true,
    bool showScore = true,
    bool showTopClientsSuppliers = true,
    bool showMoMComparison = true,
    bool showBankBalances = true,
    bool showSentinelaReport = true,
    bool showRunwayStats = true,
    bool showSparkline = true,
    String primaryColorHex = '#2563EB',
    String consultantNotes = '',
    String? logoBase64,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dre = provider.omieDRE;
    final aging = provider.omieAgingData;
    final taxes = provider.omieTaxSummary;
    final monthStr = DateFormat('MMMM yyyy', 'pt_BR').format(DateTime(provider.selectedYear, provider.selectedMonth));

    final brandColor = PdfColor.fromHex(primaryColorHex);

    pw.MemoryImage? logoImage;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      try {
        final cleanBase64 = logoBase64.contains(',') ? logoBase64.split(',').last : logoBase64;
        final imageBytes = base64Decode(cleanBase64);
        logoImage = pw.MemoryImage(imageBytes);
      } catch (e) {
        print('Erro ao decodificar logo no PDF: $e');
      }
    }

    // Calcular Margem e Score
    double income = 0;
    double expense = 0;
    if (provider.isBusinessMode) {
      income = provider.monthIncome;
      expense = provider.monthExpense;
    } else {
      income = provider.transactions.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
      expense = provider.transactions.where((t) => t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
    }
    double marginPercent = income > 0 ? ((income - expense) / income) * 100 : 0.0;
    double rawScore = 50.0;
    if (income > 0) {
      if (marginPercent > 30) {
        rawScore = 80 + (marginPercent - 30) * 0.28;
      } else if (marginPercent > 0) {
        rawScore = 60 + marginPercent * 0.66;
      } else {
        rawScore = 30 + (100 + marginPercent).clamp(0.0, 30.0);
      }
    } else if (expense > 0) {
      rawScore = 25.0;
    }
    final double finalScore = rawScore.clamp(10.0, 100.0);
    PdfColor scoreColor = PdfColors.red900;
    String scoreStatus = 'CRÍTICO';
    if (finalScore >= 80) {
      scoreColor = PdfColors.green900;
      scoreStatus = 'EXCELENTE';
    } else if (finalScore >= 60) {
      scoreColor = brandColor;
      scoreStatus = 'SAUDÁVEL';
    } else if (finalScore >= 40) {
      scoreColor = PdfColors.amber900;
      scoreStatus = 'ATENÇÃO';
    }

    // Obter Maiores Despesas
    final sortedExpenses = provider.categoricalExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topExpenses = sortedExpenses.take(5).toList();
    final double totalExpenses = sortedExpenses.fold(0.0, (sum, e) => sum + e.value);

    // Comparativo Mês a Mês (MoM)
    final currentYear = provider.selectedYear;
    final currentMonth = provider.selectedMonth;
    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    DateTime safeParseDate(dynamic input) {
      if (input == null) return DateTime(2000);
      try {
        if (input.toString().contains('/')) return DateFormat('dd/MM/yyyy').parse(input.toString());
        return DateTime.tryParse(input.toString()) ?? DateTime(2000);
      } catch (_) { return DateTime(2000); }
    }

    bool isWithinPrevPeriod(dynamic item) {
      final dateStr = item['data_vencimento'] ?? item['dDtVenc'];
      final dt = safeParseDate(dateStr);
      return dt.year == prevYear && dt.month == prevMonth;
    }

    double prevIncome = 0.0;
    for (var x in provider.omieAccountsReceivable) {
      if (isWithinPrevPeriod(x)) {
        prevIncome += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0.0;
      }
    }
    double prevExpense = 0.0;
    for (var x in provider.omieAccountsPayable) {
      if (isWithinPrevPeriod(x)) {
        prevExpense += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0.0;
      }
    }
    final double prevProfit = prevIncome - prevExpense;
    final double currentProfit = income - expense;

    final double revenueDiff = income - prevIncome;
    final double revenuePct = prevIncome > 0 ? (revenueDiff / prevIncome) * 100 : 0.0;

    final double expenseDiff = expense - prevExpense;
    final double expensePct = prevExpense > 0 ? (expenseDiff / prevExpense) * 100 : 0.0;

    final double profitDiff = currentProfit - prevProfit;
    final double profitPct = prevProfit.abs() > 0 ? (profitDiff / prevProfit.abs()) * 100 : 0.0;

    // Obter entradas e saídas detalhadas do período
    final entries = provider.omieAccountsReceivable.where((x) => provider.isWithinCurrentFilterDetailed(x)).toList();
    final exits = provider.omieAccountsPayable.where((x) => provider.isWithinCurrentFilterDetailed(x)).toList();

    // Ranking de Clientes (ABC)
    final Map<String, double> clientRevenue = {};
    for (var x in entries) {
      final name = provider.omieClients[x['codigo_cliente_fornecedor'].toString()] ?? 'Cliente ${x['codigo_cliente_fornecedor']}';
      final val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0.0;
      clientRevenue[name] = (clientRevenue[name] ?? 0.0) + val;
    }
    final sortedClients = clientRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topClients = sortedClients.take(5).toList();

    // Ranking de Fornecedores (ABC)
    final Map<String, double> supplierExpense = {};
    for (var x in exits) {
      final name = provider.omieClients[x['codigo_cliente_fornecedor'].toString()] ?? 'Fornecedor ${x['codigo_cliente_fornecedor']}';
      final val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0.0;
      supplierExpense[name] = (supplierExpense[name] ?? 0.0) + val;
    }
    final sortedSuppliers = supplierExpense.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSuppliers = sortedSuppliers.take(5).toList();

    // Consolidado Bancário
    final List<List<String>> bankData = [];
    if (provider.isBusinessMode) {
      for (var acc in provider.omieAccounts) {
        bankData.add([
          acc.name.toUpperCase(), 
          'CONTA OMIE (CNPJ: ${acc.cnpj ?? "Não Inf."})', 
          currency.format(provider.totalBalance)
        ]);
      }
      if (bankData.isEmpty) {
        bankData.add(['EMPRESA PRINCIPAL', 'CONTA CONSOLIDADA OMIE', currency.format(provider.totalBalance)]);
      }
    } else {
      for (var w in provider.wallets) {
        bankData.add([
          w.name.toUpperCase(), 
          'CARTEIRA LOCAL', 
          currency.format(provider.getWalletBalance(w.id))
        ]);
      }
    }

    // Auditoria de Anomalias (Sentinela Guard)
    final List<TransactionModel> mappedHistory = [];
    for (var x in provider.omieAccountsPayable) {
      final dateStr = x['data_vencimento'] ?? x['dDtVenc'];
      final dt = safeParseDate(dateStr);
      final val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0.0;
      final category = provider.omieCategories[x['codigo_categoria']] ?? 'Outros';
      mappedHistory.add(
        TransactionModel(
          id: x['codigo_lancamento_omie']?.toString() ?? 'omie_${x['codigo_cliente_fornecedor']}',
          amount: val,
          category: category,
          date: dt,
          description: provider.omieClients[x['codigo_cliente_fornecedor'].toString()] ?? 'Fornecedor',
          type: TransactionType.expense,
        ),
      );
    }
    for (var t in provider.transactions) {
      if (t.type == TransactionType.expense) {
        mappedHistory.add(t);
      }
    }
    final List<String> anomaliesFound = [];
    final currentPeriodExpenses = mappedHistory.where((tx) => tx.date.year == provider.selectedYear && tx.date.month == provider.selectedMonth).toList();
    for (var tx in currentPeriodExpenses) {
      final res = AnomalyService.check(tx, mappedHistory);
      if (res.isSuspect) {
        anomaliesFound.add('${DateFormat('dd/MM').format(tx.date)} - ${tx.description} (${tx.category}): ${res.reason}');
      }
    }

    // Runway e Indicadores
    final double savingRate = income > 0 ? ((income - expense) / income) * 100 : 0.0;
    final double runwayMonths = expense > 0 ? (provider.totalBalance / expense) : 99.0;
    final String runwayText = runwayMonths >= 99.0 ? 'Excelente (99+ meses)' : '${runwayMonths.toStringAsFixed(1)} meses';

    // Sparkline spots
    final spots = provider.omieBalanceHistorySpots;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: brandColor),
                    ),
                    pw.Text(
                      subtitle.toUpperCase(),
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              if (logoImage != null)
                pw.Container(
                  margin: const pw.EdgeInsets.only(left: 16),
                  width: 60,
                  height: 60,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
            ],
          ),
          pw.Divider(thickness: 2, color: brandColor),
          pw.SizedBox(height: 15),

          // Score de Saúde Card
          if (showScore) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SAÚDE FINANCEIRA DO CAIXA', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        marginPercent >= 0 
                            ? 'Sua margem de sobra operacional está em ${marginPercent.toStringAsFixed(1)}% este mês.'
                            : 'Suas despesas superaram receitas em ${marginPercent.abs().toStringAsFixed(1)}% este mês.',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '${finalScore.toStringAsFixed(0)}/100',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: scoreColor),
                      ),
                      pw.Text(
                        scoreStatus,
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: scoreColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
          ],

          // Parecer do Consultor
          if (consultantNotes.isNotEmpty) ...[
            pw.Text('PARECER TÉCNICO E DIRETRIZES DO CONSULTOR', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandColor)),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border(left: pw.BorderSide(color: brandColor, width: 4)),
              ),
              child: pw.Text(
                consultantNotes,
                style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800),
              ),
            ),
            pw.SizedBox(height: 15),
          ],

          // KPIs Block
          if (showKpis) ...[
            pw.Text('SUMÁRIO DE PERFORMANCE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandColor)),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildKpiCard('Receita Total', currency.format(dre['revenue']), PdfColors.green900),
                _buildKpiCard('Despesa Total', currency.format(dre['expenses']), PdfColors.red900),
                _buildKpiCard('Lucro Líquido', currency.format(dre['profit']), dre['profit']! >= 0 ? brandColor : PdfColors.red900),
              ],
            ),
            pw.SizedBox(height: 15),
          ],

          // Comparativo MoM
          if (showMoMComparison) ...[
            pw.Text('COMPARATIVO COM O MÊS ANTERIOR (MoM)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandColor)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: null,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: brandColor),
              headers: ['Indicador de DRE', 'Mês Selecionado', 'Mês Anterior', 'Variação (%)'],
              data: [
                ['Receita Operacional Bruta', currency.format(income), currency.format(prevIncome), '${revenuePct >= 0 ? "+" : ""}${revenuePct.toStringAsFixed(1)}%'],
                ['Despesa Operacional Total', currency.format(expense), currency.format(prevExpense), '${expensePct >= 0 ? "+" : ""}${expensePct.toStringAsFixed(1)}%'],
                ['Lucro Líquido do Período', currency.format(currentProfit), currency.format(prevProfit), '${profitPct >= 0 ? "+" : ""}${profitPct.toStringAsFixed(1)}%'],
              ],
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 15),
          ],

          // Maiores Despesas
          if (showTopExpenses && topExpenses.isNotEmpty) ...[
            pw.Text('DETALHAMENTO DE CUSTOS (TOP 5 CATEGORIAS)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandColor)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: null,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: brandColor),
              headers: ['Categoria de Custo / Despesa', 'Valor Total Consumido', 'Representatividade (%)'],
              data: topExpenses.map((e) {
                final percent = totalExpenses > 0 ? (e.value / totalExpenses) * 100 : 0.0;
                return [e.key.toUpperCase(), currency.format(e.value), '${percent.toStringAsFixed(1)}%'];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 15),
          ],

          // Ranking ABC Clientes/Fornecedores
          if (showTopClientsSuppliers) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (topClients.isNotEmpty)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOP CLIENTES (FATURAMENTO)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandColor)),
                        pw.SizedBox(height: 6),
                        pw.TableHelper.fromTextArray(
                          border: null,
                          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 7.5),
                          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                          headers: ['Cliente', 'Total Recebido'],
                          data: topClients.map((e) => [e.key, currency.format(e.value)]).toList(),
                          cellStyle: const pw.TextStyle(fontSize: 7.5),
                        ),
                      ],
                    ),
                  ),
                if (topClients.isNotEmpty && topSuppliers.isNotEmpty)
                  pw.SizedBox(width: 16),
                if (topSuppliers.isNotEmpty)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOP FORNECEDORES (CUSTOS)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandColor)),
                        pw.SizedBox(height: 6),
                        pw.TableHelper.fromTextArray(
                          border: null,
                          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 7.5),
                          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                          headers: ['Fornecedor', 'Total Pago'],
                          data: topSuppliers.map((e) => [e.key, currency.format(e.value)]).toList(),
                          cellStyle: const pw.TextStyle(fontSize: 7.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 15),
          ],

          // Saldos Bancários Consolidados
          if (showBankBalances && bankData.isNotEmpty) ...[
            pw.Text('CONSOLIDADO DE SALDOS E CONTAS DE CAIXA', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandColor)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: null,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: brandColor),
              headers: ['Instituição / Conta', 'Origem / Modalidade', 'Saldo Final'],
              data: bankData,
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 15),
          ],

          // Sparklines / Gráfico de Tendência
          if (showSparkline && spots.isNotEmpty) ...[
            pw.Text('EVOLUÇÃO DO SALDO DE CAIXA (31 DIAS)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandColor)),
            pw.SizedBox(height: 8),
            pw.Container(
              height: 45,
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 16),
              alignment: pw.Alignment.center,
              child: SparklineWidget(spots.map((s) => s.y).toList(), brandColor),
            ),
            pw.SizedBox(height: 15),
          ],

          // Runway e Fôlego
          if (showRunwayStats) ...[
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FÔLEGO OPERACIONAL (RUNWAY)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: brandColor)),
                        pw.SizedBox(height: 4),
                        pw.Text(runwayText, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TAXA DE POUPANÇA (SAVING RATE)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: brandColor)),
                        pw.SizedBox(height: 4),
                        pw.Text('${savingRate.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
          ],

          // Alertas Sentinela Guard
          if (showSentinelaReport) ...[
            pw.Text('MONITORAMENTO E CONFORMIDADE (SENTINELA GUARD)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandColor)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: anomaliesFound.isEmpty ? PdfColors.green50 : PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: anomaliesFound.isEmpty ? PdfColors.green300 : PdfColors.amber300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 8,
                        height: 8,
                        decoration: pw.BoxDecoration(
                          color: anomaliesFound.isEmpty ? PdfColors.green700 : PdfColors.amber700,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        anomaliesFound.isEmpty ? 'Nenhuma anomalia de caixa detectada.' : '${anomaliesFound.length} lançamentos suspeitos identificados:',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  if (anomaliesFound.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    ...anomaliesFound.map(
                      (anomaly) => pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('• ', style: const pw.TextStyle(fontSize: 7.5)),
                          pw.Expanded(
                            child: pw.Text(anomaly, style: const pw.TextStyle(fontSize: 7.5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 15),
          ],

          // Aging section
          if (showAging) ...[
            pw.Text('DÍVIDA POR IDADE (AGING RECEBÍVEIS)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandColor)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: null,
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: brandColor),
              headers: ['Faixa de Atraso', 'Valor Total em Aberto'],
              data: aging.entries.map((e) => [e.key, currency.format(e.value)]).toList(),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 15),
          ],

          // Taxes & MRR
          if (showTaxes) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('IMPOSTOS RETIDOS (CAIXA INVISÍVEL)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandColor)),
                      pw.Text('Valor total retido em OS/Pedidos: ${currency.format(taxes)}', style: pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('RECEITA RECORRENTE (MRR)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandColor)),
                      pw.Text('Volume via Contratos Omie: ${currency.format(provider.omieMRRStats['MRR'] ?? 0)}', style: pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
          ],

          // Strategic Note
          if (showNotes) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border(left: pw.BorderSide(color: PdfColors.blueGrey800, width: 4)),
              ),
              child: pw.Text(
                'Nota Estratégica: Este relatório consolida dados sincronizados via API Omie. A projeção de lucro para o período é de ${((dre['profit']! / (dre['revenue']! > 0 ? dre['revenue']! : 1)) * 100).toStringAsFixed(1)}% sobre a receita bruta.',
                style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
              ),
            ),
          ],

          // Footer
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 24),
            child: pw.Center(
              child: pw.Text(
                'Relatório personalizado gerado pelo sistema GEREPAGUE White-Label. Todos os direitos reservados.',
                style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey),
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> generateCashFlowReport(TransactionsProvider provider) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final monthStr = DateFormat('MMMM yyyy', 'pt_BR').format(DateTime(provider.selectedYear, provider.selectedMonth));

    // Dados Filtrados
    final entries = provider.omieAccountsReceivable.where((x) => provider.isWithinCurrentFilterDetailed(x)).toList();
    final exits = provider.omieAccountsPayable.where((x) => provider.isWithinCurrentFilterDetailed(x)).toList();
    
    final totalIn = entries.fold(0.0, (sum, x) => sum + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0));
    final totalOut = exits.fold(0.0, (sum, x) => sum + (double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('FLUXO DE CAIXA DETALHADO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(monthStr.toUpperCase(), style: pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          // Resumo Financeiro
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildKpiCard('Total Entradas', currency.format(totalIn), PdfColors.green900),
              _buildKpiCard('Total Saídas', currency.format(totalOut), PdfColors.red900),
              _buildKpiCard('Saldo Período', currency.format(totalIn - totalOut), (totalIn - totalOut) >= 0 ? PdfColors.blue900 : PdfColors.red900),
            ],
          ),
          pw.SizedBox(height: 30),

          // Tabela de Entradas
          pw.Text('ENTRADAS (RECEITAS)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
          pw.SizedBox(height: 5),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headers: ['Data', 'Cliente', 'Categoria', 'Valor'],
            data: entries.map((x) => [
              x['data_vencimento'] ?? x['dDtVenc'] ?? '',
              provider.omieClients[x['codigo_cliente_fornecedor'].toString()] ?? 'Cliente ${x['codigo_cliente_fornecedor']}',
              provider.omieCategories[x['codigo_categoria']] ?? 'Outros',
              currency.format(double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0),
            ]).toList(),
          ),
          pw.SizedBox(height: 20),

          // Tabela de Saídas
          pw.Text('SAÍDAS (DESPESAS)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
          pw.SizedBox(height: 5),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headers: ['Data', 'Fornecedor', 'Categoria', 'Valor'],
            data: exits.map((x) => [
              x['data_vencimento'] ?? x['dDtVenc'] ?? '',
              provider.omieClients[x['codigo_cliente_fornecedor'].toString()] ?? 'Fornecedor ${x['codigo_cliente_fornecedor']}',
              provider.omieCategories[x['codigo_categoria']] ?? 'Outros',
              currency.format(double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> generateMultiCompany6MonthReport(TransactionsProvider provider) async {
    final pdf = pw.Document();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    // Carregar fontes com suporte Unicode para acentos
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    // Período dinâmico calculado
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final dt = DateTime(now.year, now.month - (5 - i), 1);
      return DateFormat('MMM/yy', 'pt_BR').format(dt);
    });

    final periodRange = '${months.first} - ${months.last}';

    final Map<String, List<double>> consolidatedIncome = {};
    final Map<String, List<double>> consolidatedExpense = {};

    void addToConsolidated(Map<String, List<double>> target, Map<String, List<double>> source) {
      source.forEach((cat, values) {
        if (!target.containsKey(cat)) {
          target[cat] = List.filled(6, 0.0);
        }
        for (int i = 0; i < 6; i++) {
          target[cat]![i] += values[i];
        }
      });
    }

    print('📄 [PDF DEBUG] Total de contas encontradas: ${provider.omieAccounts.length}');

    for (var acc in provider.omieAccounts) {
      if (acc.name == 'Empresa Principal' && provider.omieAccounts.length > 1) continue;
      
      print('📄 [PDF DEBUG] Gerando dados para: ${acc.name}...');
      final dynamicRaw = await provider.get6MonthFlowData(acc.id);
      if (dynamicRaw.isEmpty) continue;

      final incomeMatrix = dynamicRaw['income'] as Map<String, List<double>>;
      final expenseMatrix = dynamicRaw['expense'] as Map<String, List<double>>;

      addToConsolidated(consolidatedIncome, incomeMatrix);
      addToConsolidated(consolidatedExpense, expenseMatrix);

      print('📄 [PDF DEBUG] Adicionando MultiPage: ${acc.name} (${incomeMatrix.length} receitas, ${expenseMatrix.length} despesas)');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          theme: theme,
          header: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('FLUXO DE CAIXA - 6 MESES: ${acc.name.toUpperCase()}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text(periodRange, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
          build: (context) => [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {0: const pw.FixedColumnWidth(160)},
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('DESCRIÇÃO / CATEGORIA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    ...months.map((m) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('RECEITAS OPERACIONAIS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    ...List.generate(7, (_) => pw.SizedBox()),
                  ],
                ),
                ..._buildCategoryRows(incomeMatrix, incomeMatrix.keys.toList()..sort(), PdfColors.blue50, currency),
                _buildSummaryRow('TOTAL RECEITAS (A)', incomeMatrix, incomeMatrix.keys.toList(), PdfColors.blue100, currency),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.orange100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('DESPESAS / DESEMBOLSOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    ...List.generate(7, (_) => pw.SizedBox()),
                  ],
                ),
                ..._buildCategoryRows(expenseMatrix, expenseMatrix.keys.toList()..sort(), PdfColors.orange50, currency),
                _buildSummaryRow('TOTAL DESPESAS (B)', expenseMatrix, expenseMatrix.keys.toList(), PdfColors.orange100, currency),
                _buildDynamicNetProfitRow('SALDO LÍQUIDO (A - B)', incomeMatrix, expenseMatrix, PdfColors.green100, currency),
              ],
            ),
          ],
        ),
      );
    }

    if (consolidatedIncome.isNotEmpty || consolidatedExpense.isNotEmpty) {
      print('📄 [PDF DEBUG] Adicionando MultiPage CONSOLIDADO...');
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          theme: theme,
          header: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('FLUXO DE CAIXA - 6 MESES: CONSOLIDADO (TODAS AS EMPRESAS)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)),
                pw.Text(periodRange, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
          build: (context) => [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {0: const pw.FixedColumnWidth(160)},
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('DESCRIÇÃO / CATEGORIA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    ...months.map((m) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.purple100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('RECEITAS CONSOLIDADAS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    ...List.generate(7, (_) => pw.SizedBox()),
                  ],
                ),
                ..._buildCategoryRows(consolidatedIncome, consolidatedIncome.keys.toList()..sort(), PdfColors.purple50, currency),
                _buildSummaryRow('TOTAL RECEITAS (A)', consolidatedIncome, consolidatedIncome.keys.toList(), PdfColors.purple100, currency),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.orange100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('DESPESAS CONSOLIDADAS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    ...List.generate(7, (_) => pw.SizedBox()),
                  ],
                ),
                ..._buildCategoryRows(consolidatedExpense, consolidatedExpense.keys.toList()..sort(), PdfColors.orange50, currency),
                _buildSummaryRow('TOTAL DESPESAS (B)', consolidatedExpense, consolidatedExpense.keys.toList(), PdfColors.orange100, currency),
                _buildDynamicNetProfitRow('SALDO LÍQUIDO CONSOLIDADO', consolidatedIncome, consolidatedExpense, PdfColors.green100, currency),
              ],
            ),
          ],
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static List<pw.TableRow> _buildCategoryRows(Map<String, List<double>> data, List<String> categories, PdfColor bgColor, NumberFormat currency) {
    return categories.map((cat) {
      final values = data[cat] ?? List.filled(6, 0.0);
      final total = values.fold(0.0, (sum, v) => sum + v);
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bgColor),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(cat.toUpperCase(), style: const pw.TextStyle(fontSize: 6.5))),
          ...values.map((v) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(v == 0 ? '-' : currency.format(v), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 6.5)))),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currency.format(total), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold))),
        ],
      );
    }).toList();
  }

  static pw.TableRow _buildSummaryRow(String label, Map<String, List<double>> data, List<String> categories, PdfColor bgColor, NumberFormat currency) {
    final List<double> totals = List.filled(6, 0.0);
    for (var cat in categories) {
      final values = data[cat] ?? List.filled(6, 0.0);
      for (int i = 0; i < 6; i++) totals[i] += values[i];
    }
    final grandTotal = totals.fold(0.0, (sum, v) => sum + v);

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bgColor),
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(label, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
        ...totals.map((v) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currency.format(v), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)))),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currency.format(grandTotal), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
      ],
    );
  }

  static pw.TableRow _buildDynamicNetProfitRow(String label, Map<String, List<double>> income, Map<String, List<double>> expense, PdfColor bgColor, NumberFormat currency) {
    final List<double> net = List.filled(6, 0.0);
    
    for (int i = 0; i < 6; i++) {
      double inc = 0;
      double exp = 0;
      income.forEach((_, v) => inc += v[i]);
      expense.forEach((_, v) => exp += v[i]);
      net[i] = inc - exp;
    }
    final grandTotal = net.fold(0.0, (sum, v) => sum + v);

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bgColor),
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(label, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
        ...net.map((v) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currency.format(v), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: v >= 0 ? PdfColors.green900 : PdfColors.red900)))),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currency.format(grandTotal), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
      ],
    );
  }

  static pw.Widget _buildKpiCard(String title, String value, PdfColor color) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class SparklineWidget extends pw.Widget {
  final List<double> values;
  final PdfColor color;

  SparklineWidget(this.values, this.color);

  @override
  void layout(pw.Context context, pw.BoxConstraints constraints, {bool parentUsesSize = false}) {
    box = PdfRect.fromPoints(
      PdfPoint.zero,
      constraints.constrain(const PdfPoint(450, 45)),
    );
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    if (values.isEmpty) return;

    final canvas = context.canvas;
    final width = box!.width;
    final height = box!.height;

    final maxVal = values.reduce(math.max);
    final minVal = values.reduce(math.min);
    final range = (maxVal - minVal) <= 0 ? 1.0 : (maxVal - minVal);

    final stepX = width / (values.length - 1);

    canvas.setStrokeColor(color);
    canvas.setLineWidth(2.0);

    for (int i = 0; i < values.length; i++) {
      final x = box!.left + (i * stepX);
      final y = box!.bottom + (((values[i] - minVal) / range) * (height - 6) + 3);

      if (i == 0) {
        canvas.moveTo(x, y);
      } else {
        canvas.lineTo(x, y);
      }
    }
    canvas.strokePath();
  }
}
