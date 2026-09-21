import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import '../services/ai_chat_service.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialMessage;
  const AiChatScreen({super.key, this.initialMessage});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final AiChatService _aiService = AiChatService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      _messages.add({'role': 'user', 'content': widget.initialMessage!});
      _processAIResponse(widget.initialMessage!);
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
    });

    _processAIResponse(text);
  }

  void _processAIResponse(String text) async {
    setState(() {
      _isLoading = true;
    });
    
    final provider = Provider.of<TransactionsProvider>(context, listen: false);
    
    // Construir "Pacotes" de dados estruturados para a IA
    String personalContext = "";
    final recentPersonal = provider.transactions.take(5).map((t) => "${t.category}: R\$ ${t.amount.toStringAsFixed(2)}").join(", ");
    personalContext = "Top Gastos Recentes (Pessoal): $recentPersonal";

    String businessContext = "";
    // Incluir dados do Omie sempre que estiverem carregados, independente da flag de UI
    if (provider.omieSummary != null || provider.omieKey != null) {
      final clientRank = provider.incomeByClientRank;
      final topClients = clientRank.entries.take(3).map((e) => "${e.key}: R\$ ${e.value.toStringAsFixed(2)}").join(", ");
      
      final expenseRank = provider.expenseByCategoryRank;
      final topExpenses = expenseRank.entries.take(3).map((e) => "${e.key}: R\$ ${e.value.toStringAsFixed(2)}").join(", ");

      String activePeriodStr = "";
      if (provider.omieFilterMode == OmieFilterMode.monthly) {
        activePeriodStr = "Mensal (${provider.selectedMonth}/${provider.selectedYear})";
      } else if (provider.omieFilterMode == OmieFilterMode.yearly) {
        activePeriodStr = "Anual (${provider.selectedYear})";
      } else if (provider.omieFilterMode == OmieFilterMode.daily) {
        activePeriodStr = "Diário";
      } else {
        activePeriodStr = "Customizado";
      }

      double totalRec = 0;
      for (var x in provider.omieAccountsReceivable) {
        totalRec += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0.0;
      }
      double totalPay = 0;
      for (var x in provider.omieAccountsPayable) {
        totalPay += double.tryParse(x['valor_documento']?.toString() ?? '0') ?? 0.0;
      }
      
      businessContext = """
PACOTE DE DADOS EMPRESARIAIS (OMIE):
- Período Ativo Selecionado na Tela: $activePeriodStr
- Saúde Financeira Geral: Saldo Atual em Conta R\$ ${provider.totalBalance.toStringAsFixed(2)}
- Performance no Período Selecionado ($activePeriodStr): Faturamento R\$ ${provider.monthIncome.toStringAsFixed(2)} vs Despesas R\$ ${provider.monthExpense.toStringAsFixed(2)}
- Histórico Geral Acumulado (Todos os Meses/Anos do Banco de Dados): Faturamento Geral R\$ ${totalRec.toStringAsFixed(2)} vs Despesas Gerais R\$ ${totalPay.toStringAsFixed(2)}
- Riscos: R\$ ${provider.omieOverdue.toStringAsFixed(2)} em faturas vencidas.
- Maiores Clientes (Geral): $topClients
- Principais Despesas (Geral): $topExpenses
- Meta do Mês: R\$ ${provider.omieGoal.toStringAsFixed(2)}
""";
    } else {
      businessContext = "OBSERVAÇÃO: Dados do Omie não carregados ou chave não configurada.";
    }

    print('🧠 [DEBUG] Enviando Contexto Consolidado para a IA:\n$personalContext\n$businessContext');

    final response = await _aiService.getAdvice(
      text, 
      provider.transactions,
      businessContext: "$personalContext\n$businessContext",
    );

    setState(() {
      _messages.add({'role': 'ai', 'content': response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultor IA', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBody),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      ),
                    ),
                    child: Text(
                      msg['content']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppTheme.primary,
                        fontWeight: isUser ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: AppTheme.primary),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Pergunte qualquer coisa...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: AppTheme.primary,
                    mini: true,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
