import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_theme.dart';
import '../services/realtime_db_service.dart';
import 'portfolio_public_view_screen.dart';
import '../services/ai_chat_service.dart';

class PortfolioSetupScreen extends StatefulWidget {
  const PortfolioSetupScreen({super.key});

  @override
  State<PortfolioSetupScreen> createState() => _PortfolioSetupScreenState();
}

class _PortfolioSetupScreenState extends State<PortfolioSetupScreen> {
  final RealtimeDbService _dbService = RealtimeDbService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPolishingBio = false;
  String _currentSlug = '';

  @override
  void initState() {
    super.initState();
    _loadPortfolioProfile();
  }

  @override
  void dispose() {
    _slugController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolioProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await _dbService.getUserProfile();
      final String userEmail = snap?['email']?.toString() ?? '';
      
      // Carregar dados de portfólio
      _dbService.getPortfolioProfile().first.then((profile) {
        if (profile != null) {
          setState(() {
            _slugController.text = profile['slug'] ?? '';
            _titleController.text = profile['title'] ?? '';
            _bioController.text = profile['bio'] ?? '';
            _whatsappController.text = profile['whatsapp'] ?? '';
            _currentSlug = profile['slug'] ?? '';
            _isLoading = false;
          });
        } else {
          // Valores padrão baseados no email
          setState(() {
            final defaultSlug = userEmail.split('@')[0].replaceAll('.', '-');
            _slugController.text = defaultSlug;
            _titleController.text = '${snap?['name'] ?? 'Meu Nome'} - Freelancer';
            _bioController.text = 'Freelancer de Elite';
            _whatsappController.text = '';
            _isLoading = false;
          });
        }
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final String cleanSlug = _slugController.text.trim().toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9\-]'), '');

    final profile = {
      'slug': cleanSlug,
      'title': _titleController.text.trim(),
      'bio': _bioController.text.trim(),
      'whatsapp': _whatsappController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final bool success = await _dbService.savePortfolioProfile(profile);
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        setState(() => _currentSlug = cleanSlug);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Perfil do portfólio salvo com sucesso!'), backgroundColor: Colors.teal),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Este slug de subdomínio já está em uso por outro freelancer.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Configurar Portfólio Público 🎯',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textBody),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBody),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),
                    const SizedBox(height: 32),
                    _buildProfileFields(),
                    const SizedBox(height: 32),
                    _buildProjectsList(uid),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_rounded, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Tenha um portfólio automático! 🚀',
                style: GoogleFonts.outfit(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ao mover cards para "Pago" no seu Kanban de Serviços, o GerePague ajudará você a publicá-los como cases com apenas 1 clique. Seu portfólio fica indexado no Google e pronto para atrair novos clientes.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
          ),
          if (_currentSlug.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Seu link ativo: gerepague.com/portfolio/$_currentSlug',
                    style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PortfolioPublicViewScreen(slug: _currentSlug),
                      ),
                    );
                  },
                  icon: const Icon(Icons.preview_rounded, size: 14),
                  label: const Text('VER PREVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildProfileFields() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados do Portfólio',
            style: GoogleFonts.outfit(color: AppTheme.textBody, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Subdomínio/Slug
          _buildTextField(
            controller: _slugController,
            label: 'Slug de Link (ex: joao-desenvolvedor)',
            icon: Icons.link_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Informe o slug de link';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Título de Apresentação
          _buildTextField(
            controller: _titleController,
            label: 'Título Profissional (ex: João Silva - Desenvolvedor Flutter)',
            icon: Icons.badge_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Informe seu título profissional';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Bio
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildTextField(
                controller: _bioController,
                label: 'Bio / Apresentação Comercial',
                icon: Icons.description_outlined,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Fale um pouco sobre seu trabalho';
                  return null;
                },
              ),
              const SizedBox(height: 4),
              _isPolishingBio
                  ? const Padding(
                      padding: EdgeInsets.only(right: 8, top: 4),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () async {
                        final String currentText = _bioController.text.trim();
                        if (currentText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('⚠️ Escreva algo básico antes para a IA melhorar.')),
                          );
                          return;
                        }
                        setState(() => _isPolishingBio = true);
                        try {
                          final polished = await AiChatService().polishBio(currentText);
                          setState(() {
                            _bioController.text = polished;
                            _isPolishingBio = false;
                          });
                        } catch (_) {
                          setState(() => _isPolishingBio = false);
                        }
                      },
                      icon: const Icon(Icons.psychology_outlined, size: 14, color: AppTheme.primary),
                      label: const Text(
                        'Melhorar com IA 🤖',
                        style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 16),

          // WhatsApp
          _buildTextField(
            controller: _whatsappController,
            label: 'WhatsApp com DDD (apenas números, ex: 11999999999)',
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Informe o WhatsApp comercial';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Botão Salvar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('SALVAR CONFIGURAÇÕES DO PORTFÓLIO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cases Publicados no Portfólio 📂',
          style: GoogleFonts.outfit(color: AppTheme.textBody, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _dbService.getPortfolioProjects(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 48, color: AppTheme.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'Nenhum case publicado ainda.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Conclua serviços no seu Kanban para carregar cases automaticamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              );
            }

            final projects = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final proj = projects[index];
                final String title = proj['title'] ?? 'Sem Título';
                final double value = double.tryParse(proj['value']?.toString() ?? '0') ?? 0.0;
                final double rating = double.tryParse(proj['rating']?.toString() ?? '5') ?? 5.0;

                return Card(
                  color: AppTheme.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.tealAccent,
                      child: Icon(Icons.workspace_premium_rounded, color: Colors.teal),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody)),
                    subtitle: Text(
                      'Valor: R\$ ${value.toStringAsFixed(2)} • Satisfação: ${rating.toStringAsFixed(0)} ★',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remover do Portfólio?'),
                            content: const Text('Esta ação excluirá permanentemente este case do seu portfólio público.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('EXCLUIR', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _dbService.deletePortfolioProject(proj['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🗑️ Case removido do portfólio público.')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
      style: const TextStyle(color: AppTheme.textBody, fontSize: 13),
    );
  }
}
