import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/config_service.dart';

class ExtractedDocument {
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final String type; // 'expense' ou 'income'

  ExtractedDocument({
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.type,
  });

  factory ExtractedDocument.fromJson(Map<String, dynamic> json) {
    return ExtractedDocument(
      amount: double.tryParse(json['valor']?.toString() ?? '0') ?? 0.0,
      description: json['descricao'] ?? 'Documento Digital',
      category: json['categoria'] ?? 'Outros',
      date: DateTime.tryParse(json['data'] ?? '') ?? DateTime.now(),
      type: json['tipo'] ?? 'expense',
    );
  }
}

class DocumentAiService {
  final ConfigService _config = ConfigService();

  Future<ExtractedDocument?> processDocument(Uint8List bytes, String mimeType) async {
    final provider = await _config.getAiProvider();
    
    if (provider == 'openai') {
      return _processDocumentWithOpenAI(bytes, mimeType);
    } else {
      return _processDocumentWithGemini(bytes, mimeType);
    }
  }

  Future<ExtractedDocument?> _processDocumentWithOpenAI(Uint8List bytes, String mimeType) async {
    final apiKey = await _config.getOpenAIApiKey();
    if (apiKey == null || apiKey.isEmpty) throw Exception('API Key da OpenAI não configurada.');

    final base64Image = base64Encode(bytes);
    final prompt = _buildDocumentPrompt();

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:$mimeType;base64,$base64Image'}
                }
              ]
            }
          ],
          'temperature': 0.1,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final Map<String, dynamic> jsonData = jsonDecode(content);
        return ExtractedDocument.fromJson(jsonData);
      } else {
        print('Erro OpenAI Vision HTTP: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erro OpenAI Vision: $e');
      return null;
    }
  }

  Future<ExtractedDocument?> _processDocumentWithGemini(Uint8List bytes, String mimeType) async {
    final apiKey = await _config.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty || apiKey == 'API_KEY_AQUI') return null;

    final modelsToTry = [
      {'name': 'gemini-1.5-flash', 'version': 'v1'},
      {'name': 'gemini-pro', 'version': 'v1'},
    ];

    GenerativeModel? model;
    for (var m in modelsToTry) {
      try {
        final testModel = GenerativeModel(
          model: m['name']!,
          apiKey: apiKey,
          requestOptions: RequestOptions(apiVersion: m['version']),
        );
        await testModel.countTokens([Content.text('ping')]);
        model = testModel;
        break;
      } catch (e) {
        model = null;
      }
    }

    if (model == null) return null;

    try {
      final prompt = _buildDocumentPrompt();
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, bytes),
        ])
      ];

      final response = await model.generateContent(content);
      final text = response.text;
      if (text == null) return null;

      final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> data = jsonDecode(cleanJson);
      return ExtractedDocument.fromJson(data);
    } catch (e) {
      print('Erro Gemini Document AI: $e');
      return null;
    }
  }

  String _buildDocumentPrompt() {
    return '''
Analise este documento financeiro (nota fiscal, boleto ou recibo) e extraia os dados abaixo apenas em formato JSON.
Se for um boleto a pagar, o tipo é 'expense'. Se for uma nota de venda recebida, o tipo é 'income'.

Campos obrigatórios no JSON:
{
  "valor": 0.0,
  "descricao": "Nome do estabelecimento ou serviço",
  "categoria": "Sugestão de categoria (Alimentação, Transporte, Saúde, etc)",
  "data": "YYYY-MM-DD",
  "tipo": "expense" ou "income"
}
Responda APENAS o JSON puro.
''';
  }

  Future<List<ExtractedDocument>> processBankStatement(Uint8List bytes, String mimeType) async {
    final apiKey = await _config.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty || apiKey == 'API_KEY_AQUI') return [];

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      requestOptions: const RequestOptions(apiVersion: 'v1'),
    );

    try {
      final prompt = _buildBankStatementPrompt();
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, bytes),
        ])
      ];

      final response = await model.generateContent(content);
      final text = response.text;
      if (text == null) return [];

      final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> data = jsonDecode(cleanJson);
      return data.map((item) => ExtractedDocument.fromJson(item)).toList();
    } catch (e) {
      print('Erro Gemini Bank Statement: $e');
      return [];
    }
  }

  String _buildBankStatementPrompt() {
    return '''
Analise este extrato bancário e extraia TODOS os lançamentos financeiros em formato de lista JSON.
Ignore saldos parciais, focando apenas nas movimentações (entradas e saídas).

Para cada lançamento, retorne:
{
  "valor": 0.0,
  "descricao": "Descrição clara do lançamento",
  "categoria": "Sugestão de categoria (Tarifa, Venda, Pagamento, Transferência, etc)",
  "data": "YYYY-MM-DD",
  "tipo": "expense" (para saídas/débitos) ou "income" (para entradas/créditos)
}

Responda APENAS a lista JSON, sem textos adicionais.
Exemplo: [{"valor": 50.0, ...}, {"valor": 100.0, ...}]
''';
  }

  Future<String> analyzeRawText(String text) async {
    final provider = await _config.getAiProvider();
    final apiKey = provider == 'openai' ? await _config.getOpenAIApiKey() : await _config.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) return '';

    if (provider == 'openai') {
      return _analyzeTextWithOpenAI(text, apiKey);
    } else {
      return _analyzeTextWithGemini(text, apiKey);
    }
  }

  Future<String> _analyzeTextWithOpenAI(String text, String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [{'role': 'user', 'content': text}],
          'temperature': 0.7,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
    } catch (e) {
      print('Erro OpenAI Text: $e');
    }
    return '';
  }

  Future<String> _analyzeTextWithGemini(String text, String apiKey) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    try {
      final response = await model.generateContent([Content.text(text)]);
      return response.text ?? '';
    } catch (e) {
      print('Erro Gemini Text: $e');
      return '';
    }
  }
}
