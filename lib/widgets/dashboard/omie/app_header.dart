import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/transactions_provider.dart';
import '../../../providers/user_stats_provider.dart';
import '../../../core/app_theme.dart';
import '../../../screens/war_room_screen.dart';
import '../../../screens/zen_investments_screen.dart';
import '../../../screens/settings_screen.dart';
import '../../../screens/login_screen.dart';
import '../../../screens/family_setup_screen.dart';
import '../../../screens/scanner_screen.dart';
import '../../../screens/goals_screen.dart';
import '../../../screens/insights_screen.dart';
import '../../../screens/ai_chat_screen.dart';
import '../../../screens/business_dashboard_screen.dart';
import '../../../services/pdf_report_service.dart';
import '../../../services/realtime_db_service.dart';
import '../../premium_period_selector.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback onShowSyncCenter;
  final VoidCallback? onStartVoice;
  final bool isVoiceListening;

  const AppHeader({
    super.key,
    required this.onShowSyncCenter,
    this.onStartVoice,
    this.isVoiceListening = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final statsProvider = Provider.of<UserStatsProvider>(context);
    final bool isBusiness = provider.isBusinessMode;
    final bool isMobile = MediaQuery.of(context).size.width < 650;
    final activeClientUid = RealtimeDbService.bpoActiveClientUid;

    return Column(
      children: [
        if (activeClientUid != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Modo BPO: Visualizando conta do cliente.',
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    RealtimeDbService().setBpoActiveClient(null);
                    await provider.init();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('VOLTAR AO PAINEL BPO', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isMobile) ...[
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF2563EB)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/logogerepag.png',
                height: 28,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2563EB), size: 28),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBusiness ? 'Gestão Corporativa' : 'Suas Finanças',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isBusiness && provider.omieAccounts.isNotEmpty)
                    PopupMenuButton<String>(
                      onSelected: (id) => provider.switchAccount(id),
                      offset: const Offset(0, 40),
                      elevation: 4,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              provider.activeAccount?.name ?? 'Empresa',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF0F172A),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB), size: 24),
                        ],
                      ),
                      itemBuilder: (context) => provider.omieAccounts.map((acc) {
                        final isActive = acc.id == provider.activeAccountId;
                        return PopupMenuItem<String>(
                          value: acc.id,
                          child: Row(
                            children: [
                              Icon(Icons.business_rounded, color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8), size: 20),
                              const SizedBox(width: 12),
                              Text(
                                acc.name,
                                style: GoogleFonts.inter(
                                  color: isActive ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Text(
                      'Olá, ${provider.userName}!',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0F172A),
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isMobile) ...[
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessDashboardScreen())),
                      icon: const Icon(Icons.analytics_rounded, size: 16, color: Colors.white),
                      label: const Text('PORTAL BI OMIE 🚀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FamilySetupScreen())),
                      icon: const Icon(Icons.group_add_outlined, color: Colors.purpleAccent, size: 22),
                      tooltip: 'Modo Família',
                    ),
                    const SizedBox(width: 8),
                    if (isBusiness) _buildSyncButton(provider),
                    const SizedBox(width: 8),
                    if (isBusiness)
                      IconButton(
                        onPressed: () {
                          final summary = provider.executiveSummary;
                          Share.share(summary);
                        },
                        icon: const Icon(Icons.share, color: Colors.cyanAccent, size: 20),
                      ),
                  ],
                  
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                    offset: const Offset(0, 45),
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    itemBuilder: (context) => [
                      if (isMobile) ...[
                        PopupMenuItem(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessDashboardScreen())),
                          child: const _ActionMenuItem(icon: Icons.analytics_rounded, label: 'Portal BI Omie 🚀', color: Colors.cyanAccent),
                        ),
                         PopupMenuItem(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FamilySetupScreen())),
                          child: const _ActionMenuItem(icon: Icons.group_add_outlined, label: 'Modo Família', color: Colors.purpleAccent),
                        ),
                        if (isBusiness)
                          PopupMenuItem(
                            onTap: onShowSyncCenter,
                            child: const _ActionMenuItem(icon: Icons.sync, label: 'Sincronizar', color: Colors.blueAccent),
                          ),
                      ],
                      if (provider.omieAccounts.length > 1)
                        PopupMenuItem(
                          onTap: () => provider.toggleConsolidatedMode(),
                          child: _ActionMenuItem(
                            icon: provider.isConsolidatedMode ? Icons.group_work_rounded : Icons.business_rounded,
                            label: provider.isConsolidatedMode ? 'Modo Individual' : 'Modo Grupo',
                            color: provider.isConsolidatedMode ? Colors.orange : Colors.white60,
                          ),
                        ),
                      PopupMenuItem(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WarRoomScreen())),
                        child: const _ActionMenuItem(icon: Icons.security_rounded, label: 'War Room', color: AppTheme.primary),
                      ),
                      PopupMenuItem(
                        onTap: () => PdfReportService.generateExecutiveReport(provider),
                        child: const _ActionMenuItem(icon: Icons.picture_as_pdf, label: 'Relatório PDF', color: Colors.redAccent),
                      ),
                      PopupMenuItem(
                        onTap: () => provider.togglePrivacyMode(),
                        child: _ActionMenuItem(
                          icon: provider.isPrivacyMode ? Icons.visibility : Icons.visibility_off,
                          label: provider.isPrivacyMode ? 'Mostrar Valores' : 'Modo Privacidade',
                          color: provider.isPrivacyMode ? AppTheme.primary : AppTheme.expense,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              _buildFilterModeTab(provider, OmieFilterMode.monthly, 'Mensal'),
              _buildFilterModeTab(provider, OmieFilterMode.yearly, 'Anual'),
              _buildFilterModeTab(provider, OmieFilterMode.custom, 'Período'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PremiumPeriodSelector(provider: provider),
        if (!isBusiness) ...[
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'NÍVEL ${statsProvider.level}',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    'Faltam ${statsProvider.xpToNextLevel} XP',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: statsProvider.progressToNextLevel,
                  backgroundColor: AppTheme.textMuted.withValues(alpha: 0.1),
                  color: AppTheme.primary,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildHeaderAction(context, Icons.document_scanner, 'Scanner', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen()))),
              const SizedBox(width: 12),
              _buildHeaderAction(
                context,
                isVoiceListening ? Icons.mic : Icons.mic_none_rounded,
                isVoiceListening ? 'Ouvindo...' : 'Glauber',
                onStartVoice ?? () {},
                color: isVoiceListening ? Colors.redAccent : Colors.blueAccent,
              ),
              const SizedBox(width: 12),
              _buildHeaderAction(context, Icons.card_giftcard, 'Metas', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsScreen()))),
              const SizedBox(width: 12),
              _buildHeaderAction(context, Icons.auto_awesome, 'Coach IA', () => Navigator.push(context, MaterialPageRoute(builder: (context) => AiChatScreen()))),
              const SizedBox(width: 12),
              _buildHeaderAction(context, Icons.insights, 'Análises', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InsightsScreen()))),
              const SizedBox(width: 12),
              _buildHeaderAction(context, Icons.balance, 'Zen', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ZenInvestmentsScreen()))),
              const SizedBox(width: 12),
              _buildHeaderAction(context, Icons.settings, 'Ajustes', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))),
              _buildHeaderAction(context, Icons.logout, 'Sair', () async {
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
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                  }
                }
              }, color: Colors.redAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncButton(TransactionsProvider provider) {
    final bool isSyncing = provider.isRefreshingOmie;
    final Map<String, String> statuses = provider.accountSyncStatuses;
    final bool hasError = statuses.values.any((s) => s == 'Erro');

    return Stack(
      children: [
        IconButton(
          onPressed: onShowSyncCenter,
          icon: Icon(
            isSyncing ? Icons.sync : Icons.cloud_done_rounded,
            color: hasError ? Colors.redAccent : (isSyncing ? Colors.blueAccent : Colors.greenAccent),
            size: 20,
          ),
          tooltip: 'Saúde da Conexão (Sync Center)',
        ).animate(onPlay: (controller) => isSyncing ? controller.repeat() : controller.stop())
         .rotate(duration: 2.seconds),
        if (hasError)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterModeTab(TransactionsProvider provider, OmieFilterMode mode, String label) {
    final bool isSelected = provider.omieFilterMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setOmieFilterMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color color = const Color(0xFF2563EB)}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionMenuItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
