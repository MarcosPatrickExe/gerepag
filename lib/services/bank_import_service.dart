import 'dart:convert';
import 'package:csv/csv.dart';
import '../models/transaction_model.dart';
import 'document_ai_service.dart';

class BankImportService {
  final DocumentAiService _aiService = DocumentAiService();

  /// Analisar conteúdo de arquivo OFX (Extrato Bancário)
  List<Map<String, dynamic>> parseOFX(String content) {
    final List<Map<String, dynamic>> items = [];
    final transactions = content.split('<STMTTRN>');
    
    // Pular o primeiro elemento que é o cabeçalho
    for (var i = 1; i < transactions.length; i++) {
      final t = transactions[i];
      
      final amount = _extractTag(t, 'TRNAMT');
      final date = _extractTag(t, 'DTPOSTED');
      final memo = _extractTag(t, 'MEMO') ?? _extractTag(t, 'NAME') ?? 'Transação';
      
      if (amount != null && date != null) {
        items.add({
          'amount': double.tryParse(amount) ?? 0.0,
          'date': _parseOFXDate(date),
          'description': memo,
        });
      }
    }
    return items;
  }

  /// Analisar conteúdo de CSV
  List<Map<String, dynamic>> parseCSV(String content) {
    const converter = CsvToListConverter();
    final rows = converter.convert(content);
    final List<Map<String, dynamic>> items = [];

    // Tentar identificar colunas (Data, Descrição, Valor)
    // Suposição básica: [Data, Descrição, Valor]
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length >= 3) {
        items.add({
          'date': row[0].toString(),
          'description': row[1].toString(),
          'amount': double.tryParse(row[2].toString().replaceAll(',', '.')) ?? 0.0,
        });
      }
    }
    return items;
  }

  String? _extractTag(String text, String tag) {
    final regExp = RegExp('<$tag>([^<\\n\\r]+)');
    final match = regExp.firstMatch(text);
    return match?.group(1)?.trim();
  }

  DateTime _parseOFXDate(String raw) {
    // Exemplo: 20240421120000[-03:EST]
    if (raw.length >= 8) {
      final year = int.parse(raw.substring(0, 4));
      final month = int.parse(raw.substring(4, 6));
      final day = int.parse(raw.substring(6, 8));
      return DateTime(year, month, day);
    }
    return DateTime.now();
  }

  /// Processar documentos extraídos via IA para o modelo de transação
  List<TransactionModel> processExtractedDocuments(List<ExtractedDocument> docs) {
    return docs.map((doc) => TransactionModel(
      id: '',
      description: doc.description,
      amount: doc.amount,
      category: doc.category,
      date: doc.date,
      type: doc.type == 'income' ? TransactionType.income : TransactionType.expense,
    )).toList();
  }

  /// Usar Gemini para categorizar transações importadas em lote
  Future<List<TransactionModel>> enrichWithAI(List<Map<String, dynamic>> rawItems) async {
    if (rawItems.isEmpty) return [];

    final prompt = """
Analise os seguintes lançamentos de extrato bancário e sugira uma categoria financeira para cada um.
Categorias sugeridas: Alimentação, Transporte, Moradia, Lazer, Saúde, Mercantil, Salários, Impostos, Tarifas, Outros.

Lançamentos:
${rawItems.map((item) => "- ${item['description']} (${item['amount']})").join('\n')}

Responda APENAS em formato JSON:
[{"description": "...", "category": "...", "amount": 123.45, "type": "expense/income"}]
""";

    try {
      final response = await _aiService.analyzeRawText(prompt);
      final List<dynamic> jsonList = jsonDecode(response);
      
      final List<TransactionModel> transactions = [];
      for (var i = 0; i < rawItems.length; i++) {
        final aiMatch = jsonList.length > i ? jsonList[i] : null;
        
        transactions.add(TransactionModel(
          id: '', // Será gerado pelo banco
          description: rawItems[i]['description'],
          amount: (rawItems[i]['amount'] as double).abs(),
          category: aiMatch?['category'] ?? 'Outros',
          date: rawItems[i]['date'] is DateTime ? rawItems[i]['date'] : DateTime.now(),
          type: (rawItems[i]['amount'] as double) >= 0 ? TransactionType.income : TransactionType.expense,
        ));
      }
      return transactions;
    } catch (e) {
      print('Erro na categorização AI: $e');
      // Fallback para categorização manual
      return rawItems.map((item) => TransactionModel(
        id: '',
        description: item['description'],
        amount: (item['amount'] as double).abs(),
        category: 'Outros',
        date: item['date'] is DateTime ? item['date'] : DateTime.now(),
        type: (item['amount'] as double) >= 0 ? TransactionType.income : TransactionType.expense,
      )).toList();
    }
  }
}
