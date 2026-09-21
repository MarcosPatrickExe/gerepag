import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/transactions_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../screens/home_screen.dart';
import '../../../screens/goals_screen.dart';
import '../../../screens/simulation_screen.dart';
import '../../../screens/admin_dashboard_screen.dart';
import '../../../screens/dre_what_if_screen.dart';
import '../../../screens/upgrade_screen.dart';
import '../../../screens/freelancer_kanban_screen.dart';
import '../../../screens/bpo_tower_screen.dart';
import '../../../screens/proposal_generator_screen.dart';
import '../../../screens/business_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../screens/login_screen.dart';
import '../../../screens/settings_screen.dart';
import '../../../screens/user_profile_screen.dart';

class AppSidebar extends StatelessWidget {
  final TransactionsProvider provider;
  final DashboardType currentDashboard;
  final Function(DashboardType) onDashboardChanged;
  final bool extended;

  const AppSidebar({
    super.key,
    required this.provider,
    required this.currentDashboard,
    required this.onDashboardChanged,
    required this.extended,
  });

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);

    return Container(
      width: extended ? 260 : 80,
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          const SizedBox(height: 32),
          if (extended)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Image.asset('assets/images/logogerepag.png', height: 32, errorBuilder: (c, e, s) => const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2563EB), size: 32)),
                  const SizedBox(width: 12),
                  const Text('GerePag', style: TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            )
          else
            const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2563EB), size: 32),
          const SizedBox(height: 24),

          // BOTÃO DESTACADO DE ACESSO AOS 5 MÓDULOS BI OMIE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BusinessDashboardScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF06B6D4)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
                    if (extended) ...[
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'BI OMIE (5 MÓDULOS)',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSidebarIcon(Icons.dashboard_rounded, DashboardType.summary, 'Dashboard', extended),

                  
                  // 1. Módulos para BPO Financeiro
                  if (provider.userNiche == 'bpo') ...[
                    _buildBpoTowerItem(context, extended),
                    _buildSidebarIcon(Icons.trending_up_rounded, DashboardType.income, 'Receitas', extended),
                    _buildSidebarIcon(Icons.trending_down_rounded, DashboardType.expense, 'Despesas', extended),
                    _buildSidebarIcon(Icons.analytics_rounded, DashboardType.dre, 'DRE Matrix', extended),
                    _buildSidebarIcon(Icons.view_kanban_rounded, DashboardType.os, 'OS Kanban', extended),
                    _buildSidebarIcon(Icons.map_rounded, DashboardType.map, 'Geográfico', extended),
                    _buildSidebarIcon(Icons.compare_arrows_rounded, DashboardType.comparison, 'Comparativo', extended),
                    _buildPortalBiItem(extended),
                    _buildDreSimulatorItem(context, subProvider, extended),
                  ],

                  // 2. Módulos para PME (Empresa com Omie)
                  if (provider.userNiche == 'pme') ...[
                    _buildSidebarIcon(Icons.trending_up_rounded, DashboardType.income, 'Receitas', extended),
                    _buildSidebarIcon(Icons.trending_down_rounded, DashboardType.expense, 'Despesas', extended),
                    _buildSidebarIcon(Icons.analytics_rounded, DashboardType.dre, 'DRE Matrix', extended),
                    _buildDreSimulatorItem(context, subProvider, extended),
                  ],

                  // 3. Módulos para Infoprodutor (Vendas e Recuperação)
                  if (provider.userNiche == 'infoprodutor') ...[
                    _buildSidebarIcon(Icons.trending_up_rounded, DashboardType.income, 'Vendas Totais', extended),
                    _buildSidebarIcon(Icons.compare_arrows_rounded, DashboardType.comparison, 'Desempenho', extended),
                    _buildSidebarIcon(Icons.account_balance_wallet_outlined, DashboardType.wallets, 'Minhas Contas', extended),
                    // Item customizado de Recuperação de Vendas por IA
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Painel de Recuperação IA Glauber ativo! 🤖'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.bolt, color: Colors.orange, size: 22),
                              if (extended) ...[
                                const SizedBox(width: 12),
                                const Text('Recuperação IA', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // 4. Módulos para Autônomo / Freelancer (B2C)
                  if (provider.userNiche == 'autonomo') ...[
                    _buildSidebarIcon(Icons.account_balance_wallet_outlined, DashboardType.wallets, 'Minhas Contas', extended),
                    _buildSidebarIcon(Icons.credit_card, DashboardType.creditCards, 'Meus Cartões', extended),
                    _buildSidebarIcon(Icons.pie_chart_outline, DashboardType.budget, 'Orçamentos', extended),
                    _buildSidebarIcon(Icons.subscriptions_outlined, DashboardType.subscriptions, 'Assinaturas', extended),
                    _buildSidebarIcon(Icons.calendar_month_outlined, DashboardType.installments, 'Parcelas', extended),
                    _buildKanbanItem(context, extended),
                    _buildProposalGeneratorItem(context, extended),
                    _buildGoalsItem(context, extended),
                    _buildSimulatorItem(context, extended),
                  ],
                ],
              ),
            ),
          ),
          if (provider.userRole == 'admin')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen())),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, color: Colors.orangeAccent, size: 22),
                      if (extended) ...[
                        const SizedBox(width: 12),
                        const Text('Super Admin', style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (extended && !subProvider.isPro) ...[
            const Divider(height: 24, indent: 24, endIndent: 24),
            _buildUsageLimitsCard(context, subProvider),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Row(
                  mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 22),
                    if (extended) ...[
                      const SizedBox(width: 12),
                      const Text(
                        'Meu Perfil',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Row(
                  mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.settings_outlined, color: Color(0xFF64748B), size: 22),
                    if (extended) ...[
                      const SizedBox(width: 12),
                      const Text(
                        'Configurações',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () => _handleLogout(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Row(
                  mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                    if (extended) ...[
                      const SizedBox(width: 12),
                      const Text(
                        'Sair da Conta',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Conta?'),
        content: const Text('Deseja realmente desconectar deste dispositivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SAIR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => const LoginScreen()), 
          (route) => false,
        );
      }
    }
  }

  Widget _buildBpoTowerItem(BuildContext context, bool extended) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BpoTowerScreen()),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.business_center_rounded, color: Color(0xFF7C3AED), size: 22),
              if (extended) ...[
                const SizedBox(width: 12),
                const Text('Torre BPO', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortalBiItem(bool extended) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {}, // Future logic
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Color(0xFF2563EB), size: 22),
              if (extended) ...[
                const SizedBox(width: 12),
                const Text('Portal BI', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDreSimulatorItem(BuildContext context, SubscriptionProvider subProvider, bool extended) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          if (!subProvider.isPro) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DreWhatIfScreen()));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.query_stats_rounded, 
                color: subProvider.isPro ? const Color(0xFF64748B) : Colors.orange, 
                size: 22
              ),
              if (extended) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Simulador DRE', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
                      if (!subProvider.isPro)
                        const Icon(Icons.lock, size: 14, color: Colors.orange),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsItem(BuildContext context, bool extended) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsScreen())),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.savings_outlined, color: Color(0xFF2563EB), size: 22),
              if (extended) ...[
                const SizedBox(width: 12),
                const Text('Minhas Metas', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatorItem(BuildContext context, bool extended) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SimulationScreen())),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.psychology_outlined, color: Color(0xFF64748B), size: 22),
              if (extended) ...[
                const SizedBox(width: 12),
                const Text('Simulador', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKanbanItem(BuildContext context, bool extended) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FreelancerKanbanScreen())),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.view_kanban_rounded, color: Color(0xFF2563EB), size: 22),
              if (extended) ...[
                const SizedBox(width: 12),
                const Text('Projetos & Kanban', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProposalGeneratorItem(BuildContext context, bool extended) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProposalGeneratorScreen())),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.rocket_launch, color: Color(0xFF10B981), size: 22),
              if (extended) ...[
                const SizedBox(width: 12),
                const Text('Gerador Orçamento ⚡', style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarIcon(IconData icon, DashboardType type, String label, bool extended) {
    final bool isSelected = currentDashboard == type;
    return GestureDetector(
      onTap: () => onDashboardChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B), size: 22),
            if (extended) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageLimitsCard(BuildContext context, SubscriptionProvider subProvider) {
    final ocrPct = (subProvider.ocrUsageCount / 3).clamp(0.0, 1.0);
    final negPct = (subProvider.negotiationUsageCount / 2).clamp(0.0, 1.0);
    
    final bool nearLimit = subProvider.ocrUsageCount >= 2 || subProvider.negotiationUsageCount >= 1;
    final Color progressColor = nearLimit ? Colors.orange : const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: progressColor, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Limites do Plano Grátis',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // OCR limit line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Scanner OCR', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text('${subProvider.ocrUsageCount}/3', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ocrPct,
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
          // Negotiation limit line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IA Glauber', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text('${subProvider.negotiationUsageCount}/2', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: negPct,
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: progressColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text(
                'LIBERAR ACESSO 🚀',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}
