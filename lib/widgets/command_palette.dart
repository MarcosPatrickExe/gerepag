import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import '../models/omie_account.dart';
import '../screens/business_dashboard_screen.dart';
import '../screens/admin_settings_screen.dart';
import '../screens/document_vault_screen.dart';
import '../services/excel_export_service.dart';

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key});

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  List<CommandAction> _filteredActions = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateFilter('');
  }

  void _updateFilter(String query) {
    final provider = Provider.of<TransactionsProvider>(context, listen: false);
    final List<CommandAction> allActions = [
      CommandAction(
        title: '🚀 Abrir Portal BI Omie (5 Módulos)',
        subtitle: 'Dashboard completo: DRE, DFC, Aging, CRM, Vendas, What-If',
        icon: Icons.analytics_rounded,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const BusinessDashboardScreen()));
        },
      ),
      // Ações de Empresa
      ...provider.omieAccounts.map((acc) => CommandAction(
        title: 'Trocar para ${acc.name}',
        subtitle: 'Ativar conta empresarial da Omie',
        icon: Icons.business_rounded,
        onTap: () => provider.switchAccount(acc.id),
      )),
      
      // Ações de Navegação (Simuladas via State na Home)
      CommandAction(
        title: 'Ver DRE Gerencial',
        subtitle: 'Dashboard de faturamento e despesas',
        icon: Icons.table_view_rounded,
        onTap: () => _triggerNavigation(2), 
      ),
      CommandAction(
        title: 'Mapa de Calor Financeiro',
        subtitle: 'Visão geográfica de faturamento',
        icon: Icons.map_outlined,
        onTap: () => _triggerNavigation(4),
      ),
       CommandAction(
        title: 'Projeção de Fluxo (Forecast)',
        subtitle: 'Previsão de caixa baseada em IA',
        icon: Icons.auto_awesome,
        onTap: () => _triggerNavigation(1),
      ),

      // Ações Globais
      CommandAction(
        title: 'Gerar Relatório PDF',
        subtitle: 'Exportar fechamento executivo do mês',
        icon: Icons.picture_as_pdf_outlined,
        onTap: () => debugPrint('Exportando PDF...'),
      ),
      CommandAction(
        title: 'Exportar Planilha Excel',
        subtitle: 'Gerar .xlsx para contabilidade (.xlsx)',
        icon: Icons.table_chart_outlined,
        onTap: () => ExcelExportService.exportToExcel(provider),
      ),
      CommandAction(
        title: 'Alternar Modo Privacidade',
        subtitle: 'Esconder valores na tela',
        icon: Icons.remove_red_eye_outlined,
        onTap: () => provider.togglePrivacyMode(),
      ),
       CommandAction(
        title: 'Ativar Modo Empresarial',
        subtitle: 'Ligar/Desligar BI da Omie',
        icon: Icons.business_center,
        onTap: () => provider.toggleBusinessMode(),
      ),
      CommandAction(
        title: 'Cofre de Configurações',
        subtitle: 'Gerenciar chaves de API e IA',
        icon: Icons.security_rounded,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSettingsScreen())),
      ),
      CommandAction(
        title: 'Pasta Digital de Notas',
        subtitle: 'Ver histórico de documentos salvos',
        icon: Icons.folder_copy_rounded,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DocumentVaultScreen())),
      ),
    ];

    setState(() {
      _filteredActions = allActions
          .where((a) => a.title.toLowerCase().contains(query.toLowerCase()) || 
                       a.subtitle.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _selectedIndex = 0;
    });
  }

  void _triggerNavigation(int index) {
      // Aqui poderíamos usar um callback ou um evento global. 
      // Para este protótipo, vamos assumir que a navegação é feita via provider ou broadcast.
      Navigator.pop(context, index); // Retorna o index para a Home processar
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Center(
        child: Container(
          width: 600,
          height: 480,
          decoration: BoxDecoration(
            color: Color(0xFF1E293B).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10),
            ],
          ),
          child: Column(
            children: [
              _buildSearchField(),
              const Divider(color: AppTheme.textMuted),
              Expanded(
                child: _filteredActions.isEmpty
                    ? _buildEmptyState()
                    : _buildActionsList(),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack).fadeIn(),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppTheme.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textBody, fontSize: 18),
              onChanged: _updateFilter,
              decoration: const InputDecoration(
                hintText: 'O que você quer fazer agora?',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.textBody.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('ESC', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: _filteredActions.length,
      itemBuilder: (context, index) {
        final action = _filteredActions[index];
        final bool isSelected = _selectedIndex == index;

        return MouseRegion(
          onEnter: (_) => setState(() => _selectedIndex = index),
          child: GestureDetector(
            onTap: () {
                action.onTap();
                if (action.title.startsWith('Ver')) {
                    // Já tratado no Navigator.pop
                } else {
                    Navigator.pop(context);
                }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppTheme.primary.withValues(alpha: 0.3) : Colors.transparent),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(action.icon, color: isSelected ? AppTheme.primary : Colors.white54, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          action.subtitle,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) 
                    const Icon(Icons.keyboard_return_rounded, color: AppTheme.primary, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textBody.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('Nenhum comando encontrado', style: TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Row(
        children: [
          _buildKeyTip('↑↓', 'Navegar'),
          const SizedBox(width: 20),
          _buildKeyTip('Enter', 'Executar'),
          const Spacer(),
          const Text('GerePag Central de Comando v1.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildKeyTip(String key, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.textBody.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.textMuted),
          ),
          child: Text(key, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }
}

class CommandAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  CommandAction({required this.title, required this.subtitle, required this.icon, required this.onTap});
}
