import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class LinkClientDialog extends StatefulWidget {
  const LinkClientDialog({super.key});

  @override
  State<LinkClientDialog> createState() => _LinkClientDialogState();
}

class _LinkClientDialogState extends State<LinkClientDialog> {
  final _uidCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _uidCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Widget _dialogField(TextEditingController c, String label, IconData icon) => TextField(
    controller: c,
    style: const TextStyle(color: AppTheme.textBody, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.primary, size: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    ),
  );

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
            child: const Icon(Icons.person_add_rounded, color: Color(0xFF7C3AED), size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Vincular Cliente',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textBody),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'O cliente deve copiar seu ID em Configurações → ID de Vinculação BPO.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            _dialogField(_uidCtrl, 'UID do Cliente', Icons.key_rounded),
            const SizedBox(height: 12),
            _dialogField(_nameCtrl, 'Nome / Razão Social', Icons.business_rounded),
            const SizedBox(height: 12),
            _dialogField(_phoneCtrl, 'Telefone (opcional)', Icons.phone_rounded),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            final uid = _uidCtrl.text.trim();
            final name = _nameCtrl.text.trim();
            final phone = _phoneCtrl.text.trim();
            if (uid.isEmpty || name.isEmpty) return;
            Navigator.pop(context, {
              'uid': uid,
              'name': name,
              'phone': phone,
            });
          },
          child: const Text('VINCULAR', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
