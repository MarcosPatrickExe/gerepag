import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/realtime_db_service.dart';

class GlauberProfileScreen extends StatefulWidget {
  const GlauberProfileScreen({super.key});

  @override
  State<GlauberProfileScreen> createState() => _GlauberProfileScreenState();
}

class _GlauberProfileScreenState extends State<GlauberProfileScreen> {
  final _realtimeService = RealtimeDbService();
  final _nameController = TextEditingController();
  final _memoryController = TextEditingController();
  String _selectedPersonality = 'professional';
  bool _isSaving = false;

  final List<Map<String, String>> _personalities = [
    {
      'id': 'friendly',
      'name': 'Casual & Amigável 😊',
      'desc': 'Conversa de forma descontraída, simpática e usa emojis ocasionais.',
      'color': '0xFF3B82F6',
    },
    {
      'id': 'professional',
      'name': 'Profissional & Elegante 💼',
      'desc': 'Didático, formal e focado em excelência corporativa.',
      'color': '0xFF10B981',
    },
    {
      'id': 'assertive',
      'name': 'Direto & Realista ⚡',
      'desc': 'Assertivo, direto ao ponto e focado em alta cobrança de metas.',
      'color': '0xFFF59E0B',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    try {
      final profile = await _realtimeService.getGlauberProfile().first;
      if (profile.isNotEmpty && mounted) {
        setState(() {
          _nameController.text = profile['name']?.toString() ?? 'Glauber';
          _selectedPersonality = profile['personality']?.toString() ?? 'professional';
        });
      } else if (mounted) {
        _nameController.text = 'Glauber';
      }
    } catch (_) {
      _nameController.text = 'Glauber';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await _realtimeService.saveGlauberProfile({
        'name': _nameController.text.trim().isEmpty ? 'Glauber' : _nameController.text.trim(),
        'personality': _selectedPersonality,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso! 🧠'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar configurações: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addManualMemory() async {
    final text = _memoryController.text.trim();
    if (text.isEmpty) return;

    await _realtimeService.addGlauberMemory(text);
    _memoryController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lembrança adicionada com sucesso! 🧠'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Perfil & Memória do Glauber 🤖', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBody),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _realtimeService.getGlauberProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data ?? {};
          final List<dynamic> memories = profile['memories'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cartão Informativo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, color: AppTheme.primary, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Inteligência Adaptativa',
                              style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'O Glauber aprende fatos importantes sobre você conforme conversa e se adapta à personalidade que você escolher.',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Nome Customizado
                const Text(
                  'COMO DESEJA CHAMAR A IA?',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: AppTheme.textBody),
                        decoration: const InputDecoration(
                          hintText: 'Ex: Glauber, Sofia, Jarvis...',
                          labelText: 'Nome do Assistente',
                          labelStyle: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('SALVAR'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Seletor de Personalidade
                const Text(
                  'PERSONALIDADE E TOM DE VOZ',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 12),
                Column(
                  children: _personalities.map((p) {
                    final isSelected = _selectedPersonality == p['id'];
                    final color = Color(int.parse(p['color']!));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Colors.white.withValues(alpha: 0.04),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedPersonality = p['id']!;
                          });
                          _saveProfile();
                        },
                        leading: Radio<String>(
                          value: p['id']!,
                          groupValue: _selectedPersonality,
                          activeColor: color,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPersonality = val;
                              });
                              _saveProfile();
                            }
                          },
                        ),
                        title: Text(
                          p['name']!,
                          style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          p['desc']!,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Banco de Memórias
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BANCO DE MEMÓRIAS DA IA',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    Text(
                      '${memories.length} aprendidas',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Input de memória manual
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _memoryController,
                        style: const TextStyle(color: AppTheme.textBody),
                        decoration: const InputDecoration(
                          hintText: 'Ex: Usuário é fotógrafo freelancer.',
                          labelText: 'Ensinar fato manualmente',
                          labelStyle: TextStyle(color: AppTheme.textMuted),
                        ),
                        onSubmitted: (_) => _addManualMemory(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppTheme.primary, size: 36),
                      onPressed: _addManualMemory,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Lista de lembranças
                if (memories.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Column(
                        children: [
                          Icon(Icons.bubble_chart_outlined, size: 40, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 12),
                          const Text(
                            'Glauber ainda não guardou nenhuma memória.\nFale "ei glauber, lembre que..." ou adicione acima!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: memories.length,
                    itemBuilder: (context, index) {
                      final item = memories[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 16),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.toString(),
                                style: const TextStyle(color: AppTheme.textBody, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.expense, size: 18),
                              onPressed: () => _realtimeService.deleteGlauberMemory(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
