import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import 'home_screen.dart';

class OmieSetupWizardScreen extends StatefulWidget {
  const OmieSetupWizardScreen({super.key});

  @override
  State<OmieSetupWizardScreen> createState() => _OmieSetupWizardScreenState();
}

class _OmieSetupWizardScreenState extends State<OmieSetupWizardScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();
  bool _isSaving = false;

  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty || _keyController.text.isEmpty || _secretController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos da sua empresa.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final provider = Provider.of<TransactionsProvider>(context, listen: false);
      
      await provider.saveOmieAccount(
        _nameController.text.trim(),
        _keyController.text.trim(),
        _secretController.text.trim(),
      );
      
      provider.setBusinessMode(true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao configurar: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildGlassForm(),
                    const SizedBox(height: 24),
                    _buildFooterActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  Color(0xFF1E293B),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withValues(alpha: 0.1),
            ),
          ).animate(onPlay: (c) => c.repeat()).blur(begin: const Offset(50, 50), end: const Offset(100, 100), duration: 5.seconds).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 5.seconds),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.auto_awesome, size: 48, color: Colors.blueAccent),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).shimmer(delay: 1.seconds),
        const SizedBox(height: 24),
        const Text(
          'Configuração BI',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
        const SizedBox(height: 12),
        Text(
          'Conecte o GerePag ao seu Omie ERP\npara desbloquear análises em tempo real.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 16,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildGlassForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Nome da Empresa',
                icon: Icons.business,
                delay: 300,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _keyController,
                label: 'Omie App Key',
                icon: Icons.key_rounded,
                delay: 450,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _secretController,
                label: 'Omie App Secret',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                delay: 600,
              ),
              const SizedBox(height: 40),
              _buildPrimaryButton(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    required int delay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: delay.ms).slideX(begin: -0.1);
  }

  Widget _buildPrimaryButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: _isSaving ? null : _handleSave,
        child: _isSaving 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ATUALIZAR PORTAL BI',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                ),
                SizedBox(width: 12),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ],
            ),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Column(
      children: [
        TextButton(
          onPressed: () async {
            final provider = Provider.of<TransactionsProvider>(context, listen: false);
            await provider.setUsingOmie(false);
            provider.setBusinessMode(true);
            if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
          },
          child: Text(
            'NÃO USO OMIE? CONFIGURAR MANUALMENTE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen())),
          child: Text(
            'Configurar depois',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1.seconds);
  }
}
