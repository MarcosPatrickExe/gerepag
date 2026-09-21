import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/config_service.dart';
import '../providers/transactions_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiAction {
  final String type; // 'whatsapp_cobrança', 'ajuste_orcamento', etc
  final Map<String, dynamic> data;

  AiAction({required this.type, required this.data});
}

class AiInsightResult {
  final String title;
  final String message;
  final String severity; // 'info', 'warning', 'critical'
  final DateTime timestamp;
  final AiAction? action;

  AiInsightResult({
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.action,
  });

  factory AiInsightResult.empty() => AiInsightResult(
    title: 'Análise em andamento',
    message: 'A IA está processando seus dados financeiros...',
    severity: 'info',
    timestamp: DateTime.now(),
  );
}

class AiInsightService {
  final ConfigService _config = ConfigService();
  GenerativeModel? _geminiModel;

  Future<AiInsightResult?> getSmartAlert(TransactionsProvider provider) async {
    final String providerName = await _config.getAiProvider();
    final bool autoBusinessAi = await _config.getAutoBusinessAi();
    
    // Se estiver no modo Omie/Empresa e a automação estiver ligada, força OpenAI
    bool useOpenAI = providerName == 'openai';
    if (provider.isBusinessMode && autoBusinessAi) {
      useOpenAI = true;
    }

    if (useOpenAI) {
      return _getOpenAIInsight(provider);
    } else {
      return _getGeminiInsight(provider);
    }
  }

  Future<AiInsightResult?> _getGeminiInsight(TransactionsProvider provider) async {
    final apiKey = await _config.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty || apiKey == 'API_KEY_AQUI') return null;

    if (_geminiModel == null) {
      final modelsToTry = [
        {'name': 'gemini-1.5-flash', 'version': 'v1'},
        {'name': 'gemini-pro', 'version': 'v1'},
        {'name': 'gemini-1.5-flash', 'version': 'v1beta'},
      ];

      for (var m in modelsToTry) {
        try {
          final testModel = GenerativeModel(
            model: m['name']!,
            apiKey: apiKey,
            requestOptions: RequestOptions(apiVersion: m['version']),
          );
          await testModel.countTokens([Content.text('ping')]);
          _geminiModel = testModel;
          break;
        } catch (e) {
          _geminiModel = null;
        }
      }
    }

    final prompt = _buildPrompt(provider);

    try {
      final response = await _geminiModel!.generateContent([Content.text(prompt)]);
      return _parseResponse(response.text);
    } catch (e) {
      print('Erro Gemini: $e');
      return null;
    }
  }

  Future<AiInsightResult?> _getOpenAIInsight(TransactionsProvider provider) async {
    final apiKey = await _config.getOpenAIApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      // Fallback para Gemini se a chave da OpenAI não existir
      return _getGeminiInsight(provider);
    }

    final prompt = _buildPrompt(provider);

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
            {'role': 'system', 'content': 'Você é um CFO virtual especializado em ERP Omie e finanças brasileiras. Responda apenas em JSON.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return _parseResponse(content);
      } else {
        print('Erro OpenAI HTTP: ${response.body}');
        return _getGeminiInsight(provider); // Fallback
      }
    } catch (e) {
      print('Erro OpenAI: $e');
      return null;
    }
  }

  String _buildPrompt(TransactionsProvider provider) {
    final summary = provider.omieSummary ?? {};
    final recentExpenses = provider.expenseByCategoryRank;
    final overdue = provider.omieOverdue;
    
    return '''
Analise os dados financeiros abaixo e identifique UMA anomalia ou insight crítico.
DADOS:
- Saldo: ${summary['contaCorrente']?['vTotal'] ?? 'N/A'}
- Receita Mes: ${provider.monthIncome}
- Despesa Mes: ${provider.monthExpense}
- Inadimplência (Atrasados): $overdue
- Gastos/Categoria: $recentExpenses

Responda APENAS um JSON:
{
  "title": "Máximo 5 palavras",
  "message": "Máximo 20 palavras",
  "severity": "info" ou "warning" ou "critical",
  "action": {
    "type": "whatsapp_cobrança",
    "data": {
      "phone": "55XXXXXXXXXXX",
      "text": "Mensagem persuasiva sugerida pela IA"
    }
  } (opcional, envie apenas se severity for critical/warning e houver inadimplência)
}
''';
  }

  AiInsightResult? _parseResponse(String? text) {
    if (text == null) return null;
    try {
      final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> data = jsonDecode(cleanJson);

      AiAction? action;
      if (data['action'] != null) {
        action = AiAction(
          type: data['action']['type'],
          data: Map<String, dynamic>.from(data['action']['data']),
        );
      }

      return AiInsightResult(
        title: data['title'] ?? 'Insight Financeiro',
        message: data['message'] ?? 'Análise concluída.',
        severity: data['severity'] ?? 'info',
        timestamp: DateTime.now(),
        action: action,
      );
    } catch (e) {
      return null;
    }
  }
}
