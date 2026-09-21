import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../services/ai_chat_service.dart';
import '../providers/subscription_provider.dart';
import '../screens/upgrade_screen.dart';

class AiNegotiationCard extends StatefulWidget {
  final String contactName;
  final double amount;
  final String dueDate;
  final String description;
  final String type; // 'receber' ou 'pagar'

  const AiNegotiationCard({
    super.key,
    required this.contactName,
    required this.amount,
    required this.dueDate,
    required this.description,
    required this.type,
  });

  static void show(
    BuildContext context, {
    required String contactName,
    required double amount,
    required String dueDate,
    required String description,
    required String type,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: AiNegotiationCard(
                contactName: contactName,
                amount: amount,
                dueDate: dueDate,
                description: description,
                type: type,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  State<AiNegotiationCard> createState() => _AiNegotiationCardState();
}

class _AiNegotiationCardState extends State<AiNegotiationCard> {
  final AiChatService _aiChatService = AiChatService();
  String _generatedText = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateProposal();
    });
  }

  Future<void> _generateProposal() async {
    final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    if (!subProvider.canUseNegotiation) {
      setState(() {
        _generatedText = 'LIMIT_EXCEEDED';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedText = '';
    });

    try {
      final text = await _aiChatService.generateNegotiationProposal(
        contactName: widget.contactName,
        amount: widget.amount,
        dueDate: widget.dueDate,
        description: widget.description,
        type: widget.type,
      );
      setState(() {
        _generatedText = text;
      });
      await subProvider.incrementNegotiationUsage();
    } catch (e) {
      setState(() {
        _generatedText = 'Erro ao gerar proposta de negociação por IA.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_generatedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copiado para a área de transferência! 📋'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _shareText() {
    if (_generatedText.isNotEmpty) {
      Share.share(_generatedText);
    }
  }

  void _sendViaWhatsApp() async {
    if (_generatedText.isEmpty) return;
    final url = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(_generatedText)}';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir WhatsApp: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'receber'
        ? 'Cobrança Inteligente 🤖'
        : 'Renegociar Conta 🤝';

    final subtitle = widget.type == 'receber'
        ? 'Glauber gerou um lembrete de pagamento amigável para enviar para ${widget.contactName}.'
        : 'Glauber elaborou uma proposta de renegociação/prazo para enviar a ${widget.contactName}.';

    final bool isLimitExceeded = _generatedText == 'LIMIT_EXCEEDED';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                widget.type == 'receber' ? Icons.chat_bubble_outline : Icons.handshake_outlined,
                color: AppTheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textBody,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          if (isLimitExceeded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x33FF9800), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock, color: Colors.orange, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Limite de IA Atingido 🚀',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBody),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Você atingiu o limite de 2 negociações de cobrança gratuitas por mês. Assine o plano Pro para geração ilimitada de propostas inteligentes!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Fechar bottom sheet
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('SER PRO E TER IA ILIMITADA', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppTheme.primary),
                            SizedBox(height: 16),
                            Text(
                              'Glauber está redigindo...',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            )
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          _generatedText,
                          style: const TextStyle(
                            color: AppTheme.textBody,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            if (!_isLoading) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy, color: AppTheme.primary, size: 18),
                      label: const Text('COPIAR TEXTO', style: TextStyle(color: AppTheme.textBody)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareText,
                      icon: const Icon(Icons.share, color: AppTheme.primary, size: 18),
                      label: const Text('COMPARTILHAR', style: TextStyle(color: AppTheme.textBody)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendViaWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                  label: const Text('ENVIAR NO WHATSAPP 💬', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _generateProposal,
                  icon: const Icon(Icons.refresh, color: AppTheme.textMuted, size: 14),
                  label: const Text('GERAR OUTRA OPÇÃO', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
