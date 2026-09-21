import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../core/app_theme.dart';
import '../providers/subscription_provider.dart';
import '../providers/transactions_provider.dart';
import 'category_manager_screen.dart';
import 'badges_screen.dart';
import 'family_setup_screen.dart';
import 'upgrade_screen.dart';
import 'future_planning_screen.dart';
import 'custom_report_screen.dart';
import 'whatsapp_cobranca_screen.dart';
import 'clients_manager_screen.dart';
import 'freelancer_kanban_screen.dart';
import 'glauber_profile_screen.dart';
import 'portfolio_setup_screen.dart';
import '../services/pdf_report_service.dart';
import '../services/bank_sync_service.dart';
import '../services/bio_auth_service.dart';
import '../services/realtime_db_service.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:share_plus/share_plus.dart';
import '../models/omie_account.dart';
import '../models/transaction_model.dart';
import 'subscription_dashboard_screen.dart';
import 'break_even_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final transProvider = Provider.of<TransactionsProvider>(context);
    final bool isWide = MediaQuery.of(context).size.width > 900;
    final bool isBpo = transProvider.userNiche == 'bpo';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: isWide 
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna Esquerda: Assinatura e Gestão (Apenas para Freelancer/Pessoal)
                if (!isBpo) ...[
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildSubscriptionCard(context, subProvider),
                        const SizedBox(height: 32),
                        _buildBusinessSection(context, transProvider, subProvider),
                        const SizedBox(height: 32),
                        _buildContadorSection(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
                // Coluna Direita: Utilitários e Outros
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isBpo) ...[
                        _buildSectionTitle('AUTOMAÇÃO & PROJEÇÃO'),
                        const SizedBox(height: 16),
                        StatefulBuilder(
                          builder: (context, setState) {
                            return FutureBuilder<bool>(
                              future: NotificationsListener.hasPermission.then((v) => v ?? false),
                              builder: (context, permissionSnap) {
                                final bool hasPermission = permissionSnap.data ?? false;
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (hasPermission ? Colors.green : AppTheme.primary).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.sync_rounded,
                                      color: hasPermission ? Colors.green : AppTheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  title: const Text('Automação Bancária', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    hasPermission
                                        ? 'Status: Sincronização ativa ⚡'
                                        : 'Status: Desativado (Toque para permitir)',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                  trailing: Switch(
                                    value: hasPermission,
                                    activeColor: Colors.green,
                                    onChanged: (val) async {
                                      await BankSyncService.requestPermission();
                                      await BankSyncService.init();
                                      setState(() {});
                                    },
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                );
                              },
                            );
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.auto_graph,
                          title: 'Calculadora de Futuro',
                          subtitle: 'Projete sua independência financeira',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const FuturePlanningScreen()));
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                      _buildSectionTitle(isBpo ? 'RELATÓRIOS CONTÁBEIS' : 'UTILITÁRIOS PROFISSIONAIS'),
                      const SizedBox(height: 16),
                      if (!isBpo) ...[
                        _buildSettingsTile(
                          icon: Icons.chat_outlined,
                          title: 'Cobrança Rápida por WhatsApp',
                          subtitle: 'Crie lembretes de cobrança automáticos com IA',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const WhatsAppCobrancaScreen()));
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.psychology_outlined,
                          title: 'Perfil & Memória do Glauber',
                          subtitle: 'Ajuste a personalidade e ensine novos fatos ao assistente',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const GlauberProfileScreen()));
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.people_outline_rounded,
                          title: 'Meus Clientes',
                          subtitle: 'Cadastre e organize os contatos dos seus clientes',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsManagerScreen()));
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.key_rounded,
                          title: 'ID de Vinculação BPO',
                          subtitle: 'Copie seu ID para enviar ao seu Contador/BPO',
                          trailing: const Icon(Icons.copy_rounded, color: Colors.blueAccent, size: 18),
                          onTap: () {
                            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                            if (uid.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: uid));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ ID de Vinculação copiado!')),
                              );
                            }
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.view_kanban_rounded,
                          title: 'Kanban de Projetos',
                          subtitle: 'Gerencie o faturamento e progresso dos seus serviços',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const FreelancerKanbanScreen()));
                          },
                        ),
                        _buildSettingsTile(
                          icon: Icons.scale_rounded,
                          title: 'Ponto de Equilíbrio ⚖️',
                          subtitle: 'Calcule quanto precisa faturar para bater metas e cobrir custos',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const BreakEvenScreen()));
                          },
                        ),
                      ],
                      _buildSettingsTile(
                        icon: Icons.picture_as_pdf_outlined,
                        title: 'Exportar Mês em PDF',
                        subtitle: 'Relatório profissional (PRO)',
                        onTap: () {
                          if (isBpo) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomReportScreen()));
                          } else {
                            if (!subProvider.isPro) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
                              return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomReportScreen()));
                          }
                        },
                        trailing: (isBpo || subProvider.isPro) ? null : const Icon(Icons.lock, size: 16, color: Colors.orange),
                      ),
                      _buildSettingsTile(
                        icon: Icons.table_view_outlined,
                        title: 'Exportar Histórico (CSV)',
                        subtitle: 'Planilha completa para Excel (PRO)',
                        onTap: () => _exportToCsv(context, subProvider, transProvider),
                        trailing: (isBpo || subProvider.isPro) ? null : const Icon(Icons.lock, size: 16, color: Colors.orange),
                      ),
                      if (!isBpo) ...[
                        _buildSettingsTile(
                          icon: Icons.family_restroom,
                          title: 'Equipes & Gestão Business',
                          subtitle: 'Gerencie acessos de colaboradores e sócios',
                          onTap: () {
                            if (!subProvider.isFamily) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
                              return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilySetupScreen()));
                          },
                          trailing: subProvider.isFamily ? null : const Icon(Icons.lock, size: 16, color: Colors.orange),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _buildSectionTitle('PERSONALIZAÇÃO'),
                      const SizedBox(height: 16),
                      if (!isBpo) ...[
                        _buildSettingsTile(
                          icon: Icons.emoji_events,
                          title: 'Minhas Conquistas',
                          subtitle: 'Veja seus badges e troféus',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const BadgesScreen()));
                          },
                        ),
                      ],
                      _buildSettingsTile(
                        icon: Icons.category,
                        title: 'Gerenciar Categorias',
                        subtitle: 'Personalize suas categorias de gasto',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryManagerScreen()));
                        },
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('SEGURANÇA'),
                      const SizedBox(height: 16),
                      StatefulBuilder(
                        builder: (context, setState) {
                          return FutureBuilder<bool>(
                            future: BioAuthService().isBiometricsAvailable(),
                            builder: (context, bioAvailSnap) {
                              final bool available = bioAvailSnap.data ?? false;
                              if (!available) return const SizedBox.shrink();

                              return FutureBuilder<bool>(
                                future: BioAuthService().isEnabled(),
                                builder: (context, enabledSnap) {
                                  final bool enabled = enabledSnap.data ?? false;
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.fingerprint_rounded, color: AppTheme.primary, size: 20),
                                    ),
                                    title: const Text('Bloqueio por Biometria', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
                                    subtitle: const Text('Solicitar digital/faceID ao abrir o aplicativo', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                    trailing: Switch(
                                      value: enabled,
                                      activeColor: AppTheme.primary,
                                      onChanged: (val) async {
                                        await BioAuthService().setEnabled(val);
                                        setState(() {});
                                      },
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const Divider(height: 48),
                      _buildSettingsTile(
                        icon: Icons.logout,
                        title: 'Sair da Conta',
                        subtitle: 'Desconectar deste dispositivo',
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        color: AppTheme.expense,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                if (!isBpo) ...[
                  _buildSubscriptionCard(context, subProvider),
                  const SizedBox(height: 32),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return FutureBuilder<bool>(
                        future: NotificationsListener.hasPermission.then((v) => v ?? false),
                        builder: (context, permissionSnap) {
                          final bool hasPermission = permissionSnap.data ?? false;
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (hasPermission ? Colors.green : AppTheme.primary).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.sync_rounded,
                                color: hasPermission ? Colors.green : AppTheme.primary,
                                size: 20,
                              ),
                            ),
                            title: const Text('Automação Bancária', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              hasPermission
                                  ? 'Status: Sincronização ativa ⚡'
                                  : 'Status: Desativado (Toque para permitir)',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                            trailing: Switch(
                              value: hasPermission,
                              activeColor: Colors.green,
                              onChanged: (val) async {
                                await BankSyncService.requestPermission();
                                await BankSyncService.init();
                                setState(() {});
                              },
                            ),
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.auto_graph,
                    title: 'Calculadora de Futuro',
                    subtitle: 'Projete sua independência financeira',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FuturePlanningScreen()));
                    },
                  ),
                  const SizedBox(height: 32),
                ],
                _buildSectionTitle(isBpo ? 'RELATÓRIOS CONTÁBEIS' : 'UTILITÁRIOS'),
                const SizedBox(height: 16),
                if (!isBpo) ...[
                  _buildSettingsTile(
                    icon: Icons.chat_outlined,
                    title: 'Cobrança Rápida por WhatsApp',
                    subtitle: 'Crie lembretes de cobrança automáticos com IA',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const WhatsAppCobrancaScreen()));
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.psychology_outlined,
                    title: 'Perfil & Memória do Glauber',
                    subtitle: 'Ajuste a personalidade e ensine novos fatos ao assistente',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const GlauberProfileScreen()));
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.rocket_launch_outlined,
                    title: 'Meu Portfólio Público',
                    subtitle: 'Divulgue seus cases de faturamento e atraia clientes',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PortfolioSetupScreen()));
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.people_outline_rounded,
                    title: 'Meus Clientes',
                    subtitle: 'Cadastre e organize os contatos dos seus clientes',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsManagerScreen()));
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.key_rounded,
                    title: 'ID de Vinculação BPO',
                    subtitle: 'Copie seu ID para enviar ao seu Contador/BPO',
                    trailing: const Icon(Icons.copy_rounded, color: Colors.blueAccent, size: 18),
                    onTap: () {
                      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                      if (uid.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: uid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ ID de Vinculação copiado!')),
                        );
                      }
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.view_kanban_rounded,
                    title: 'Kanban de Projetos',
                    subtitle: 'Gerencie o faturamento e progresso dos seus serviços',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FreelancerKanbanScreen()));
                    },
                  ),
                ],
                _buildSettingsTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Exportar Mês em PDF',
                  subtitle: 'Relatório profissional (PRO)',
                  onTap: () {
                    if (isBpo) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomReportScreen()));
                    } else {
                      if (!subProvider.isPro) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
                        return;
                      }
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomReportScreen()));
                    }
                  },
                  trailing: (isBpo || subProvider.isPro) ? null : const Icon(Icons.lock, size: 16, color: Colors.orange),
                ),
                _buildSettingsTile(
                  icon: Icons.table_view_outlined,
                  title: 'Exportar Histórico (CSV)',
                  subtitle: 'Planilha completa para Excel (PRO)',
                  onTap: () => _exportToCsv(context, subProvider, transProvider),
                  trailing: (isBpo || subProvider.isPro) ? null : const Icon(Icons.lock, size: 16, color: Colors.orange),
                ),
                if (!isBpo) ...[
                  _buildSettingsTile(
                    icon: Icons.family_restroom,
                    title: 'Equipes & Gestão Business',
                    subtitle: 'Gerencie acessos de colaboradores e sócios',
                    onTap: () {
                      if (!subProvider.isFamily) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
                        return;
                      }
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FamilySetupScreen()));
                    },
                    trailing: subProvider.isFamily ? null : const Icon(Icons.lock, size: 16, color: Colors.orange),
                  ),
                ],
                const SizedBox(height: 32),
                _buildSectionTitle('PERSONALIZAÇÃO'),
                const SizedBox(height: 16),
                if (!isBpo) ...[
                  _buildSettingsTile(
                    icon: Icons.emoji_events,
                    title: 'Minhas Conquistas',
                    subtitle: 'Veja seus badges e troféus',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BadgesScreen()));
                    },
                  ),
                ],
                _buildSettingsTile(
                  icon: Icons.category,
                  title: 'Gerenciar Categorias',
                  subtitle: 'Personalize suas categorias de gasto',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryManagerScreen()));
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('SEGURANÇA'),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    return FutureBuilder<bool>(
                      future: BioAuthService().isBiometricsAvailable(),
                      builder: (context, bioAvailSnap) {
                        final bool available = bioAvailSnap.data ?? false;
                        if (!available) return const SizedBox.shrink();

                        return FutureBuilder<bool>(
                          future: BioAuthService().isEnabled(),
                          builder: (context, enabledSnap) {
                            final bool enabled = enabledSnap.data ?? false;
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.fingerprint_rounded, color: AppTheme.primary, size: 20),
                              ),
                              title: const Text('Bloqueio por Biometria', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Solicitar digital/faceID ao abrir o aplicativo', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              trailing: Switch(
                                value: enabled,
                                activeColor: AppTheme.primary,
                                onChanged: (val) async {
                                  await BioAuthService().setEnabled(val);
                                  setState(() {});
                                },
                              ),
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const Divider(height: 40),
                if (!isBpo) ...[
                  _buildBusinessSection(context, transProvider, subProvider),
                  const SizedBox(height: 40),
                  _buildContadorSection(context),
                  const SizedBox(height: 40),
                ],
                _buildSettingsTile(
                  icon: Icons.logout,
                  title: 'Sair da Conta',
                  subtitle: 'Desconectar deste dispositivo',
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  color: AppTheme.expense,
                ),
                const SizedBox(height: 48),
              ],
            ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionProvider provider) {
    String tierName = 'Plano Gratuito';
    Color tierColor = AppTheme.textMuted;
    if (provider.tier == SubscriptionTier.pro) { tierName = 'Plano Pro'; tierColor = AppTheme.primary; }
    if (provider.tier == SubscriptionTier.family) { tierName = 'Plano Business'; tierColor = Colors.purple; }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionDashboardScreen())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: provider.isPro ? tierColor.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(provider.isPro ? Icons.verified : Icons.star_border, color: tierColor, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textBody)),
                    Text(
                      provider.isPro ? 'Acesso total liberado!' : 'Desbloqueie recursos avançados',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            if (!provider.isPro) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SER PREMIUM AGORA 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSection(BuildContext context, TransactionsProvider provider, SubscriptionProvider subProvider) {
    final bool isGated = provider.omieAccounts.isNotEmpty && !subProvider.isFamily;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'EMPRESARIAL (MULTI-OMIE) 💼',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            Switch(
              value: provider.isBusinessMode,
              onChanged: (val) => provider.toggleBusinessMode(),
              activeColor: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: provider.isDemoMode ? Colors.cyan.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: provider.isDemoMode ? Colors.cyan.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              const Icon(Icons.psychology_alt_rounded, color: Colors.cyan),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modo Demonstração', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textBody)),
                    Text('Experimente o app com dados fictícios', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Switch(
                value: provider.isDemoMode,
                onChanged: (val) => provider.toggleDemoMode(),
                activeColor: Colors.cyan,
              ),
            ],
          ),
        ),
        ...provider.omieAccounts.map((acc) => _buildAccountItem(context, acc, provider)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              if (isGated) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
                return;
              }
              _showAddAccountDialog(context, provider);
            },
            icon: Icon(Icons.add, size: 18, color: isGated ? Colors.orange : Colors.blue),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ADICIONAR NOVA EMPRESA',
                  style: TextStyle(color: isGated ? Colors.orange : Colors.blue),
                ),
                if (isGated) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.lock, size: 14, color: Colors.orange),
                ]
              ],
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isGated ? Colors.orange : Colors.blue,
              side: BorderSide(color: isGated ? Colors.orange : Colors.blue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountItem(BuildContext context, OmieAccount acc, TransactionsProvider provider) {
    final isActive = acc.id == provider.activeAccountId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.blue.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isActive ? Colors.blue : Colors.black.withValues(alpha: 0.05),
            child: Icon(Icons.business, color: isActive ? Colors.white : AppTheme.textMuted, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textBody)),
                Text('KEY: ${acc.appKey.substring(0, 4)}****', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          if (!isActive)
            IconButton(
              onPressed: () => provider.switchAccount(acc.id),
              icon: const Icon(Icons.swap_horiz, color: Colors.blueAccent),
            ),
          IconButton(
            onPressed: () => _confirmDeleteAccount(context, acc, provider),
            icon: const Icon(Icons.delete_outline, color: AppTheme.expense),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, TransactionsProvider provider) {
    final nameController = TextEditingController();
    final keyController = TextEditingController();
    final secretController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Nova Empresa Omie', style: TextStyle(color: AppTheme.textBody)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textBody),
                decoration: const InputDecoration(labelText: 'Identificação (ex: Matriz)', labelStyle: TextStyle(color: AppTheme.textMuted)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                style: const TextStyle(color: AppTheme.textBody),
                decoration: const InputDecoration(labelText: 'App Key', labelStyle: TextStyle(color: AppTheme.textMuted)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: secretController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textBody),
                decoration: const InputDecoration(labelText: 'App Secret', labelStyle: TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && keyController.text.isNotEmpty && secretController.text.isNotEmpty) {
                provider.saveOmieAccount(nameController.text, keyController.text, secretController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, OmieAccount acc, TransactionsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Excluir Empresa?'),
        content: Text('Tem certeza que deseja remover ${acc.name}? Todos os dados locais sincronizados desta empresa serão limpos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('NÃO')),
          TextButton(
            onPressed: () {
              provider.removeAccount(acc.id);
              Navigator.pop(context);
            },
            child: const Text('SIM, EXCLUIR', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: (color ?? AppTheme.primary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color ?? AppTheme.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: color ?? AppTheme.textBody, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _exportToCsv(BuildContext context, SubscriptionProvider sub, TransactionsProvider trans) {
    if (!sub.isPro) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
      return;
    }

    // Lógica simples de CSV para exportação imediata
    String csv = 'Data,Categoria,Descricao,Valor,Tipo\n';
    for (var t in trans.transactions) {
      csv += '${t.date.toIso8601String()},${t.category},${t.description},${t.amount},${t.type.name}\n';
    }
    
    Share.share(csv, subject: 'Exportação Financeira Controle Real');
  }

  Widget _buildContadorSection(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    bool isLinking = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return StreamBuilder<Map<String, dynamic>?>(
          stream: RealtimeDbService().getLinkedAccountant(),
          builder: (context, snapshot) {
            final accountant = snapshot.data;
            final bool isLinked = accountant != null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONTADOR PARCEIRO 🤝',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isLinked ? Colors.teal.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: isLinked
                      ? Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.analytics_rounded, color: Colors.teal),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    accountant['name'] ?? 'Contador Parceiro',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textBody),
                                  ),
                                  Text(
                                    accountant['email'] ?? '',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${accountant['uid']}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
                              tooltip: 'Desvincular Contador',
                              onPressed: () async {
                                await RealtimeDbService().unlinkAccountant();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🔄 Contador desvinculado com sucesso.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Conectar com seu Contador',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textBody),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Insira o ID de Vinculação fornecido pelo seu contador parceiro para liberar o acesso dele para auditoria fiscal.',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      hintText: 'Cole o ID do Contador aqui...',
                                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                      filled: true,
                                      fillColor: Colors.black.withValues(alpha: 0.02),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.teal),
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textBody),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isLinking
                                        ? null
                                        : () async {
                                            final id = controller.text.trim();
                                            if (id.isEmpty) return;

                                            setState(() => isLinking = true);
                                            final success = await RealtimeDbService().linkAccountant(id);
                                            setState(() => isLinking = false);

                                            if (context.mounted) {
                                              if (success) {
                                                controller.clear();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('✅ Contador parceiro conectado!'),
                                                    backgroundColor: Colors.teal,
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('⚠️ ID inválido ou usuário não cadastrado como contador.'),
                                                    backgroundColor: Colors.redAccent,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    child: isLinking
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('VINCULAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
