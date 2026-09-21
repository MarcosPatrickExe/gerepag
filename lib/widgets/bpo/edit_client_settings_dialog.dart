import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/app_theme.dart';
import '../../services/realtime_db_service.dart';

class EditClientSettingsDialog extends StatefulWidget {
  final Map<String, dynamic> client;
  final RealtimeDbService db;
  final VoidCallback onSuccess;

  const EditClientSettingsDialog({
    super.key,
    required this.client,
    required this.db,
    required this.onSuccess,
  });

  @override
  State<EditClientSettingsDialog> createState() => _EditClientSettingsDialogState();
}

class _EditClientSettingsDialogState extends State<EditClientSettingsDialog> {
  late String _selectedRegime;
  late TextEditingController _tagsCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _feeAmountCtrl;
  late TextEditingController _dueDayCtrl;

  bool _isLoading = true;
  String _currentStatus = 'Pendente';

  @override
  void initState() {
    super.initState();
    _selectedRegime = widget.client['regime']?.toString() ?? 'MEI';
    _tagsCtrl = TextEditingController(text: (widget.client['tags'] as List?)?.join(', ') ?? '');
    _phoneCtrl = TextEditingController();
    _feeAmountCtrl = TextEditingController();
    _dueDayCtrl = TextEditingController(text: '5');
    _loadFeeAndPhone();
  }

  Future<void> _loadFeeAndPhone() async {
    final clientUid = widget.client['id'] ?? '';
    double currentAmount = 0.0;
    int currentDueDay = 5;
    String currentPhone = widget.client['phone']?.toString() ?? '';

    try {
      final fees = await widget.db.getBpoFees().first;
      final feeData = fees[clientUid] as Map? ?? {};
      currentAmount = double.tryParse(feeData['amount']?.toString() ?? '0') ?? 0.0;
      currentDueDay = int.tryParse(feeData['dueDay']?.toString() ?? '5') ?? 5;
      _currentStatus = feeData['status']?.toString() ?? 'Pendente';
      if (feeData['phone'] != null && feeData['phone'].toString().isNotEmpty) {
        currentPhone = feeData['phone'].toString();
      }
    } catch (_) {}

    if (currentPhone.isEmpty && clientUid.isNotEmpty) {
      try {
        final profileSnap = await FirebaseDatabase.instance.ref('users/$clientUid/profile').get();
        if (profileSnap.exists && profileSnap.value is Map) {
          final profileData = Map<String, dynamic>.from(profileSnap.value as Map);
          currentPhone = profileData['phone']?.toString() ?? '';
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _phoneCtrl.text = currentPhone;
        _feeAmountCtrl.text = currentAmount > 0 ? currentAmount.toString() : '';
        _dueDayCtrl.text = currentDueDay.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tagsCtrl.dispose();
    _phoneCtrl.dispose();
    _feeAmountCtrl.dispose();
    _dueDayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientName = widget.client['name'] ?? '';
    final regimes = ['MEI', 'Simples Nacional', 'Lucro Presumido', 'Lucro Real'];

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Configurar $clientName',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textBody),
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Regime Tributário', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRegime,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                      ),
                    ),
                    items: regimes.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedRegime = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Tags (separadas por vírgula)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _tagsCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ex: Alimentos, VIP, Importador',
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
                  const SizedBox(height: 16),
                  const Text('WhatsApp do Cliente (com DDD)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ex: 11999998888',
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
                  const SizedBox(height: 16),
                  const Text('Valor Mensal dos Honorários (R\$)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _feeAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ex: 1200.00',
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
                  const SizedBox(height: 16),
                  const Text('Dia de Vencimento (1 a 31)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _dueDayCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ex: 5',
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
                ],
              ),
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
                  final List<String> tagsList = _tagsCtrl.text
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
                  final phone = _phoneCtrl.text.trim();
                  final double amount = double.tryParse(_feeAmountCtrl.text.trim()) ?? 0.0;
                  final int dueDay = int.tryParse(_dueDayCtrl.text.trim()) ?? 5;

                  await widget.db.saveBpoClientRegimeAndTags(
                    clientUid,
                    _selectedRegime,
                    tagsList,
                    phone: phone.isNotEmpty ? phone : null,
                  );
                  if (amount > 0) {
                    await widget.db.saveBpoFee(
                      clientUid,
                      amount,
                      dueDay,
                      _currentStatus,
                      phone: phone.isNotEmpty ? phone : null,
                    );
                  }

                  widget.onSuccess();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('✅ Configurações e faturamento salvos!'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
          child: const Text('SALVAR'),
        ),
      ],
    );
  }
}
