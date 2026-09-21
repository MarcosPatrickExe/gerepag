import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/app_theme.dart';
import '../../services/realtime_db_service.dart';

class SendMessageToClientDialog extends StatefulWidget {
  final Map<String, dynamic> client;
  final RealtimeDbService db;

  const SendMessageToClientDialog({
    super.key,
    required this.client,
    required this.db,
  });

  @override
  State<SendMessageToClientDialog> createState() => _SendMessageToClientDialogState();
}

class _SendMessageToClientDialogState extends State<SendMessageToClientDialog> {
  final _msgCtrl = TextEditingController();
  bool _visibleToClient = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingMessage();
  }

  Future<void> _loadExistingMessage() async {
    final clientUid = widget.client['id'] ?? '';
    try {
      final currentMsgSnap = await FirebaseDatabase.instance
          .ref('users/${widget.db.currentUserUid}/bpo_clients/$clientUid/client_message')
          .get();
      if (currentMsgSnap.exists && currentMsgSnap.value is Map) {
        final data = Map<String, dynamic>.from(currentMsgSnap.value as Map);
        if (mounted) {
          setState(() {
            _msgCtrl.text = data['message'] ?? '';
            _visibleToClient = data['visible'] ?? true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientName = widget.client['name'] ?? '';

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Aviso para $clientName',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Escreva uma mensagem importante. Ela aparecerá em destaque no painel principal do cliente.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _msgCtrl,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ex: Olá! Por favor, nos envie os extratos bancários conciliados até o dia 05.',
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
                        'Exibir mensagem na tela do cliente',
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
          onPressed: _isLoading
              ? null
              : () async {
                  final clientUid = widget.client['id'] ?? '';
                  await widget.db.saveBpoClientMessage(
                    clientUid,
                    _msgCtrl.text.trim(),
                    _visibleToClient,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('✉️ Mensagem atualizada!'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
          child: const Text('ENVIAR'),
        ),
      ],
    );
  }
}
