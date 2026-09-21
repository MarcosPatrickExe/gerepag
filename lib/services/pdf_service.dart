import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/transactions_provider.dart';

class PdfService {
  static Future<void> generateBusinessReport(TransactionsProvider provider) async {
    final pdf = pw.Document();
    final cur = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Dados
    final dre = provider.omieDRE;
    final history = provider.omieMonthlyBarHistory;
    final abc = provider.abcCurveProducts.take(10).toList();
    final rfv = provider.rfvAnalysis;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RELATÓRIO EXECUTIVO BI BUSINESS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text('Gerado em: $now', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Sigma BI', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue600)),
              ],
            ),
            pw.SizedBox(height: 32),

            // Resumo Financeiro
            pw.Text('1. RESUMO FINANCEIRO (MÊS ATUAL)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildMetricBox('RECEITA BRUTA', cur.format(dre['revenue']), PdfColors.green900),
                _buildMetricBox('EBITDA', cur.format(provider.omieEBITDA), PdfColors.blue900),
                _buildMetricBox('RESULTADO LÍQUIDO', cur.format(dre['profit']), PdfColors.orange900),
              ],
            ),
            pw.SizedBox(height: 32),

            // Tendência
            pw.Text('2. TENDÊNCIA DOS ÚLTIMOS 12 MESES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Mês', 'Receita', 'Despesa', 'Líquido'],
              data: history.map((e) => [
                e['month'],
                cur.format(e['income']),
                cur.format(e['expense']),
                cur.format(e['net']),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellAlignment: pw.Alignment.centerRight,
              cellAlignments: {0: pw.Alignment.centerLeft},
            ),
            pw.SizedBox(height: 32),

            // Curva ABC
            pw.Text('3. TOP 10 PRODUTOS (CURVA ABC)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Produto', 'Faturamento', '%', 'Classe'],
              data: abc.map((e) => [
                e['name'],
                cur.format(e['value']),
                '${(e['percent'] as double).toStringAsFixed(1)}%',
                e['class'],
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
            ),
          ];
        },
      ),
    );

    // Salvar e Abrir
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildMetricBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
