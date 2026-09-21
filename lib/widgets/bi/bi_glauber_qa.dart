import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_chat_service.dart';
import '../../providers/transactions_provider.dart';

class BiGlauberQa extends StatefulWidget {
  const BiGlauberQa({super.key});

  @override
  State<BiGlauberQa> createState() => _BiGlauberQaState();
}

class _BiGlauberQaState extends State<BiGlauberQa> {
  final TextEditingController _controller = TextEditingController();
  final AiChatService _aiService = AiChatService();
  bool _isProcessing = false;
  String? _answer;

  final List<String> _quickQuestions = [
    'Qual foi a receita de janeiro?',
    'Quanto temos em conta corrente?',
    'Qual fornecedor tem maior débito?',
    'Qual produto tem maior churn?',
  ];

  Future<void> _askQuestion(String question) async {
    setState(() {
      _isProcessing = true;
      _answer = null;
      _controller.text = question;
    });

    final txProvider = Provider.of<TransactionsProvider>(context, listen: false);
    final contextPrompt = '''
Você é a Glauber AI, assistente executiva de BI do GerePague e Omie. Responda à pergunta do usuário de forma concisa e direta usando os dados atuais:
- Receita Mensal: R\$ ${txProvider.monthIncome.toStringAsFixed(2)}
- Despesa Mensal: R\$ ${txProvider.monthExpense.toStringAsFixed(2)}
- Saldo em Conta: R\$ ${txProvider.currentBalance.toStringAsFixed(2)}
- Contas a Receber: R\$ ${txProvider.totalReceivable.toStringAsFixed(2)}
- Contas a Pagar: R\$ ${txProvider.totalPayable.toStringAsFixed(2)}
- EBITDA: R\$ ${txProvider.omieEBITDA.toStringAsFixed(2)}

Pergunta do usuário: "$question"
''';

    try {
      final response = await _aiService.getAdvice(question, [], businessContext: contextPrompt);
      if (mounted) {
        setState(() {
          _answer = response;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _answer = 'Não foi possível processar a pergunta. Tente novamente.';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Painel Q&A — Pergunte à Glauber AI (Linguagem Natural)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sugestões Rápidas
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickQuestions.map((q) {
              return ActionChip(
                backgroundColor: const Color(0xFF1E293B),
                side: BorderSide.none,
                label: Text(q, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                onPressed: () => _askQuestion(q),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Campo de Entrada
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Digite sua dúvida financeira ou de vendas...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) _askQuestion(val.trim());
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isProcessing
                    ? null
                    : () {
                        if (_controller.text.trim().isNotEmpty) {
                          _askQuestion(_controller.text.trim());
                        }
                      },
                child: _isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ],
          ),

          // Resposta da IA
          if (_answer != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.smart_toy_outlined, color: Color(0xFF38BDF8), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _answer!,
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
