import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class CsvExportService {
  static Future<String?> exportTransactionsToCsv(List<TransactionModel> transactions) async {
    try {
      List<List<dynamic>> rows = [];

      // Cabeçalho
      rows.add(['Data', 'Categoria', 'Valor', 'Tipo']);

      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      for (var t in transactions) {
        rows.add([
          dateFormat.format(t.date),
          t.category,
          t.amount,
          t.type == TransactionType.expense ? 'Saída' : 'Entrada',
        ]);
      }

      String csvContent = const ListToCsvConverter().convert(rows);

      // Salvar arquivo
      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/transacoes_real_${DateTime.now().millisecondsSinceEpoch}.csv';
      final File file = File(path);
      
      await file.writeAsString(csvContent);
      return path;
    } catch (e) {
      print('Erro ao exportar CSV: $e');
      return null;
    }
  }
}
