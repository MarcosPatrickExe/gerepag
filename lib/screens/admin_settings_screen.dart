import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../services/bio_auth_service.dart';
import '../core/app_theme.dart';
import 'dart:ui';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final TextEditingController _geminiController = TextEditingController();
  final TextEditingController _openaiController = TextEditingController();
  final ConfigService _config = ConfigService();
  final BioAuthService _bioAuth = BioAuthService();
  bool _isLoading = true;
  bool _isBioAuthEnabled = false;
  bool _canCheckBiometrics = false;
  String _activeProvider = 'gemini';
  bool _autoBusinessAi = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final geminiKey = await _config.getGeminiApiKey();
    final openaiKey = await _config.getOpenAIApiKey();
    final provider = await _config.getAiProvider();
    final autoAi = await _config.getAutoBusinessAi();
    final bioEnabled = await _bioAuth.isEnabled();
    final canCheck = await _bioAuth.isBiometricsAvailable();
    
    if (mounted) {
      setState(() {
        _geminiController.text = geminiKey ?? '';
        _openaiController.text = openaiKey ?? '';
        _activeProvider = provider;
        _autoBusinessAi = autoAi;
        _isBioAuthEnabled = bioEnabled;
        _canCheckBiometrics = canCheck;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    await _config.setGeminiApiKey(_geminiController.text);
    await _config.setOpenAIApiKey(_openaiController.text);
    await _config.setAiProvider(_activeProvider);
    await _config.setAutoBusinessAi(_autoBusinessAi);
    await _bioAuth.setEnabled(_isBioAuthEnabled);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cofre atualizado e sincronizado! 🚀')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text('Cofre de Configurações'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology_alt, color: AppTheme.primary, size: 32),
                              const SizedBox(width: 16),
                              Text(
                                'GereIA Console',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.textBody, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Escolha o provedor de Inteligência Artificial para o GerePag. Remova qualquer espaço extra ao colar as chaves.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          
                          // AI Provider Selector
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _buildProviderTab('Gemini', Icons.auto_awesome, _activeProvider == 'gemini', () => setState(() => _activeProvider = 'gemini'))),
                                Expanded(child: _buildProviderTab('ChatGPT', Icons.chat_bubble_outline, _activeProvider == 'openai', () => setState(() => _activeProvider = 'openai'))),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          if (_activeProvider == 'gemini') ...[
                            _buildKeyField('Gemini API Key', _geminiController, 'Google AI Studio Key'),
                          ] else ...[
                            _buildKeyField('OpenAI API Key', _openaiController, 'sk-xxxx...'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.business_center, color: Colors.blueAccent, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Empresarial: gpt-4o-mini', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 12)),
                                        Text('Otimizado para grandes volumes de dados Omie.', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _autoBusinessAi, 
                                    onChanged: (val) => setState(() => _autoBusinessAi = val),
                                    activeColor: Colors.blueAccent,
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
                          const Divider(color: AppTheme.textMuted),
                          const SizedBox(height: 24),
                          
                          // Biometrics
                          Row(
                            children: [
                              Icon(Icons.fingerprint, color: AppTheme.primary, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Segurança Biométrica', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
                                    Text(
                                      _canCheckBiometrics ? 'Proteger acesso ao cofre' : 'Biometria indisponível',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isBioAuthEnabled,
                                onChanged: _canCheckBiometrics 
                                  ? (val) => setState(() => _isBioAuthEnabled = val)
                                  : null,
                                activeColor: AppTheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _saveConfig,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text('SINCRONIZAR CONFIGURAÇÕES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'As chaves são salvas apenas no seu dispositivo.',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildProviderTab(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : AppTheme.textMuted, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: AppTheme.textBody, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            filled: true,
            fillColor: Colors.black38,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.vpn_key_outlined, color: AppTheme.primary, size: 20),
          ),
        ),
      ],
    );
  }
}
