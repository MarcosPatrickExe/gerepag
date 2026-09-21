import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../services/config_service.dart';

class CoachInsight {
  final String text;
  final String category;
  final double potentialSaving;

  CoachInsight({required this.text, this.category = 'Geral', this.potentialSaving = 0.0});
}

class CoachService {
  static final CoachService _instance = CoachService._internal();
  factory CoachService() => _instance;
  CoachService._internal();

  final ConfigService _config = ConfigService();
  GenerativeModel? _model;

  Future<void> _ensureGeminiInitialized() async {
    if (_model != null) return;
    
    final apiKey = await _config.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty || apiKey == 'API_KEY_AQUI') return;

    final modelsToTry = [
      {'name': 'gemini-1.5-flash', 'version': 'v1'},
      {'name': 'gemini-pro', 'version': 'v1'},
    ];

    for (var m in modelsToTry) {
      try {
        final testModel = GenerativeModel(
          model: m['name']!,
          apiKey: apiKey,
          requestOptions: RequestOptions(apiVersion: m['version']),
        );
        await testModel.countTokens([Content.text('ping')]);
        _model = testModel;
        return; 
      } catch (e) {
        _model = null;
      }
    }
  }

  void init(String apiKey) {}

  Future<CoachInsight?> generateDailyInsight(List<TransactionModel> transactions) async {
    final provider = await _config.getAiProvider();
    
    if (provider == 'openai') {
      return _getOpenAICoachInsight(transactions);
    } else {
      return _getGeminiCoachInsight(transactions);
    }
  }

  Future<CoachInsight?> _getOpenAICoachInsight(List<TransactionModel> transactions) async {
    final apiKey = await _config.getOpenAIApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final prompt = _buildCoachPrompt(transactions);

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
            {'role': 'system', 'content': 'Você é um Coach Financeiro de Elite. Responda apenas com o conselho curto.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 100,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'];
        return CoachInsight(text: text);
      }
    } catch (e) {
      print('Erro Coach OpenAI: $e');
    }
    return null;
  }

  Future<CoachInsight?> _getGeminiCoachInsight(List<TransactionModel> transactions) async {
    await _ensureGeminiInitialized();
    if (_model == null || transactions.isEmpty) return null;

    final prompt = _buildCoachPrompt(transactions);

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      if (response.text != null) {
        return CoachInsight(text: response.text!);
      }
    } catch (e) {
      print('Erro no Coach Gemini: $e');
    }
    return null;
  }

  String _buildCoachPrompt(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return 'Dê um conselho geral sobre economia e motivação financeira.';
    
    final now = DateTime.now();
    final thisMonthExpenses = transactions
        .where((t) => t.type == TransactionType.expense && t.date.month == now.month && t.date.year == now.year)
        .toList();
    
    final totalSpentThisMonth = thisMonthExpenses.fold(0.0, (sum, t) => sum + t.amount);
    final dayOfMonth = now.day;
    final burnRate = totalSpentThisMonth / dayOfMonth;
    final projectedTotal = burnRate * 30;

    final history = transactions.map((t) => '${t.category}: R\$ ${t.amount} (${t.type.name})').take(30).join('\n');
    
    return '''
    Você é um Coach Financeiro de Elite e Preditivo.
    
    DADOS ATUAIS:
    - Gastou até agora este mês: R\$ ${totalSpentThisMonth.toStringAsFixed(2)} (Dia $dayOfMonth)
    - Ritmo diário: R\$ ${burnRate.toStringAsFixed(2)}
    - Projeção para o fim do mês: R\$ ${projectedTotal.toStringAsFixed(2)}
    
    HISTÓRICO RECENTE:
    $history
    
    SUA MISSÃO:
    1. Analise o ritmo (burn rate). Se a projeção for alta demais (ex: > R\$ 2000 ou muito acima do normal), alerte proativamente ("Vinícius, você costuma gastar X até tal dia...").
    2. Dê UM ÚNICO conselho focado em PREVISÃO e COMPORTAMENTO.
    3. Seja curto, impactante e use emojis (máximo 160 caracteres).
    4. Responda apenas com o texto do conselho.
    ''';
  }
}
