import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/config_service.dart';
import '../services/realtime_db_service.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ConfigService _config = ConfigService();
  GenerativeModel? _model;

  Future<bool> init() async {
    return await _speech.initialize(
      onStatus: (status) => print('Voice Status: $status'),
      onError: (error) => print('Voice Error: $error'),
    );
  }

  Future<void> _ensureAiInitialized() async {
    // Se já estiver inicializado, não faz nada
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
            requestOptions: RequestOptions(apiVersion: m['version']!),
          );
          
          await testModel.generateContent([Content.text('ping')]);
          
          _model = testModel;
          print('Jarvis (Glauber) inicializado: ${m['name']} (Key: ${key.substring(0, 4)}...)');
          return;
        } catch (e) {
          continue;
        }
      }
    }
    print('Glauber: Nenhuma chave ou modelo disponível funcionou.');
  }

  void startListening(Function(String) onResult) async {
    if (_speech.isListening) return;
    
    bool available = await _speech.initialize();
    if (available) {
      HapticFeedback.lightImpact();
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: 'pt_BR',
      );
    }
  }

  Future<Map<String, dynamic>?> processCommandWithAi(String text) async {
    HapticFeedback.mediumImpact();
    await _ensureAiInitialized();
    if (_model == null) return null;

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
      tonePrompt = 'Você responde de forma amigável, casual e informal (use emojis eventuais).';
    } else if (personality == 'assertive') {
      tonePrompt = 'Você responde de forma assertiva, firme, realista e direta ao ponto.';
    } else {
      tonePrompt = 'Você responde de forma profissional, polida e técnica.';
    }

    String memoryPrompt = memories.isNotEmpty
        ? 'FATOS QUE VOCÊ SE LEMBRA SOBRE O NEGÓCIO/USUÁRIO:\n' + memories.map((m) => '- $m').join('\n')
        : '';

    final prompt = '''
    Você é o $assistantName, o assistente financeiro inteligente do app GEREPAGUE. 
    $tonePrompt
    
    $memoryPrompt

    DATA ATUAL DE HOJE (USE COMO BASE PARA DATAS RELATIVAS COMO ONTEM, AMANHÃ OU DIAS ESPECÍFICOS): ${DateFormat('yyyy-MM-dd').format(DateTime.now())}

    Sua tarefa é analisar o comando por voz do usuário (que pode conter múltiplas solicitações/ações faladas simultaneamente) e retornar NO FORMATO JSON PURO no seguinte formato de lista de comandos:
    
    {
      "commands": [
        {
          "action": "...",
          ... (campos da ação)
        }
      ]
    }
    
    AÇÕES POSSÍVEIS:
    1. "add_client": Cadastrar um novo cliente/contato.
       Campos: "action": "add_client", "client_name": Nome do cliente, "phone": Celular/WhatsApp, "email": E-mail.
       Exemplos: "cadastrar o cliente João da Silva com telefone 11988887777".
       
    2. "add_project": Criar um novo projeto ou serviço no Kanban.
       Campos: "action": "add_project", "client_name": Nome do cliente associado, "description": Nome/descrição do projeto/serviço, "amount": Valor numérico do contrato, "due_date": Prazo/data se houver (formato dd/MM/yyyy).
       Exemplos: "crie o projeto Logotipo de 800 reais para o cliente Lucas".

    3. "create_invoice": Enviar ou gerar uma cobrança por WhatsApp.
       Campos: "action": "create_invoice", "client_name": Nome do cliente, "amount": Valor da cobrança, "description": Referência/serviço cobrado.
       Exemplos: "cobrar o João da Silva 400 reais referente ao logotipo".

    4. "add_transaction": Registrar lançamento de entrada (ganho/receita) ou saída (gasto/despesa).
       Campos: "action": "add_transaction", "amount": valor numérico, "description": descrição, "category": categoria (Alimentação, Transporte, Lazer, Saúde, Moradia, Educação, Outros), "type": "income" (ganho) ou "expense" (gasto), "date": data no formato yyyy-MM-dd se dita (ex: se o usuário diz 'gastei ontem', use a data de ontem com base no dia de hoje. Se diz 'no dia 10', use a data correspondente ao dia 10 do mês). Se não especificada, omita ou use null.
       Exemplos: "gastei 50 com Uber ontem", "recebi 2000 reais de salário no dia 10", "paguei 30 de almoço".

    5. "add_subscription": Registrar despesa mensal recorrente (mensalidade, assinatura, etc.).
       Campos: "action": "add_subscription", "name": Nome do serviço ou mensalidade, "price": Valor mensal cobrado, "billing_day": Dia de cobrança/vencimento mensal (número de 1 a 31).
       Exemplos: "vou ter despesa mensal de 300 reais todo mes de escola", "crie a assinatura Netflix de 55 reais todo dia 10", "mensalidade da academia de 120 reais todo dia 5".

    6. "add_memory": Lembrar de um fato importante sobre o usuário ou negócio para o futuro.
       Campos: "action": "add_memory", "memory": O fato completo resumido em terceira pessoa para memorizar.
       Exemplos: "lembre que meu melhor cliente é o Lucas".

    7. "query": Perguntas, dúvidas ou consultas financeiras gerais.
       Campos: "action": "query", "query": Pergunta reformulada ou original do usuário.
       Exemplos: "qual é o meu saldo?".

    8. "save_goal_money": Depositar ou retirar dinheiro de um cofrinho/meta de poupança.
       Campos: "action": "save_goal_money", "goal_name": Nome do cofrinho/meta de poupança (ex: notebook, reserva, carro, viagem), "amount": valor decimal positivo se for guardar/depositar, ou valor decimal negativo se for tirar/resgatar.
       Exemplos: "guarde 50 reais no cofrinho do notebook", "guardar 100 reais na meta da viagem", "tirar 30 reais do cofrinho do carro", "resgatar 40 reais do cofrinho da reserva".

    9. "create_goal": Criar uma nova meta de poupança ou cofrinho digital.
       Campos: "action": "create_goal", "goal_name": Nome do cofrinho/meta a ser criada (ex: notebook, reserva, viagem), "target_amount": Valor alvo decimal (ex: 2000, 5000, 1000).
       Exemplos: "crie a meta notebook de 2500 reais", "criar cofrinho viagem de 1000 reais", "nova meta reserva de 5000".

    10. "delete_item": Excluir ou apagar um lançamento, transação, assinatura/mensalidade, cofrinho/meta ou projeto.
        Campos: "action": "delete_item", "item_type": "transaction" (para gastos/receitas locais), "subscription" (mensalidades/recorrentes), "goal" (cofrinho/meta) ou "project" (Kanban), "name": Nome ou termo identificador do item a ser excluído (ex: netflix, ifood, notebook, logotipo).
        Exemplos: "apague a despesa do ifood", "deletar assinatura netflix", "excluir meta do notebook", "apagar projeto logotipo".

    ATENÇÃO: Se o usuário falar múltiplos comandos ao mesmo tempo (ex: "recebi 2000 de salário e gastei 50 com pizza e 30 com uber"), você DEVE gerar um elemento no array "commands" para cada transação e ação correspondente.

    FRASE DO USUÁRIO: "$text"
    
    RESPONDA APENAS O JSON (sem markdown ou blocos de código):
    ''';

    try {
      print('🎤 [$assistantName Voice] Texto Reconhecido: "$text"');
      print('🧠 [$assistantName Voice] Prompt Enviado para a IA:\n$prompt');
      
      final response = await _model!.generateContent([Content.text(prompt)]);
      
      print('🤖 [$assistantName Voice] Resposta Bruta da IA:\n"${response.text}"');
      final cleanJson = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '{}';
      final parsed = jsonDecode(cleanJson);
      
      print('📊 [$assistantName Voice] JSON Decodificado com Sucesso: $parsed');
      return parsed;
    } catch (e) {
      if (e.toString().contains('503') || e.toString().contains('high demand')) {
        print('🔄 [$assistantName Voice] Sobrecarga. Trocando de rota...');
        _model = null; 
        await _ensureAiInitialized();
        if (_model != null) {
          try {
            print('🧠 [$assistantName Voice] Re-enviando Prompt após Sobrecarga...');
            final retryResponse = await _model!.generateContent([Content.text(prompt)]);
            print('🤖 [$assistantName Voice] Resposta Bruta da IA (Retentativa):\n"${retryResponse.text}"');
            final cleanJson = retryResponse.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '{}';
            final parsed = jsonDecode(cleanJson);
            print('📊 [$assistantName Voice] JSON Decodificado com Sucesso (Retentativa): $parsed');
            return parsed;
          } catch (_) {}
        }
      }
      print('Erro no $assistantName: $e');
      _model = null; // Resetar para tentar outro modelo na próxima vez
    }
    return null;
  }

  void stopListening() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
