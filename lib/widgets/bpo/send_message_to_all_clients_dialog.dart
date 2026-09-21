import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class SendMessageToAllClientsDialog extends StatefulWidget {
  const SendMessageToAllClientsDialog({super.key});

  @override
  State<SendMessageToAllClientsDialog> createState() => _SendMessageToAllClientsDialogState();
}

class _SendMessageToAllClientsDialogState extends State<SendMessageToAllClientsDialog> {
  final _msgCtrl = TextEditingController();
  bool _visibleToClient = true;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_rounded, color: Color(0xFF7C3AED), size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Aviso Geral (Em Lote)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textBody),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Escreva uma mensagem importante. Ela será disparada e exibida simultaneamente em destaque no painel principal de TODOS os seus clientes vinculados.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _msgCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ex: Prezados clientes, fiquem atentos ao prazo de entrega de documentos fiscais até o dia 05.',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _visibleToClient,
                activeColor: const Color(0xFF7C3AED),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _visibleToClient = val);
                  }
                },
              ),
              const Expanded(
                child: Text(
                  'Exibir mensagem na tela de todos',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            final text = _msgCtrl.text.trim();
            if (text.isEmpty) return;
            Navigator.pop(context, {
              'message': text,
              'visible': _visibleToClient,
            });
          },
          child: const Text('DISPARAR AVISO', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
