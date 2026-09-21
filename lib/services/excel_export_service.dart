import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../providers/transactions_provider.dart';

class ExcelExportService {
  static Future<void> exportToExcel(TransactionsProvider provider) async {
    final excel = Excel.createExcel();
    final Sheet sheetObject = excel['GerePag_Relatorio'];
    excel.delete('Sheet1'); // Remove a aba padrão

    final List<String> header = [
      'Data Vencimento',
      'Descrição',
      'Categoria',
      'Cliente/Fornecedor',
      'Valor (R\$)',
      'Status',
      'Tipo'
    ];

    // Estilizar cabeçalho
    var headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#1E293B'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    for (var i = 0; i < header.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(header[i]);
        cell.cellStyle = headerStyle;
    }

    // Unificar transações a pagar e a receber
    final List<dynamic> allTransactions = [
      ...provider.omieAccountsReceivable.map((x) => {...x, 'type': 'RECEBER'}),
      ...provider.omieAccountsPayable.map((x) => {...x, 'type': 'PAGAR'}),
    ];

    // Filtrar pelo período selecionado no provider
    final filtered = allTransactions.where((x) {
        final dtStr = x['data_vencimento'] ?? x['dDtVenc'];
        if (dtStr == null) return false;
        final DateTime dt = DateTime.parse(dtStr.toString());
        
        bool result = false;
        switch (provider.filterMode) {
          case OmieFilterMode.daily:
            result = provider.selectedSpecificDate != null &&
                   dt.day == provider.selectedSpecificDate!.day &&
                   dt.month == provider.selectedSpecificDate!.month &&
                   dt.year == provider.selectedSpecificDate!.year;
            break;
          case OmieFilterMode.monthly:
            result = dt.month == provider.selectedMonth && dt.year == provider.selectedYear;
            break;
          case OmieFilterMode.yearly:
            result = dt.year == provider.selectedYear;
            break;
          case OmieFilterMode.custom:
            if (provider.rangeStart != null && provider.rangeEnd != null) {
              result = dt.isAfter(provider.rangeStart!.subtract(const Duration(days: 1))) &&
                     dt.isBefore(provider.rangeEnd!.add(const Duration(days: 1)));
            }
            break;
        }
        return result;
    }).toList();

    // Ordenar por data
    filtered.sort((a, b) {
      final da = DateTime.parse((a['data_vencimento'] ?? a['dDtVenc']).toString());
      final db = DateTime.parse((b['data_vencimento'] ?? b['dDtVenc']).toString());
      return da.compareTo(db);
    });

    // Inserir dados
    for (var i = 0; i < filtered.length; i++) {
      final x = filtered[i];
      final date = x['data_vencimento'] ?? x['dDtVenc'] ?? '';
      final desc = x['descricao'] ?? x['cDescr'] ?? 'Sem descrição';
      final cat = provider.omieCategories[x['codigo_categoria'] ?? x['cCodCategor']] ?? 'Outros';
      final client = provider.omieClients[x['codigo_cliente_fornecedor']?.toString() ?? x['nCodCliente']?.toString()] ?? 'N/A';
      final val = double.tryParse(x['valor_documento']?.toString() ?? x['vValor']?.toString() ?? '0') ?? 0.0;
      final status = x['status_titulo'] ?? (x['cStatus'] == 'P' ? 'PAGO' : 'ABERTO');
      final type = x['type'];

      sheetObject.appendRow([
        TextCellValue(date.toString()),
        TextCellValue(desc.toString()),
        TextCellValue(cat.toString()),
        TextCellValue(client.toString()),
        DoubleCellValue(val),
        TextCellValue(status.toString()),
        TextCellValue(type.toString()),
      ]);
    }

    // Salvar e Compartilhar
    final List<int>? fileBytes = excel.save();
    if (fileBytes != null) {
        final directory = await getTemporaryDirectory();
        final fileName = 'Relatorio_GerePag_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(fileBytes);
        
        await Share.shareXFiles([XFile(file.path)], text: 'Relatório Financeiro GerePag');
    }
  }
}
