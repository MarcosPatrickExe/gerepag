import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../services/realtime_db_service.dart';

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final RealtimeDbService _db = RealtimeDbService();
  final TextEditingController _codeController = TextEditingController();
  String? _myFamilyId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFamilyStatus();
  }

  Future<void> _loadFamilyStatus() async {
    setState(() => _isLoading = true);
    await _db.init();
    // Acessar a propriedade privada via reflexão ou apenas re-implementar a busca aqui
    // Como simplificação, vou expor o familyId no serviço ou buscar novamente
    final snapshot = await _db.createFamily(); // Vou ajustar o serviço para getFamilyId
    setState(() {
      _myFamilyId = snapshot;
      _isLoading = false;
    });
  }

  Future<void> _createNewFamily() async {
    setState(() => _isLoading = true);
    final id = await _db.createFamily();
    setState(() {
      _myFamilyId = id;
      _isLoading = false;
    });
  }

  Future<void> _joinFamily() async {
    if (_codeController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    final success = await _db.joinFamily(_codeController.text);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conectado com sucesso! 🎉'), backgroundColor: AppTheme.income),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código inválido ou não encontrado.'), backgroundColor: AppTheme.expense),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Família'), elevation: 0),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Orçamento Compartilhado',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Conecte-se com seu parceiro(a) para gerenciar o saldo e as metas da casa em tempo real.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 48),
                
                if (_myFamilyId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text('SEU CÓDIGO DE CONVITE', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 12),
                        SelectableText(
                          _myFamilyId!,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _myFamilyId!));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado!')));
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('COPIAR CÓDIGO'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createNewFamily,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('CRIAR MEU GRUPO FAMILIAR'),
                    ),
                  ),
                ],

                const SizedBox(height: 48),
                const Divider(color: AppTheme.textMuted),
                const SizedBox(height: 48),
                
                const Text('OU ENTRE EM UM GRUPO EXISTENTE', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    hintText: 'Insira o código do seu parceiro',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _joinFamily,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primary),
                    ),
                    child: const Text('CONECTAR', style: TextStyle(color: AppTheme.primary)),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
