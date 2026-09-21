import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../services/auth_lock_service.dart';
import '../services/realtime_db_service.dart';
import 'package:provider/provider.dart';
import '../providers/transactions_provider.dart';
import 'home_screen.dart';
import 'omie_setup_wizard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late FirebaseAuth _auth;
  final AuthLockService _lockService = AuthLockService();
  bool _isLoggingIn = false;
  bool _isAuthReady = false;
  bool _isRegistering = false;
  bool _showPassword = false;
  String _selectedNiche = 'autonomo';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _auth = FirebaseAuth.instance;
      if (mounted) setState(() => _isAuthReady = true);
    } catch (e) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        _auth = FirebaseAuth.instance;
        if (mounted) setState(() => _isAuthReady = true);
      } catch (retryError) {
        debugPrint('Erro Crítico Auth: $retryError');
      }
    }
  }

  Future<void> _handleAuthAction() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha e-mail e senha')),
      );
      return;
    }

    setState(() => _isLoggingIn = true);
    final email = _emailController.text.trim();

    try {
      if (_isRegistering) {
        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
        );
        
        if (userCredential.user != null) {
          await RealtimeDbService().initializeNewUser(
            email,
            niche: _selectedNiche,
          );
        }
      } else {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
        );
      }
      
      if (mounted) {
        final provider = Provider.of<TransactionsProvider>(context, listen: false);
        await provider.init();
        if (!mounted) return;
        
        Widget nextScreen = const HomeScreen();
        if (_isRegistering) {
          if (_selectedNiche == 'pme' || _selectedNiche == 'bpo') {
            provider.setBusinessMode(true);
            nextScreen = const OmieSetupWizardScreen();
          } else {
            provider.setBusinessMode(false);
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Erro: ${e.message}';
      if (e.code == 'email-already-in-use') errorMsg = 'E-mail já cadastrado.';
      else if (e.code == 'invalid-email') errorMsg = 'E-mail inválido.';
      else if (e.code == 'wrong-password') errorMsg = 'Senha incorreta.';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fundo clean off-white (Slate 50)
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;
          return Stack(
            children: [
              _buildDotGrid(),
              isWide ? _buildDesktopLayout() : _buildMobileLayout(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDotGrid() {
    return Opacity(
      opacity: 0.4,
      child: CustomPaint(
        size: Size.infinite,
        painter: DotGridPainter(color: const Color(0xFFE2E8F0)), // Grade de pontos cinza sutil
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogoSection(false),
              const SizedBox(height: 36),
              // Card Clean Branco Flutuante com Sombra Suave
              Container(
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _buildLoginForm(false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Side: Image/Info (Fundo clean leve e sofisticado)
        Expanded(
          flex: 6,
          child: Container(
            color: const Color(0xFFF1F5F9), // Slate 100
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(80.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogoSection(true),
                        const SizedBox(height: 60),
                        Text(
                          'Sua operação financeira\nem um só lugar.',
                          style: GoogleFonts.outfit(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A), // Titulo escuro clean
                            height: 1.1,
                            letterSpacing: -1.5,
                          ),
                        ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.1),
                        const SizedBox(height: 32),
                        Text(
                          'Conecte dados do seu ERP e transforme números em decisões estratégicas com inteligência artificial.',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: const Color(0xFF475569), // Slate 600
                            height: 1.6,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Side: Login Form (Card Clean Flutuante)
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Container(
                  padding: const EdgeInsets.all(40.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildLoginForm(true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection(bool isDesktop) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/logogerepag.png',
          height: isDesktop ? 65 : 55,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance_wallet_rounded, size: 40, color: AppTheme.primary),
        ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildLoginForm(bool isDesktop) {
    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        if (isDesktop) ...[
          _buildLogoSection(true),
          const SizedBox(height: 48),
        ],
        Text(
          _isRegistering ? 'Criar Conta' : 'Acessar Portal',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 8),
        Text(
          _isRegistering ? 'Preencha os dados abaixo.' : 'Entre com suas credenciais.',
          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 15),
        ),
        const SizedBox(height: 36),
        _buildInputField(
          controller: _emailController,
          label: 'E-mail',
          icon: Icons.alternate_email_rounded,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          controller: _passwordController,
          label: 'Senha',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
        if (_isRegistering) ...[
          const SizedBox(height: 24),
          Text(
            'COMO VOCÊ PRETENDE USAR O GEREPAG?',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildNicheItem(
            nicheKey: 'autonomo',
            title: 'Autônomo / Freelancer',
            description: 'Finanças simples, scanner de notas e cobranças rápidas por WhatsApp.',
            icon: Icons.person_outline_rounded,
            color: Colors.blue,
          ),
          const SizedBox(height: 10),
          _buildNicheItem(
            nicheKey: 'pme',
            title: 'Pequena / Média Empresa',
            description: 'Conecte seu Omie ERP, faça previsões de caixa e DRE completo.',
            icon: Icons.storefront_rounded,
            color: Colors.green,
          ),
          const SizedBox(height: 10),
          _buildNicheItem(
            nicheKey: 'bpo',
            title: 'BPO Financeiro',
            description: 'Gerencie múltiplos clientes e conciliações Omie unificadas.',
            icon: Icons.business_center_rounded,
            color: Colors.purple,
          ),
          const SizedBox(height: 10),
          _buildNicheItem(
            nicheKey: 'contador',
            title: 'Contador Parceiro / Auditor',
            description: 'Monitore a saúde fiscal de seus clientes, audite a DRE e envie pareceres técnicos.',
            icon: Icons.analytics_rounded,
            color: Colors.teal,
          ),
          const SizedBox(height: 10),
          _buildNicheItem(
            nicheKey: 'infoprodutor',
            title: 'Infoprodutor / Coprodutor',
            description: 'Recupere boletos e Pix gerados por IA de forma ágil.',
            icon: Icons.school_rounded,
            color: Colors.orange,
          ),
        ],
        const SizedBox(height: 36),
        _buildActionButton(),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => setState(() => _isRegistering = !_isRegistering),
          child: RichText(
            text: TextSpan(
              text: _isRegistering ? 'Já possui conta? ' : 'Novo por aqui? ',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
              children: [
                TextSpan(
                  text: _isRegistering ? 'Entre agora' : 'Crie sua conta',
                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 16),
        Text(
          '⚡ AMBIENTE DE DEMONSTRAÇÃO (ACESSO RÁPIDO)',
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),

        _buildDemoButton(
          label: '🏢 Demo Empresa (Omie BI & DRE)',
          color: const Color(0xFF2563EB),
          onTap: () => _loginAsDemoUser('empresa'),
        ),
        const SizedBox(height: 8),
        _buildDemoButton(
          label: '💼 Demo Freelancer & OS',
          color: const Color(0xFF06B6D4),
          onTap: () => _loginAsDemoUser('freelancer'),
        ),
        const SizedBox(height: 8),
        _buildDemoButton(
          label: '👤 Demo Finanças Pessoais',
          color: const Color(0xFF10B981),
          onTap: () => _loginAsDemoUser('pessoal'),
        ),

        if (!_isAuthReady || _isLoggingIn)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 3),
          ),
      ],
    );
  }

  Widget _buildDemoButton({required String label, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoggingIn ? null : onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: color.withValues(alpha: 0.05),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Future<void> _loginAsDemoUser(String demoType) async {
    setState(() => _isLoggingIn = true);
    try {
      final provider = Provider.of<TransactionsProvider>(context, listen: false);
      if (demoType == 'empresa') {
        provider.enableDemoOmieAccount();
      } else if (demoType == 'freelancer') {
        provider.setBusinessMode(false);
        provider.setUserNiche('autonomo');
        await provider.init();
      } else {
        provider.setBusinessMode(false);
        provider.setUserNiche('pessoal');
        await provider.init();
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Modo Demonstração Ativo: ${demoType.toUpperCase()}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      debugPrint('Erro ao iniciar modo demo: $e');
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !_showPassword,
          style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
            suffixIcon: isPassword ? IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8), size: 18),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ) : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], // Azul/Indigo Clean
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _isLoggingIn ? null : _handleAuthAction,
          child: Text(
            (_isRegistering ? 'CRIAR CONTA' : 'ACESSAR PORTAL').toUpperCase(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 1.0, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildNicheItem({
    required String nicheKey,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final bool isSelected = _selectedNiche == nicheKey;
    return InkWell(
      onTap: () => setState(() => _selectedNiche = nicheKey),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? color : const Color(0xFF94A3B8), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: isSelected ? color : const Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class DotGridPainter extends CustomPainter {
  final Color color;
  DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const spacing = 25.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
