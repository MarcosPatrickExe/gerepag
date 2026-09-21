import 'package:flutter/material.dart';
import '../../../providers/transactions_provider.dart';
import '../../../screens/ai_chat_screen.dart';

class OmieAIConsultantCard extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieAIConsultantCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          const Text('Assistente Estratégico IA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tire dúvidas sobre seu lucro, clientes e projeções direto com a IA.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AiChatScreen(initialMessage: provider.omieBusinessAIContext)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2), 
              foregroundColor: Colors.white, 
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
            ),
            child: const Center(child: Text('CONSULTAR IA AGORA', style: TextStyle(fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }
}
