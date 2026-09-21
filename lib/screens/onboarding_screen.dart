import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../core/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Domine sua\nOperação 🏦',
      description: 'Conecte Sigma, Micro e Manut em segundos. Seus dados fluem em tempo real, eliminando planilhas e erros.',
      icon: Icons.account_balance_rounded,
      color: const Color(0xFF2563EB),
      accentColor: const Color(0xFF60A5FA),
    ),
    OnboardingData(
      title: 'Consultor\nFinanceiro IA 🤖',
      description: 'Tenha um CFO 24h no seu bolso. Previsões precisas e decisões baseadas em dados reais da sua empresa.',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF7C3AED),
      accentColor: const Color(0xFFA78BFA),
    ),
    OnboardingData(
      title: 'Dashboards\nde Elite 📊',
      description: 'DRE, Fluxo de Caixa e Comercial com clareza absoluta. Visualize a saúde do seu negócio em um clique.',
      icon: Icons.dashboard_customize_rounded,
      color: const Color(0xFF059669),
      accentColor: const Color(0xFF34D399),
    ),
    OnboardingData(
      title: 'Visão Holding\nConsolidada 🏢',
      description: 'Controle total para grandes grupos. Faturamento e saldo de todas as suas empresas em uma única tela.',
      icon: Icons.domain_rounded,
      color: const Color(0xFFD97706),
      accentColor: const Color(0xFFFBBF24),
    ),
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;
          
          return Stack(
            children: [
              _buildDotGrid(),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: isWide 
                          ? _buildDesktopLayout() 
                          : _buildMobileLayout(),
                    ),
                    if (!isWide) _buildBottomActionArea(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        return _buildPageContent(_pages[index]);
      },
    );
  }

  Widget _buildDesktopLayout() {
    final page = _pages[_currentPage];
    
    return Row(
      children: [
        // Left Side: Illustration
        Expanded(
          flex: 1,
          child: Container(
            child: _buildHeroSection(page),
          ).animate(key: ValueKey('hero_$_currentPage'))
           .fadeIn(duration: 800.ms)
           .slideX(begin: -0.1, curve: Curves.easeOutQuart),
        ),
        
        // Right Side: Content
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(80.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextSection(page, crossAxisAlignment: CrossAxisAlignment.start),
                const SizedBox(height: 60),
                _buildDesktopActionArea(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopActionArea() {
    final page = _pages[_currentPage];
    final isLastPage = _currentPage == _pages.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            _pages.length,
            (index) => GestureDetector(
              onTap: () {
                setState(() => _currentPage = index);
                _pageController.jumpToPage(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                height: 6,
                width: _currentPage == index ? 32 : 12,
                decoration: BoxDecoration(
                  color: _currentPage == index ? page.color : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: 300,
          height: 64,
          child: ElevatedButton(
            onPressed: () {
              if (!isLastPage) {
                setState(() => _currentPage++);
                _pageController.animateToPage(
                  _currentPage,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutQuart,
                );
              } else {
                _finishOnboarding();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: page.color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              shadowColor: page.color.withValues(alpha: 0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLastPage ? 'COMEÇAR AGORA' : 'PRÓXIMO PASSO',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  size: 20,
                ),
              ],
            ),
          ).animate(key: ValueKey('btn_$_currentPage'))
           .scale(duration: 400.ms, curve: Curves.easeOut),
        ),
      ],
    );
  }

  Widget _buildDotGrid() {
    return Opacity(
      opacity: 0.3,
      child: CustomPaint(
        size: Size.infinite,
        painter: DotGridPainter(color: Colors.grey.withValues(alpha: 0.1)),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/logogerepag.png',
            height: 32,
            errorBuilder: (context, error, stackTrace) => Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: _pages[_currentPage].color, size: 24),
                const SizedBox(width: 8),
                Text(
                  'GerePag',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _finishOnboarding,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Pular',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(OnboardingData page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeroSection(page),
                  const SizedBox(height: 30),
                  _buildTextSection(page),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(OnboardingData page) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle outer ring
          Container(
            height: 230,
            width: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: page.color.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),

          // Main Icon Container
          Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: page.color.withValues(alpha: 0.05),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                page.icon,
                size: 75,
                color: page.color,
              ).animate(key: ValueKey(page.title))
               .scale(duration: 600.ms, curve: Curves.easeOutBack)
               .shimmer(delay: 1.seconds, duration: 2.seconds),
            ),
          ),
          
          // Decorative small dots
          ...List.generate(3, (index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 2 * 3.14159),
              duration: Duration(seconds: 10 + (index * 2)),
              builder: (context, value, child) {
                final angle = value + (index * 2);
                return Transform.translate(
                  offset: Offset(115 * 1, 0), // Base radius
                  child: Transform.rotate(
                    angle: angle,
                    child: Transform.translate(
                      offset: const Offset(115, 0),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: page.color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).where((_) => false).toList(), // Hidden for now for cleaner look
        ],
      ),
    );
  }

  Widget _buildTextSection(OnboardingData page, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center}) {
    bool isCentered = crossAxisAlignment == CrossAxisAlignment.center;
    
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          page.title,
          textAlign: isCentered ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.outfit(
            fontSize: isCentered ? 34 : 54, 
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: isCentered ? -0.8 : -1.5,
            height: 1.1,
          ),
        ).animate(key: ValueKey('t_${page.title}')).fadeIn(duration: 600.ms).slideY(begin: 0.2, curve: Curves.easeOutQuart),
        const SizedBox(height: 24),
        Text(
          page.description,
          textAlign: isCentered ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.inter(
            fontSize: isCentered ? 16 : 20,
            color: const Color(0xFF475569),
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ).animate(key: ValueKey('d_${page.title}')).fadeIn(delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
      ],
    );
  }

  Widget _buildBottomActionArea() {
    final page = _pages[_currentPage];
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentPage == index ? 24 : 6,
                decoration: BoxDecoration(
                  color: _currentPage == index ? page.color : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              if (!isLastPage) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutQuart,
                );
              } else {
                _finishOnboarding();
              }
            },
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: page.color.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: page.color.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? 'COMEÇAR AGORA' : 'PRÓXIMO PASSO',
                      style: GoogleFonts.outfit(
                        color: page.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                      color: page.color,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ).animate(key: ValueKey('btn_$_currentPage'))
           .scale(duration: 400.ms, begin: const Offset(0.98, 0.98), curve: Curves.easeOut),
        ],
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

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color accentColor;

  OnboardingData({
    required this.title, 
    required this.description, 
    required this.icon, 
    required this.color,
    required this.accentColor,
  });
}




