import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/config_service.dart';
import '../services/realtime_db_service.dart';
import '../providers/transactions_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiChatService {
  final ConfigService _config = ConfigService();
  GenerativeModel? _model;
  ChatSession? _chat;

  Future<void> _ensureGeminiInitialized() async {
    if (_model != null) return;
    
    final apiKeys = await _config.getGeminiApiKeys();
    
    final List<Map<String, String>> modelsToTry = [
      {'name': 'gemini-3.1-flash-preview', 'version': 'v1beta'},
      {'name': 'gemini-3.1-flash-lite-preview', 'version': 'v1beta'},
      {'name': 'gemini-1.5-flash', 'version': 'v1'},
      {'name': 'gemini-pro', 'version': 'v1'},
    ];

    for (var key in apiKeys) {
      for (var m in modelsToTry) {
        try {
          final testModel = GenerativeModel(
            model: m['name']!,
            apiKey: key,
            requestOptions: RequestOptions(apiVersion: m['version']),
          );
          
          await testModel.countTokens([Content.text('ping')]);
          
          _model = testModel;
          _chat = _model!.startChat();
          print('✅ [Glauber Chat] Modelo: ${m['name']} (Key: ${key.substring(0, 4)}...)');
          return; 
        } catch (e) {
          _model = null;
        }
      }
    }
  }

  AiChatService();

  Future<String> getAdvice(String message, List<TransactionModel> transactions, {String? businessContext}) async {
    final provider = await _config.getAiProvider();

    // Carregar Perfil do Glauber
    String assistantName = 'Glauber';
    String personality = 'profissional';
    List<String> memories = [];
    try {
      final profile = await RealtimeDbService().getGlauberProfile().first;
      if (profile.isNotEmpty) {
        assistantName = profile['name']?.toString() ?? 'Glauber';
        personality = profile['personality']?.toString() ?? 'profissional';
        if (profile['memories'] != null) {
          memories = List<String>.from(profile['memories']);
        }
      }
    } catch (_) {}

    final systemContext = _buildSystemContext(
      transactions,
      businessContext,
      assistantName: assistantName,
      personality: personality,
      memories: memories,
    );
    
    if (provider == 'openai') {
      return _getOpenAIAdvice(message, systemContext, assistantName);
    } else {
      return _getGeminiAdvice(message, systemContext, assistantName);
    }
  }

  Future<String> _getOpenAIAdvice(String message, String context, String assistantName) async {
    final apiKey = await _config.getOpenAIApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'Ops! Você selecionou ChatGPT mas ainda não configurou a API Key no cofre.';
    }

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
            {'role': 'system', 'content': context},
            {'role': 'user', 'content': message}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('Erro OpenAI HTTP: ${response.body}');
        return 'Erro ao falar com o ChatGPT: ${response.statusCode}. Tente o Gemini no cofre.';
      }
    } catch (e) {
      return 'Erro na conexão com a OpenAI: $e';
    }
  }

  Future<String> _getGeminiAdvice(String message, String context, String assistantName) async {
    await _ensureGeminiInitialized();
    if (_model == null) {
      return 'Ops! Você ainda não configurou a API Key do Gemini no cofre (Ctrl+K -> Administrador).';
    }

    try {
      final response = await _chat!.sendMessage(Content.text('$context\n\nPergunta do usuário: $message'));
      return response.text ?? 'Peço desculpas, não consegui gerar uma resposta agora.';
    } catch (e) {
      // Se der erro de sobrecarga (503), tentar resetar e usar outro modelo/chave uma vez
      if (e.toString().contains('503') || e.toString().contains('high demand')) {
        print('🔄 [$assistantName] Sobrecarga detectada. Tentando trocar de modelo/chave...');
        _model = null; // Forçar reinicialização
        _chat = null;
        await _ensureGeminiInitialized();
        if (_model != null) {
          try {
             final response = await _chat!.sendMessage(Content.text('$context\n\nPergunta do usuário: $message'));
             return response.text ?? 'Tentei outro modelo, mas não houve resposta.';
          } catch (e2) {
             return 'Mesmo trocando de modelo, o Google está instável hoje: $e2';
          }
        }
      }
      return 'Erro ao falar com o consultor $assistantName: $e';
    }
  }

  String _buildSystemContext(
    List<TransactionModel> transactions,
    String? businessContext, {
    required String assistantName,
    required String personality,
    required List<String> memories,
  }) {
    // Agrupar transações pessoais por categoria para o contexto
    final Map<String, double> personalCategories = {};
    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        personalCategories[t.category] = (personalCategories[t.category] ?? 0) + t.amount;
      }
    }
    
    final sortedCats = personalCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final catSummary = sortedCats.take(10).map((e) => "${e.key}: R\$ ${e.value.toStringAsFixed(2)}").join(", ");

    double personalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, item) => sum + item.amount);
    
    double personalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, item) => sum + item.amount);
    
    final recentHistory = transactions.take(15).map((t) => "${t.description} (R\$ ${t.amount})").join(" | ");

    String toneInstructions = '';
    if (personality == 'friendly') {
      toneInstructions = 'Você deve responder com um tom amigável, casual, empático e descontraído, usando emojis eventuais.';
    } else if (personality == 'assertive') {
      toneInstructions = 'Você deve responder com um tom assertivo, direto ao ponto, realista, firme e de alta cobrança, sem rodeios.';
    } else {
      toneInstructions = 'Você deve responder de forma profissional, elegante, polida e didática.';
    }

    String memoryPrompt = memories.isNotEmpty
        ? 'FATOS QUE VOCÊ LEMBRA SOBRE O NEGÓCIO/USUÁRIO (USE PARA PERSONALIZAR A RESPOSTA):\n' + memories.map((m) => '- $m').join('\n')
        : '';

    return '''
Você é o $assistantName, o consultor financeiro de elite do usuário. $toneInstructions
Sua missão é dar conselhos ultra-estratégicos cruzando o que ele gasta no dia a dia com a saúde da empresa dele.

$memoryPrompt

DADOS RECENTES (PESSOAL):
- Histórico: $recentHistory
- Top 10 Categorias: $catSummary
- Saldo Pessoal Estimado: R\$ ${(personalIncome - personalExpense).toStringAsFixed(2)}
- Entradas Mês: R\$ ${personalIncome.toStringAsFixed(2)}
- Saídas Mês: R\$ ${personalExpense.toStringAsFixed(2)}

${businessContext ?? 'CONTEXTO EMPRESARIAL: Nenhuma conta Omie conectada. Foque 100% no financeiro pessoal dele.'}

DIRETRIZES DO ASSISTENTE:
1. Analise o comportamento: Se você vir muitos gastos repetidos no histórico, aponte isso de forma inteligente.
2. Tom de voz: Personalizado conforme as instruções acima.
3. Respostas impactantes: Responda em Português do Brasil de forma concisa.
''';
  }

  Future<String> generateNegotiationProposal({
    required String contactName,
    required double amount,
    required String dueDate,
    required String description,
    required String type,
  }) async {
    final provider = await _config.getAiProvider();

    // Carregar Perfil do Glauber
    String assistantName = 'Glauber';
    String personality = 'profissional';
    List<String> memories = [];
    try {
      final profile = await RealtimeDbService().getGlauberProfile().first;
      if (profile.isNotEmpty) {
        assistantName = profile['name']?.toString() ?? 'Glauber';
        personality = profile['personality']?.toString() ?? 'profissional';
        if (profile['memories'] != null) {
          memories = List<String>.from(profile['memories']);
        }
      }
    } catch (_) {}

    String tonePrompt = '';
    if (personality == 'friendly') {
      tonePrompt = 'Escreva com tom amigável, simpático, empático e informal (pode usar emojis).';
    } else if (personality == 'assertive') {
      tonePrompt = 'Escreva com tom altamente assertivo, direto ao ponto, firme e realista, sem rodeios desnecessários.';
    } else {
      tonePrompt = 'Escreva com tom profissional, educado, polido e formal.';
    }

    String memoryPrompt = memories.isNotEmpty
        ? 'Fatos que você lembra sobre o usuário/negócio para contextualizar a mensagem:\n' + memories.map((m) => '- $m').join('\n')
        : '';
    
    final prompt = type == 'receber'
        ? 'Você se chama $assistantName. $tonePrompt\n$memoryPrompt\nEscreva uma mensagem de cobrança amigável e extremamente polida para enviar no WhatsApp ou E-mail para $contactName. O valor em aberto é de R\$ ${amount.toStringAsFixed(2)}, com data de vencimento em $dueDate, referente a "$description". Ofereça espaço para que ele(a) envie o comprovante ou nos dê uma previsão de pagamento.'
        : 'Você se chama $assistantName. $tonePrompt\n$memoryPrompt\nEscreva uma proposta de renegociação de dívida educada, humilde e profissional para enviar a um fornecedor chamado $contactName. O valor do boleto em aberto/vencido é de R\$ ${amount.toStringAsFixed(2)}, com data de vencimento em $dueDate, referente a "$description". Explique de forma genérica que houve um descasamento temporário no fluxo de caixa e proponha prorrogar o vencimento por 15 a 30 dias, ou parcelar o valor em 2x, perguntando se é viável para eles.';

    if (provider == 'openai') {
      final apiKey = await _config.getOpenAIApiKey();
      if (apiKey == null || apiKey.isEmpty) return 'Configure a OpenAI no cofre.';
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
              {'role': 'system', 'content': 'Você é o $assistantName, um assistente financeiro inteligente especializado em negociação de cobranças e dívidas com fornecedores.'},
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.7,
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        }
      } catch (_) {}
    }

    await _ensureGeminiInitialized();
    if (_model == null) return 'Configure as chaves do Gemini ou OpenAI no cofre.';
    try {
      final response = await _chat!.sendMessage(Content.text(
        'Você é o $assistantName, assistente de elite especializado em comunicação financeira.\n\n$prompt'
      ));
      return response.text ?? 'Erro ao gerar proposta.';
    } catch (e) {
      return 'Erro ao gerar proposta de negociação por IA: $e';
    }
  }

  Future<String> getCashFlowForecastAdvice(TransactionsProvider provider) async {
    final aiProvider = await _config.getAiProvider();
    
    // Carregar Perfil do Glauber
    String assistantName = 'Glauber';
    String personality = 'profissional';
    List<String> memories = [];
    try {
      final profile = await RealtimeDbService().getGlauberProfile().first;
      if (profile.isNotEmpty) {
        assistantName = profile['name']?.toString() ?? 'Glauber';
        personality = profile['personality']?.toString() ?? 'profissional';
        if (profile['memories'] != null) {
          memories = List<String>.from(profile['memories']);
        }
      }
    } catch (_) {}

    double currentBalance = provider.totalBalance;
    
    // Filtrar e preparar dados do caixa
    final forecast = provider.omieDailyForecast;
    final alert = provider.omiePredictiveAlert;
    
    // Próximos 5 contas a receber (AR) pendentes
    final List<dynamic> ar = provider.omieAccountsReceivable
        .where((x) => x['status_titulo'] != 'PAGO')
        .take(5)
        .toList();
        
    // Próximos 5 contas a pagar (AP) pendentes
    final List<dynamic> ap = provider.omieAccountsPayable
        .where((x) => x['status_titulo'] != 'PAGO')
        .take(5)
        .toList();

    String arText = ar.map((x) {
      final String client = x['nome_cliente'] ?? x['cNomeClient'] ?? 'Cliente';
      final double val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0.0;
      final String dueDate = x['data_vencimento'] ?? x['dDtVenc'] ?? '';
      return "- Receber de $client: R\$ ${val.toStringAsFixed(2)} em $dueDate";
    }).join("\n");

    String apText = ap.map((x) {
      final String prov = x['nome_fornecedor'] ?? x['cNomeForn'] ?? 'Fornecedor';
      final double val = double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0.0;
      final String dueDate = x['data_vencimento'] ?? x['dDtVenc'] ?? '';
      return "- Pagar para $prov: R\$ ${val.toStringAsFixed(2)} em $dueDate";
    }).join("\n");

    String alertText = alert != null 
        ? "ALERTA DE CAIXA DETECTADO: ${alert['message']}\nSugestão recomendada: ${alert['suggestion']}"
        : "Nenhum alerta de caixa negativo projetado para os próximos 30 dias.";

    String tonePrompt = '';
    if (personality == 'friendly') {
      tonePrompt = 'Use um tom amigável, casual, empático e pragmático, usando emojis.';
    } else if (personality == 'assertive') {
      tonePrompt = 'Use um tom assertivo, de alta cobrança, direto ao ponto e focado em risco, sem rodeios.';
    } else {
      tonePrompt = 'Use um tom profissional, analítico, polido e refinado como um CFO virtual.';
    }

    String memoriesPrompt = memories.isNotEmpty
        ? 'Lembretes sobre o negócio:\n' + memories.map((m) => '- $m').join('\n')
        : '';

    final prompt = '''
Você é o $assistantName, o CFO Virtual e analista financeiro inteligente do usuário.
$tonePrompt

$memoriesPrompt

Aqui estão os dados atuais e projeções de fluxo de caixa da empresa:
- Saldo em Conta Corrente Hoje: R\$ ${currentBalance.toStringAsFixed(2)}
- Projeção de Caixa (Próximos 10 períodos com alteração):
  ${forecast.take(10).map((f) {
    final String dt = DateFormat('dd/MM').format(f['date'] as DateTime);
    final double bal = f['balance'] as double;
    return "$dt: R\$ ${bal.toStringAsFixed(2)}";
  }).join(" | ")}

- Próximos Recebimentos Pendentes (Contas a Receber):
${arText.isEmpty ? 'Nenhum recebimento pendente listado.' : arText}

- Próximos Pagamentos Pendentes (Contas a Pagar):
${apText.isEmpty ? 'Nenhum pagamento pendente listado.' : apText}

- Diagnóstico do Motor Preditivo:
$alertText

Analise brevemente se há riscos de liquidez e proponha 3 ações práticas imediatas para melhorar ou proteger o caixa (por exemplo: antecipar fatura de cliente específico, prorrogar prazo com fornecedor específico que vença próximo ao período crítico, ou incentivar vendas à vista). 
Responda em Português do Brasil com formatação limpa e markdown em no máximo 15 linhas, direto ao ponto.
''';

    if (aiProvider == 'openai') {
      final apiKey = await _config.getOpenAIApiKey();
      if (apiKey == null || apiKey.isEmpty) return 'Configure a OpenAI no cofre.';
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
              {'role': 'system', 'content': 'Você é o $assistantName, um consultor financeiro CFO virtual inteligente de elite.'},
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.7,
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        }
      } catch (_) {}
    }

    await _ensureGeminiInitialized();
    if (_model == null) return 'Configure as chaves do Gemini ou OpenAI no cofre.';
    try {
      final response = await _chat!.sendMessage(Content.text(prompt));
      return response.text ?? 'Erro ao gerar análise de fluxo de caixa.';
    } catch (e) {
      return 'Erro ao gerar análise do fluxo de caixa: $e';
    }
  }

  Future<String> polishBio(String bio) async {
    final provider = await _config.getAiProvider();
    final systemContext = "Você é o assistente Glauber AI. Melhore a biografia de freelancer do usuário para que soe muito atraente, comercial e altamente profissional. Mantenha em no máximo 3 frases. Retorne APENAS a biografia reescrita, sem aspas, introduções ou observações.";
    if (provider == 'openai') {
      return _getOpenAIAdvice(bio, systemContext, 'Glauber');
    } else {
      return _getGeminiAdvice(bio, systemContext, 'Glauber');
    }
  }

  Future<List<String>> generateScopeFromDescription(String description) async {
    final provider = await _config.getAiProvider();
    final systemContext = "Você é o Glauber AI. Com base na descrição do projeto fornecida pelo usuário, gere uma lista de 5 a 7 itens curtos de escopo técnico de desenvolvimento ou design. Retorne APENAS os itens (um por linha), sem números, sem marcadores, sem introduções.";
    final String res;
    if (provider == 'openai') {
      res = await _getOpenAIAdvice(description, systemContext, 'Glauber');
    } else {
      res = await _getGeminiAdvice(description, systemContext, 'Glauber');
    }
    return res.split('\n')
        .map((e) => e.trim().replaceAll(RegExp(r'^[\-\*•\d\.\s]+'), ''))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> generateFullProposalEstimate({
    required String clientName,
    required String projectTitle,
    required String projectType,
    required String description,
  }) async {
    final provider = await _config.getAiProvider();
    final systemContext = "Você é o Glauber AI, um especialista comercial de tecnologia. Com base nas informações fornecidas, estime e configure os detalhes da proposta em formato JSON.\n"
        "Retorne APENAS um objeto JSON válido, sem markdown (sem ```json ou ```), com a seguinte estrutura exata:\n"
        "{\n"
        "  \"coverLetter\": \"Uma introdução curta e persuasiva para o cliente (máx 3 frases)\",\n"
        "  \"designHours\": 40,\n"
        "  \"devHours\": 80,\n"
        "  \"fixedPrice\": 12000,\n"
        "  \"scope\": [\"item 1\", \"item 2\", \"item 3\"],\n"
        "  \"designDays\": 7,\n"
        "  \"devDays\": 20,\n"
        "  \"deployDays\": 5,\n"
        "  \"observations\": \"Observação sobre validade e suporte\"\n"
        "}";
    final String prompt = "Cliente: $clientName\nProjeto: $projectTitle\nTipo/Modelo: $projectType\nDescrição do Projeto: $description";
    final String res;
    if (provider == 'openai') {
      res = await _getOpenAIAdvice(prompt, systemContext, 'Glauber');
    } else {
      res = await _getGeminiAdvice(prompt, systemContext, 'Glauber');
    }

    try {
      final cleanRes = res.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanRes) as Map<String, dynamic>;
    } catch (e) {
      return {
        "coverLetter": "Olá! Apresentamos nossa proposta comercial customizada para as necessidades do seu negócio.",
        "designHours": 30,
        "devHours": 60,
        "fixedPrice": 10000.0,
        "scope": ["Desenvolvimento das telas principais", "Integração de banco de dados", "Testes e homologação"],
        "designDays": 5,
        "devDays": 15,
        "deployDays": 5,
        "observations": "Proposta gerada automaticamente por Glauber AI."
      };
    }
  }
}
