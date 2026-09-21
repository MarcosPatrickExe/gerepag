import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/subscription_provider.dart';
import '../services/stripe_service.dart';

enum BillingCycle { monthly, quarterly, yearly }

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  BillingCycle _currentCycle = BillingCycle.monthly;
  final _couponController = TextEditingController();
  int _appliedDiscountPercent = 0;
  String? _couponError;
  String? _appliedCouponCode;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    setState(() {
      _couponError = null;
      if (code == 'GEREPAG30' || code == 'BPO30' || code == 'GLAUBER30') {
        _appliedDiscountPercent = 30;
        _appliedCouponCode = code;
      } else if (code.isEmpty) {
        _appliedDiscountPercent = 0;
        _appliedCouponCode = null;
      } else {
        _couponError = 'Cupom inválido ou expirado ❌';
        _appliedDiscountPercent = 0;
        _appliedCouponCode = null;
      }
    });
  }

  double _getDiscountedPrice(double originalPrice) {
    if (_appliedDiscountPercent > 0) {
      return originalPrice * (100 - _appliedDiscountPercent) / 100;
    }
    return originalPrice;
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildAppBar(context),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildCycleSelector(),
                  const SizedBox(height: 24),
                  _buildCouponInput(),
                  const SizedBox(height: 32),
                  
                  // Plan Cards Section
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isWide = constraints.maxWidth > 800;
                      if (isWide) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildProPlan(context, subProvider)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildFamilyPlan(context, subProvider)),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildProPlan(context, subProvider),
                          const SizedBox(height: 24),
                          _buildFamilyPlan(context, subProvider),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  
                  // Feature Comparison Section
                  _buildComparisonTable(),
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Cancele a qualquer momento. Renovação automática via Stripe.',
                    style: TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFFC084FC)], // Blue to Purple
          ).createShader(bounds),
          child: const Icon(Icons.workspace_premium_rounded, size: 72, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'Eleve seu Controle Financeiro',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'IA ilimitada, OCR avançado e relatórios White-Label',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildCycleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCycleButton('Mensal', BillingCycle.monthly),
          _buildCycleButton('Trimestral', BillingCycle.quarterly),
          _buildCycleButton('Anual', BillingCycle.yearly, hasDiscount: true),
        ],
      ),
    );
  }

  Widget _buildCycleButton(String label, BillingCycle cycle, {bool hasDiscount = false}) {
    bool isSelected = _currentCycle == cycle;
    return GestureDetector(
      onTap: () => setState(() => _currentCycle = cycle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.white.withValues(alpha: 0.12)) : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('17% OFF', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCouponInput() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _couponController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cupom de Desconto / Parceiro',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _applyCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('APLICAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          if (_couponError != null) ...[
            const SizedBox(height: 8),
            Text(_couponError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
          if (_appliedCouponCode != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Cupom $_appliedCouponCode aplicado: $_appliedDiscountPercent% de desconto! 🎉',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProPlan(BuildContext context, SubscriptionProvider provider) {
    double originalPrice = 49.90;
    String label = "/mês";
    if (_currentCycle == BillingCycle.quarterly) { originalPrice = 129.90; label = "/3 meses"; }
    if (_currentCycle == BillingCycle.yearly) { originalPrice = 497.00; label = "/ano"; }

    double finalPrice = _getDiscountedPrice(originalPrice);

    return _buildPlanCard(
      context,
      title: 'PLANO PRO',
      price: finalPrice,
      originalPrice: _appliedDiscountPercent > 0 ? originalPrice : null,
      periodLabel: label,
      gradientColors: [const Color(0xFF1E3A8A).withValues(alpha: 0.3), const Color(0xFF2563EB).withValues(alpha: 0.1)],
      accentColor: const Color(0xFF3B82F6),
      features: [
        'Scanner OCR Ilimitado 📸',
        'Relatórios PDF Profissionais 📄',
        'Consultoria IA Avançada 🧠',
        'Cofre de IA Desbloqueado',
        'Simulador DRE What-If',
      ],
      onTap: () => _handleUpgrade(context, provider, SubscriptionTier.pro, "PRO", finalPrice),
    );
  }

  Widget _buildFamilyPlan(BuildContext context, SubscriptionProvider provider) {
    double originalPrice = 97.00;
    String label = "/mês";
    if (_currentCycle == BillingCycle.quarterly) { originalPrice = 259.00; label = "/3 meses"; }
    if (_currentCycle == BillingCycle.yearly) { originalPrice = 997.00; label = "/ano"; }

    double finalPrice = _getDiscountedPrice(originalPrice);

    return _buildPlanCard(
      context,
      title: 'PLANO BUSINESS',
      isPopular: true,
      price: finalPrice,
      originalPrice: _appliedDiscountPercent > 0 ? originalPrice : null,
      periodLabel: label,
      gradientColors: [const Color(0xFF581C87).withValues(alpha: 0.3), const Color(0xFF7C3AED).withValues(alpha: 0.1)],
      accentColor: const Color(0xFF8B5CF6),
      features: [
        'Tudo do Plano Pro ✨',
        'Multi-Omie (Até 3 Empresas) 🏢',
        'Dashboard Holding Consolidado 📊',
        'Configurações de Relatório White-Label 📄',
        'Gestão de Equipes (Sócios/Colaboradores)',
        'Suporte prioritário via WhatsApp',
      ],
      onTap: () => _handleUpgrade(context, provider, SubscriptionTier.family, "BUSINESS", finalPrice),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required double price,
    double? originalPrice,
    required String periodLabel,
    required List<String> features,
    required List<Color> gradientColors,
    required Color accentColor,
    bool isPopular = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isPopular ? accentColor.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08), width: isPopular ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 2),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'RECOMENDADO',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (originalPrice != null) ...[
                Text(
                  'R\$ ${originalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.white30,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                'R\$ ${price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0, left: 4),
                child: Text(periodLabel, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: Colors.greenAccent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(f, style: const TextStyle(color: Colors.white, fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('COMEÇAR JÁ 🚀', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tabela Comparativa de Recursos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            border: TableBorder.symmetric(inside: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
            children: [
              _buildTableRow(['Recurso', 'Grátis', 'PRO', 'BUSINESS'], isHeader: true),
              _buildTableRow(['Scanner OCR', '3 / mês', 'Ilimitado', 'Ilimitado']),
              _buildTableRow(['IA Glauber', '2 / mês', 'Ilimitado', 'Ilimitado']),
              _buildTableRow(['Integrações Omie', '1', '1', 'Até 3 (Multi)']),
              _buildTableRow(['Relatórios Customizados', '❌', 'Sim (Simples)', 'Sim (White-Label)']),
              _buildTableRow(['Simulador DRE', '❌', 'Sim', 'Sim (Avançado)']),
              _buildTableRow(['Acessos de Equipe', '❌', '❌', 'Sim']),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(
            cell,
            textAlign: isHeader ? TextAlign.left : (cell == cells.first ? TextAlign.left : TextAlign.center),
            style: TextStyle(
              color: isHeader ? Colors.white : (cell == '❌' ? Colors.redAccent : Colors.white70),
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontSize: isHeader ? 12 : 11,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleUpgrade(BuildContext context, SubscriptionProvider provider, SubscriptionTier tier, String planName, double amount) async {
    final stripe = StripeService();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    String interval = 'month';
    int intervalCount = 1;

    if (_currentCycle == BillingCycle.quarterly) {
      interval = 'month';
      intervalCount = 3;
    } else if (_currentCycle == BillingCycle.yearly) {
      interval = 'year';
      intervalCount = 1;
    }

    try {
      final sessionData = await stripe.createCheckoutSession(
        planName: "$planName (${_currentCycle.name})",
        amount: amount,
        interval: interval,
        intervalCount: intervalCount,
      );
      
      if (context.mounted) Navigator.pop(context); // Fecha o loading inicial

      if (sessionData != null && sessionData['url'] != null) {
        final checkoutUrl = sessionData['url']!;
        final sessionId = sessionData['id']!;

        await stripe.launchStripeCheckout(checkoutUrl);
        
        if (context.mounted) {
          _showActivationDialog(context, provider, sessionId, tier);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao conectar com o Stripe.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fecha loading se houver erro
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  void _showActivationDialog(BuildContext context, SubscriptionProvider provider, String sessionId, SubscriptionTier tier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.greenAccent),
            SizedBox(width: 10),
            Text('Pagamento em Aberto', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A página de pagamento foi aberta no seu navegador.',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Após concluir o pagamento, clique no botão abaixo para ativar seu plano imediatamente.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () async {
              showDialog(
                context: dialogContext,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );

              final stripe = StripeService();
              final isPaid = await stripe.verifyPaymentStatus(sessionId);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext); // Fecha o loading interno
                
                if (isPaid) {
                  int days = 30;
                  if (_currentCycle == BillingCycle.quarterly) days = 90;
                  if (_currentCycle == BillingCycle.yearly) days = 365;

                  await provider.upgradeTo(
                    tier, 
                    sessionId: sessionId,
                    durationDays: days,
                  );
                  
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext); // Fecha o diálogo de ativação
                    _showSuccessDialog(context);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pagamento ainda não detectado. Conclua no navegador primeiro.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('JÁ PAGUEI, ATIVAR!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Parabéns! 🎉', style: TextStyle(color: Colors.white)),
        content: const Text('Seu plano Premium foi ativado e salvo com sucesso. Aproveite todos os recursos!', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Volta para a Home
            },
            child: const Text('VAMOS COMEÇAR!', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }
}
