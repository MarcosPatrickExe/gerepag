import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class BpoClientSnap {
  final double income, expense;
  final int txCount;
  const BpoClientSnap({required this.income, required this.expense, required this.txCount});
}

class BpoPdfService {
  static Future<void> generateAndPrintExecutivePdf({
    required String clientName,
    required String regime,
    required BpoClientSnap snap,
    required String accountantNotes,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final monthYear = DateFormat('MMMM yyyy', 'pt_BR').format(now);

    final double balance = snap.income - snap.expense;
    final double margin = snap.income > 0 ? (balance / snap.income) * 100 : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('RELATORIO EXECUTIVO BPO FINANCEIRO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  pw.Text('CLIENTE: $clientName (${regime.toUpperCase()})', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(monthYear.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Emitido em: $formattedDate', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 2, color: PdfColors.indigo900),
          pw.SizedBox(height: 20),

          // Painel Geral de Indicadores
          pw.Text('SUMARIO FINANCEIRO MENSAL', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green300), borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Column(children: [
                  pw.Text('RECEITAS', style: pw.TextStyle(fontSize: 8, color: PdfColors.green900, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(currency.format(snap.income), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                ]),
              )),
              pw.SizedBox(width: 12),
              pw.Expanded(child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.red50, border: pw.Border.all(color: PdfColors.red300), borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Column(children: [
                  pw.Text('DESPESAS', style: pw.TextStyle(fontSize: 8, color: PdfColors.red900, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(currency.format(snap.expense), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                ]),
              )),
              pw.SizedBox(width: 12),
              pw.Expanded(child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: balance >= 0 ? PdfColors.blue50 : PdfColors.amber50, 
                  border: pw.Border.all(color: balance >= 0 ? PdfColors.blue300 : PdfColors.amber300), 
                  borderRadius: pw.BorderRadius.circular(6)
                ),
                child: pw.Column(children: [
                  pw.Text('SALDO LIQUIDO', style: pw.TextStyle(fontSize: 8, color: balance >= 0 ? PdfColors.blue900 : PdfColors.amber900, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(currency.format(balance), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: balance >= 0 ? PdfColors.blue900 : PdfColors.amber900)),
                ]),
              )),
            ],
          ),
          pw.SizedBox(height: 20),

          // Margem Operacional
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('MARGEM DE SOBRA OPERACIONAL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('${margin.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: margin >= 0 ? PdfColors.green900 : PdfColors.red900)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Nota Estratégica do BPO / Parecer do Contador
          pw.Text('PARECER E DIRETRIZES DO CONSULTOR CONTABIL/BPO', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border(left: pw.BorderSide(color: PdfColors.indigo900, width: 4)),
            ),
            child: pw.Text(
              accountantNotes.isNotEmpty ? accountantNotes : 'Nenhuma nota ou parecer adicional registrado para este periodo pelo consultor financeiro responsável.',
              style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, height: 1.4),
            ),
          ),
          pw.SizedBox(height: 40),

          // Assinaturas
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(children: [
                pw.Container(width: 150, height: 1, color: PdfColors.grey500),
                pw.SizedBox(height: 4),
                pw.Text('BPO Financeiro Responsável', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ]),
              pw.Column(children: [
                pw.Container(width: 150, height: 1, color: PdfColors.grey500),
                pw.SizedBox(height: 4),
                pw.Text('Representante do Cliente', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ]),
            ],
          ),

          // Footer
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 60),
            child: pw.Center(child: pw.Text('Documento emitido digitalmente pela plataforma GEREPAGUE. Todos os direitos reservados.', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey))),
          )
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
