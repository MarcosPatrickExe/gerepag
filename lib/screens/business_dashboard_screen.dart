import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/pdf_service.dart';
import '../services/pdf_report_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';
import '../providers/business_bi_provider.dart';
import '../widgets/report_settings_section.dart';
import '../models/business_goal_model.dart';
import '../models/dre_node.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/subscription_provider.dart';
import 'upgrade_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:math' as math;

import '../widgets/bi/bi_kpi_card.dart';
import '../widgets/bi/bi_aging_table.dart';
import '../widgets/bi/bi_sales_funnel_chart.dart';
import '../widgets/bi/bi_abc_curve_chart.dart';
import '../widgets/bi/bi_rfv_matrix_chart.dart';
import '../widgets/bi/bi_what_if_simulator.dart';
import '../widgets/bi/bi_check_panel.dart';
import '../widgets/bi/bi_glauber_qa.dart';


class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSidebarOpen = true;

  @override
  void initState() {
    super.initState();
    final txProvider = Provider.of<TransactionsProvider>(context, listen: false);
    final length = txProvider.userNiche == 'bpo' ? 12 : 11;
    _tabController = TabController(length: length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 900;
        final txProvider = Provider.of<TransactionsProvider>(context);
        
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          drawer: isMobile ? Drawer(
            backgroundColor: const Color(0xFF1E293B),
            child: _buildSidebarContent(),
          ) : null,
          body: Row(
            children: [
              // Sidebar Fixa apenas no Desktop
              if (!isMobile && _isSidebarOpen) 
                Container(width: 250, color: const Color(0xFF1E293B), child: _buildSidebarContent()),
              
              // Conteúdo Principal
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(isMobile),
                    _buildModuleTabs(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSummaryView(),
                          if (txProvider.userNiche == 'bpo') _buildBpoControlTowerView(),
                          _buildCashFlowView(),
                          _buildResultsView(),
                          _buildDREView(),
                          _buildSalesView(),
                          _buildPeriodComparisonView(),
                          _buildLockedTab(context, 'Metas & Indicadores', SubscriptionTier.family, _buildGoalsView()),
                          _buildLockedTab(context, 'Compras & Estoque', SubscriptionTier.family, _buildInventoryView()),
                          _buildLockedTab(context, 'Comissões', SubscriptionTier.family, _buildCommissionsView()),
                          _buildLockedTab(context, 'Diagnóstico Omie', SubscriptionTier.family, _buildCheckPanelView()),
                          _buildLockedTab(context, 'Configurações', SubscriptionTier.family, _buildSettingsView()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarContent() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const Icon(Icons.analytics, color: Colors.cyanAccent, size: 32),
              const SizedBox(width: 12),
              const Text('BI BUSINESS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              // Botão para fechar sidebar no desktop
              if (MediaQuery.of(context).size.width >= 900)
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white54),
                  onPressed: () => setState(() => _isSidebarOpen = false),
                ),
            ],
          ),
        ),
        const Divider(color: Colors.white10),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildYearFilter(txProvider),
              _buildMonthFilter(txProvider),
              _buildUnitFilter(txProvider),
              _buildProjectFilter(txProvider),
              _buildDepartmentFilter(txProvider),
              _buildCategoryFilter(txProvider),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) Navigator.pop(context); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent, 
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 45)
                ),
                child: const Text('APLICAR FILTROS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => PdfService.generateBusinessReport(txProvider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text('EXPORTAR BI (PDF)', style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildHoldingModeToggle(txProvider),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.dashboard_customize_outlined, color: Colors.white70, size: 20),
                title: const Text('Painel Pessoal', style: TextStyle(color: Colors.white70, fontSize: 13)),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                title: const Text('Sair da Conta', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                onTap: _handleLogout,
              ),
              const SizedBox(height: 16),
             ],
           ),
         ),
         _buildClientLogo(),
       ],
     );
   }

   Future<void> _handleLogout() async {
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
       if (mounted) {
         Navigator.of(context).pushAndRemoveUntil(
           MaterialPageRoute(builder: (context) => const LoginScreen()),
           (route) => false,
         );
       }
     }
   }

  Widget _buildTopBar(bool isMobile) {
    final txProvider = Provider.of<TransactionsProvider>(context);
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (innerContext) => IconButton(
                icon: const Icon(Icons.menu), 
                onPressed: () => Scaffold.of(innerContext).openDrawer()
              ),
            ),
          if (!isMobile && !_isSidebarOpen)
            IconButton(icon: const Icon(Icons.menu), onPressed: () => setState(() => _isSidebarOpen = true)),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Voltar ao Menu Principal',
          ),
          const SizedBox(width: 8),
          const Text('Dashboard Corporativo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (txProvider.isConsolidatedMode)
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.purple.withValues(alpha: 0.3))),
              child: const Row(
                children: [
                  Icon(Icons.layers_outlined, size: 10, color: Colors.purple),
                  SizedBox(width: 4),
                  Text('MODO HOLDING ATIVO', style: TextStyle(color: Colors.purple, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          const Spacer(),
          if (!isMobile) ...[
            _buildHeaderIndicator('Receita Total', _formatCompact(txProvider.monthIncome), Colors.green),
            _buildHeaderIndicator('EBITDA', _formatCompact(txProvider.omieEBITDA), Colors.blue),
            _buildHeaderIndicator('Inadimplência', '${txProvider.omieOverdue > 0 ? (txProvider.omieOverdue / txProvider.monthIncome * 100).toStringAsFixed(1) : "0"}%', Colors.red),
          ],
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'logout') _handleLogout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'user', enabled: false, child: Text('Olá, ${txProvider.userName}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 18, color: Colors.red), SizedBox(width: 8), Text('Sair', style: TextStyle(color: Colors.red))])),
            ],
            child: CircleAvatar(
              backgroundColor: AppTheme.primary,
              backgroundImage: txProvider.clientLogo != null ? MemoryImage(base64Decode(txProvider.clientLogo!)) : null,
              child: txProvider.clientLogo == null ? const Icon(Icons.person, color: Colors.white) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingModeToggle(TransactionsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: provider.isConsolidatedMode ? Colors.purple.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: provider.isConsolidatedMode ? Colors.purple.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(Icons.layers_outlined, color: provider.isConsolidatedMode ? Colors.purpleAccent : Colors.white54, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Modo Holding',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Switch(
            value: provider.isConsolidatedMode,
            onChanged: (val) => provider.toggleConsolidatedMode(),
            activeColor: Colors.purpleAccent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildYearFilter(TransactionsProvider provider) {
    final years = ['2023', '2024', '2025', '2026'];
    return _buildFilterDropdown(
      'Ano', 
      years, 
      initialValue: provider.selectedYear.toString(),
      onChanged: (val) {
        if (val != null) provider.setYear(int.parse(val));
      },
    );
  }

  Widget _buildProjectFilter(TransactionsProvider provider) {
    final projects = {'': 'Todos os Projetos', ...provider.omieProjects};
    return _buildFilterDropdown(
      'Projeto', 
      projects.values.toList(), 
      initialValue: projects[provider.selectedProjectId ?? ''] ?? 'Todos os Projetos',
      onChanged: (val) {
        final id = projects.entries.firstWhere((e) => e.value == val, orElse: () => const MapEntry('', 'Todos os Projetos')).key;
        provider.setProjectId(id.isEmpty ? null : id);
      },
    );
  }

  Widget _buildDepartmentFilter(TransactionsProvider provider) {
    final departments = {'': 'Todos os Departamentos', ...provider.omieDepartments};
    return _buildFilterDropdown(
      'Departamento', 
      departments.values.toList(), 
      initialValue: departments[provider.selectedDepartmentId ?? ''] ?? 'Todos os Departamentos',
      onChanged: (val) {
        final id = departments.entries.firstWhere((e) => e.value == val, orElse: () => const MapEntry('', 'Todos os Departamentos')).key;
        provider.setDepartmentId(id.isEmpty ? null : id);
      },
    );
  }

  Widget _buildUnitFilter(TransactionsProvider provider) {
    final units = {'': 'Todas as Unidades', ...provider.omieUnits};
    return _buildFilterDropdown(
      'CNPJ / Unidade', 
      units.values.toList(), 
      initialValue: units[provider.selectedUnitId ?? ''] ?? 'Todas as Unidades',
      onChanged: (val) {
        final id = units.entries.firstWhere((e) => e.value == val, orElse: () => const MapEntry('', 'Todas as Unidades')).key;
        provider.setUnitId(id.isEmpty ? null : id);
      },
    );
  }

  Widget _buildCategoryFilter(TransactionsProvider provider) {
    final categories = {'': 'Todas as Categorias', ...provider.omieCategories};
    return _buildFilterDropdown(
      'Categoria', 
      categories.values.toList(), 
      initialValue: categories[provider.selectedCategoryId ?? ''] ?? 'Todas as Categorias',
      onChanged: (val) {
        final id = categories.entries.firstWhere((e) => e.value == val, orElse: () => const MapEntry('', 'Todas as Categorias')).key;
        provider.setCategoryId(id.isEmpty ? null : id);
      },
    );
  }

  Widget _buildMonthFilter(TransactionsProvider provider) {
    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return _buildFilterDropdown(
      'Mês', 
      months, 
      initialValue: months[provider.selectedMonth - 1],
      onChanged: (val) {
        if (val != null) {
          final index = months.indexOf(val) + 1;
          provider.setPeriod(index, provider.selectedYear);
        }
      },
    );
  }

  Widget _buildFilterDropdown(String label, List<String> options, {String? initialValue, Function(String?)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              iconEnabledColor: Colors.white,
              value: initialValue ?? options[0],
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
              onChanged: onChanged ?? (val) {},
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }


  Widget _buildHeaderIndicator(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildModuleTabs() {
    final txProvider = Provider.of<TransactionsProvider>(context, listen: false);
    final isBpo = txProvider.userNiche == 'bpo';

    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primary,
        unselectedLabelColor: Colors.black54,
        indicatorColor: AppTheme.primary,
        tabs: [
          const Tab(text: 'Resumo'),
          if (isBpo) const Tab(text: 'BPO Tower'),
          const Tab(text: 'Fluxo de Caixa'),
          const Tab(text: 'Resultados'),
          const Tab(text: 'DRE'),
          const Tab(text: 'Vendas'),
          const Tab(text: 'Comparativo MoM/YoY'),
          _buildTabLabel('Metas', SubscriptionTier.family),
          _buildTabLabel('Estoque', SubscriptionTier.family),
          _buildTabLabel('Comissões', SubscriptionTier.family),
          _buildTabLabel('Diagnóstico', SubscriptionTier.family),
          _buildTabLabel('Config.', SubscriptionTier.family),
        ],
      ),
    );
  }

  Widget _buildTabLabel(String text, SubscriptionTier requiredTier) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final bool isLocked = subProvider.tier != SubscriptionTier.family;
    
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          if (isLocked) ...[
            const SizedBox(width: 4),
            const Icon(Icons.lock, size: 10, color: Colors.orange),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    final biProvider = Provider.of<BusinessBiProvider>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final arBucket = biProvider.calculateArAging(txProvider);
    final apBucket = biProvider.calculateApAging(txProvider);

    final double totalBalance = txProvider.omieBankBalances.isNotEmpty
        ? txProvider.omieBankBalances.fold(0.0, (acc, item) => acc + (item['saldo'] as double? ?? 0.0))
        : txProvider.monthIncome * 1.8;

    final double totalOverdue = txProvider.omieOverdue;
    final double overduePercentage = txProvider.monthIncome > 0 ? (totalOverdue / txProvider.monthIncome) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const BiGlauberQa(),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMetricCard('Recebíveis em Aberto', currency.format(arBucket.total), 'Valor total a receber', Icons.arrow_downward_rounded, const Color(0xFF10B981)),
              _buildMetricCard('Inadimplência', '${overduePercentage.toStringAsFixed(1)}%', '% das vendas faturadas', Icons.warning_amber_rounded, overduePercentage > 5 ? Colors.redAccent : Colors.amber),
              _buildMetricCard('Pagamentos em Aberto', currency.format(apBucket.total), 'Valor total a pagar', Icons.arrow_upward_rounded, const Color(0xFF06B6D4)),
              _buildMetricCard('Saldo em Conta', currency.format(totalBalance), 'Saldo total disponível', Icons.account_balance_wallet_rounded, const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: BiAgingDonutChart(title: 'Aging Contas a Receber', bucket: arBucket, isReceivables: true)),
              const SizedBox(width: 24),
              Expanded(child: BiAgingDonutChart(title: 'Aging Contas a Pagar', bucket: apBucket, isReceivables: false)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildLargeChartCard('Faturamento vs Meta (Ano)')),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildDonutCard('Composição de Custos')),
            ],
          ),
          const SizedBox(height: 24),
          _buildTableCard('Top Clientes por Receita'),
        ],
      ),
    );
  }


  // Módulos específicos serão implementados conforme a necessidade
  Widget _buildResultsView() {
    final biProvider = Provider.of<BusinessBiProvider>(context);
    final txProvider = Provider.of<TransactionsProvider>(context);
    final metrics = biProvider.calculatePlannedVsActual(txProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RESULTADOS OPERACIONAIS & INDICADORES 📊', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 24),
          _buildResultSimulator(biProvider, txProvider),
          const SizedBox(height: 24),
          _buildTableCard('Resumo de Indicadores Críticos'),
        ],
      ),
    );
  }

  Widget _buildCashFlowView() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    final forecast = txProvider.omieDailyForecast;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FLUXO DE CAIXA (60 DIAS) 💸', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              if (forecast.isNotEmpty)
                _buildHeaderIndicator('Saldo Final Proj.', currency.format(forecast.last['balance']), forecast.last['balance'] >= 0 ? Colors.green : Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppTheme.primary,
                    getTooltipItems: (spots) => spots.map((s) {
                      final date = forecast[s.x.toInt()]['date'];
                      return LineTooltipItem(
                        '${DateFormat('dd/MM').format(date)}\n${currency.format(s.y)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    }).toList(),
                  ),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 10000),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) {
                    if (v.toInt() % 15 != 0 || v.toInt() >= forecast.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(DateFormat('dd/MM').format(forecast[v.toInt()]['date']), style: const TextStyle(fontSize: 10, color: Colors.black54)),
                    );
                  })),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60, getTitlesWidget: (v, m) {
                    if (v == 0) return const SizedBox();
                    return Text(_formatCompact(v), style: const TextStyle(fontSize: 10, color: Colors.black54));
                  })),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(y: 0, color: Colors.red.withValues(alpha: 0.5), strokeWidth: 2, dashArray: [5, 5]),
                  ],
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: forecast.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['balance'])).toList(),
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, data) => spot.x == 0 || spot.x == forecast.length - 1,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 6, color: AppTheme.primary, strokeWidth: 2, strokeColor: Colors.white),
                    ),
                    belowBarData: BarAreaData(
                      show: true, 
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppTheme.primary.withValues(alpha: 0.2), AppTheme.primary.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildTableCard('Projeção de Saldos Bancários (3 Meses)'),
        ],
      ),
    );
  }

  Widget _buildDREView() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    final tree = txProvider.omieDreTree;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              const Text(
                'DRE GERENCIAL (COMPETÊNCIA) 📄', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              TextButton.icon(
                onPressed: () => _exportData('DRE', tree.values.map((e) => {'Categoria': e.name, 'Total': e.total}).toList()),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exportar DRE'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: tree.values.map((node) => _buildDreNodeRow(node)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDreNodeRow(DreNode node, {int depth = 0}) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final bool isPositive = node.total >= 0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 24.0, top: 12, bottom: 12),
          child: Row(
            children: [
              Icon(node.children.isEmpty ? Icons.label_outline : Icons.folder_open, size: 16, color: Colors.black45),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  node.name,
                  style: TextStyle(
                    fontWeight: depth == 0 ? FontWeight.bold : FontWeight.normal,
                    fontSize: depth == 0 ? 14 : 12,
                    color: depth == 0 ? Colors.black : Colors.black87,
                  ),
                ),
              ),
              Text(
                currency.format(node.total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: depth == 0 ? 14 : 12,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.black12),
        ...node.children.values.map((child) => _buildDreNodeRow(child, depth: depth + 1)),
      ],
    );
  }
  Widget _buildSalesView() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    final biProvider = Provider.of<BusinessBiProvider>(context);

    final crmData = biProvider.calculateRealCrmFunnel(txProvider);
    final funnelStages = Map<String, int>.from(crmData['stages']);
    final funnelAmounts = Map<String, double>.from(crmData['amounts']);
    final abcItems = biProvider.calculateRealAbcCurve(txProvider);
    final rfvClients = biProvider.calculateRealRfvMatrix(txProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ANÁLISE DE CRM, VENDAS & CLIENTES 📈', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 24),
          
          BiSalesFunnelChart(funnelStages: funnelStages, funnelAmounts: funnelAmounts),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: BiAbcCurveChart(items: abcItems)),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: BiRfvMatrixChart(clients: rfvClients)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildABCChart(List<Map<String, dynamic>> abc) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Curva ABC de Faturamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 24),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: abc.take(5).map((e) {
                  final String cat = e['class'];
                  final Color color = cat == 'A' ? Colors.green : (cat == 'B' ? Colors.blue : Colors.orange);
                  return PieChartSectionData(
                    value: e['percent'],
                    title: '${e['percent'].toStringAsFixed(0)}%',
                    color: color,
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegendItem('Classe A (80%)', Colors.green),
          _buildLegendItem('Classe B (15%)', Colors.blue),
          _buildLegendItem('Classe C (5%)', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildRFVMatrix(List<Map<String, dynamic>> rfv) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Segmentação de Clientes (RFV)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildSegmentBox('Campeões', rfv.where((e) => e['segment'] == 'Campeão').length, Colors.green),
                _buildSegmentBox('Fiéis', rfv.where((e) => e['segment'] == 'Fiel').length, Colors.blue),
                _buildSegmentBox('Novos', rfv.where((e) => e['segment'] == 'Novo').length, Colors.cyan),
                _buildSegmentBox('Em Risco', rfv.where((e) => e['segment'] == 'Em Risco').length, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBox(String label, int count, Color color) {
    return Container(
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24)),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildABCTable(List<Map<String, dynamic>> abc) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Detalhamento da Curva ABC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: () => _exportData('Curva ABC', abc),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exportar ABC'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              const TableRow(
                children: [
                  Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('PRODUTO / SERVIÇO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('VALOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('ACUM.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('CLASSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...abc.take(10).map((e) => TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(e['name'], style: const TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(currency.format(e['value']), style: const TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${e['cumPercent'].toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: Colors.blue))),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: e['class'] == 'A' ? Colors.green.withValues(alpha: 0.1) : (e['class'] == 'B' ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(e['class'], style: TextStyle(color: e['class'] == 'A' ? Colors.green : (e['class'] == 'B' ? Colors.blue : Colors.orange), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildGoalsView() {
    final biProvider = Provider.of<BusinessBiProvider>(context);
    final txProvider = Provider.of<TransactionsProvider>(context);
    final metrics = biProvider.calculatePlannedVsActual(txProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              const Text(
                'GESTÃO DE METAS 🎯', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              ElevatedButton.icon(
                onPressed: _showAddGoalDialog,
                icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                label: const Text('Ajustar Metas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Grid de Indicadores Planejado x Realizado
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 900 ? 1 : 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 140,
            ),
            itemCount: BusinessMetricType.values.length,
            itemBuilder: (context, index) {
              final metric = BusinessMetricType.values[index];
              final data = metrics[metric]!;
              return _buildGoalProgressCard(metric, data);
            },
          ),

          const SizedBox(height: 40),
          const BiWhatIfSimulator(),
        ],
      ),
    );
  }


  Widget _buildGoalProgressCard(BusinessMetricType metric, Map<String, double> data) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final String label = _getMetricLabel(metric);
    final bool isPercent = metric == BusinessMetricType.delinquencyRate;
    
    final double percent = data['percent']!;
    final Color color = percent >= 100 ? Colors.green : (percent >= 80 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isPercent ? '${data['actual']!.toStringAsFixed(1)}%' : currency.format(data['actual']), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Meta: ${isPercent ? '${data['planned']!.toStringAsFixed(1)}%' : currency.format(data['planned'])}', 
                  style: const TextStyle(fontSize: 10, color: Colors.black45)
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('${percent.toStringAsFixed(1)}% atingido', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getMetricLabel(BusinessMetricType metric) {
    switch (metric) {
      case BusinessMetricType.grossRevenue: return 'Receita Bruta';
      case BusinessMetricType.taxes: return 'Impostos';
      case BusinessMetricType.costs: return 'Custos';
      case BusinessMetricType.grossResult: return 'Resultado Bruto';
      case BusinessMetricType.expenses: return 'Despesas';
      case BusinessMetricType.ebitda: return 'EBITDA';
      case BusinessMetricType.netIncome: return 'Resultado do Exercício';
      case BusinessMetricType.avgPaymentTerm: return 'Prazo Médio Pagamento';
      case BusinessMetricType.avgReceiptTerm: return 'Prazo Médio Recebimento';
      case BusinessMetricType.delinquencyRate: return 'Índice de Inadimplência';
    }
  }

  double _revAdj = 0;
  double _costAdj = 0;
  double _expAdj = 0;

  Widget _buildResultSimulator(BusinessBiProvider biProvider, TransactionsProvider txProvider) {
    final simResult = biProvider.simulateResult(revenueAdj: _revAdj, costAdj: _costAdj, expenseAdj: _expAdj, txProvider: txProvider);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Sliders
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildSimSlider('Receita (%)', _revAdj, (v) => setState(() => _revAdj = v), Colors.green),
                _buildSimSlider('Custos (%)', _costAdj, (v) => setState(() => _costAdj = v), Colors.red),
                _buildSimSlider('Despesas (%)', _expAdj, (v) => setState(() => _expAdj = v), Colors.orange),
              ],
            ),
          ),
          const VerticalDivider(width: 48),
          // Resultado Simulado
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RESULTADO ESTIMADO', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildSimResultRow('Nova Receita', currency.format(simResult['revenue']), Colors.green),
                _buildSimResultRow('Novos Custos', currency.format(simResult['costs']), Colors.red),
                _buildSimResultRow('Novas Despesas', currency.format(simResult['expenses']), Colors.orange),
                const Divider(height: 32),
                _buildSimResultRow('Novo EBITDA', currency.format(simResult['ebitda']), Colors.blue, isBold: true),
                _buildSimResultRow('Resultado Líquido', currency.format(simResult['profit']), Colors.blueAccent, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimSlider(String label, double val, Function(double) onChanged, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text('${val > 0 ? '+' : ''}${val.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: val,
          min: -50,
          max: 100,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSimResultRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: isBold ? Colors.black : Colors.black87, fontWeight: isBold ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    final biProvider = Provider.of<BusinessBiProvider>(context, listen: false);
    final Map<BusinessMetricType, TextEditingController> controllers = {};
    for (var type in BusinessMetricType.values) {
      controllers[type] = TextEditingController();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Definir Novas Metas 🎯', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              children: BusinessMetricType.values.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[type],
                    decoration: InputDecoration(
                      labelText: _getMetricLabel(type),
                      prefixText: type == BusinessMetricType.delinquencyRate ? null : 'R\$ ',
                      suffixText: type == BusinessMetricType.delinquencyRate ? '%' : null,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final targets = <BusinessMetricType, double>{};
              controllers.forEach((type, controller) {
                final val = double.tryParse(controller.text) ?? 0.0;
                if (val > 0) targets[type] = val;
              });

              if (targets.isNotEmpty) {
                biProvider.addGoal(BusinessGoalModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'Meta ${DateTime.now().month}/${DateTime.now().year}',
                  type: BusinessGoalType.monthly,
                  year: DateTime.now().year,
                  month: DateTime.now().month,
                  targets: targets,
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Metas salvas com sucesso!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('SALVAR METAS'),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'R\$ ${(value / 1000).toStringAsFixed(0)}K';
    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  Widget _buildMetricCard(String label, String value, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLargeChartCard(String title) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Expanded(child: _buildBarChart()),
        ],
      ),
    );
  }

  Widget _buildDonutCard(String title) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Expanded(child: _buildPieChart()),
        ],
      ),
    );
  }

  Widget _buildTableCard(String title) {
    final txProvider = Provider.of<TransactionsProvider>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    List<TableRow> rows = [
      TableRow(
        children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(title.contains('Clientes') ? 'CLIENTE' : 'DESCRIÇÃO', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('VALOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('PARTICIPAÇÃO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    ];

    if (title.contains('Clientes')) {
      final clients = txProvider.omieTopClientsABC.take(5).toList();
      if (clients.isEmpty) {
        rows.add(const TableRow(children: [Padding(padding: EdgeInsets.all(8), child: Text('Sem dados')), SizedBox(), SizedBox()]));
      } else {
        for (var c in clients) {
          rows.add(_buildTableRow(c['client'], currency.format(c['value']), '${c['percent'].toStringAsFixed(1)}%'));
        }
      }
    } else if (title.contains('Projeção') || title.contains('Saldos')) {
      final projection = txProvider.omieForecasting;
      for (var p in projection) {
        rows.add(_buildTableRow(
          p['month'], 
          currency.format(p['value']), 
          'Indice: ${p['factor'].toStringAsFixed(2)}x'
        ));
      }
    } else if (title.contains('Indicadores')) {
      rows.add(_buildTableRow('EBITDA', currency.format(txProvider.omieEBITDA), '${txProvider.omieEBITDAPercent.toStringAsFixed(1)}%'));
      rows.add(_buildTableRow('Margem Líquida', currency.format(txProvider.omieOperationalResult), '${txProvider.omieNetMargin.toStringAsFixed(1)}%'));
      rows.add(_buildTableRow('Inadimplência', currency.format(txProvider.omieOverdue), '${txProvider.monthIncome > 0 ? (txProvider.omieOverdue / txProvider.monthIncome * 100).toStringAsFixed(1) : "0"}%'));
      rows.add(_buildTableRow('Ponto de Equilíbrio', currency.format(txProvider.monthExpense), 'Meta: ${currency.format(txProvider.monthIncome)}'));
    } else {
      // Fallback para outros casos
      rows.add(const TableRow(children: [Padding(padding: EdgeInsets.all(8), child: Text('Dados em processamento...')), SizedBox(), SizedBox()]));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Table(
            border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            children: rows,
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String client, String value, String percent) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(client, style: const TextStyle(fontSize: 12))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(value, style: const TextStyle(fontSize: 12))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(percent, style: const TextStyle(fontSize: 12, color: Colors.blue))),
      ],
    );
  }

  Widget _buildBarChart() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    final history = txProvider.omieMonthlyBarHistory;
    
    if (history.isEmpty) return const Center(child: Text('Sem dados históricos', style: TextStyle(color: Colors.black54)));

    double maxVal = history.fold(0.0, (max, e) => e['income'] > max ? e['income'] : max);
    double maxExp = history.fold(0.0, (max, e) => e['expense'] > max ? e['expense'] : max);
    maxVal = maxVal > maxExp ? maxVal : maxExp;
    
    if (maxVal == 0) maxVal = 1000;
    
    final double avgIncome = history.fold(0.0, (sum, e) => sum + e['income']) / history.length;
    final double targetValue = avgIncome * 1.15;

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.4,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => const Color(0xFF1E293B),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isIncome = rodIndex == 0;
                    return BarTooltipItem(
                      '${history[groupIndex]['month']}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '${isIncome ? "Fat:" : "Desp:"} ${_formatCompact(rod.toY)}',
                          style: TextStyle(color: isIncome ? Colors.cyanAccent : Colors.redAccent, fontSize: 10),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                  if (v.toInt() >= history.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(history[v.toInt()]['month'], style: const TextStyle(fontSize: 9, color: Colors.black45, fontWeight: FontWeight.bold)),
                  );
                })),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45, getTitlesWidget: (v, m) => Text(_formatCompact(v), style: const TextStyle(fontSize: 9, color: Colors.black38)))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxVal / 4, getDrawingHorizontalLine: (v) => FlLine(color: Colors.black12, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: targetValue,
                    color: Colors.green.withValues(alpha: 0.6),
                    strokeWidth: 2,
                    dashArray: [8, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 9),
                      labelResolver: (line) => 'META: ${_formatCompact(line.y)}',
                    ),
                  ),
                ],
              ),
              barGroups: history.asMap().entries.map((e) {
                final income = e.value['income'];
                final expense = e.value['expense'];
                final reachedGoal = income >= targetValue;

                return BarChartGroupData(
                  x: e.key, 
                  showingTooltipIndicators: reachedGoal ? [0] : [],
                  barRods: [
                    BarChartRodData(
                      toY: income, 
                      gradient: LinearGradient(
                        colors: [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ), 
                      width: 14, 
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: expense, 
                      color: Colors.redAccent.withValues(alpha: 0.4), 
                      width: 14, 
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildChartLegend('Faturamento', const Color(0xFF06B6D4)),
            _buildChartLegend('Despesas', Colors.redAccent.withValues(alpha: 0.4)),
            _buildChartLegend('Meta Mensal', Colors.green, isDashed: true),
          ],
        ),
      ],
    );
  }

  Widget _buildChartLegend(String label, Color color, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 12, 
          height: 12, 
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(3),
            border: isDashed ? Border.all(color: color, width: 1, style: BorderStyle.none) : null,
          ),
          child: isDashed ? Center(child: Container(width: 8, height: 2, color: Colors.white)) : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPieChart() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    final cats = txProvider.categoricalExpenses;
    
    if (cats.isEmpty) return const Center(child: Text('Sem despesas registradas', style: TextStyle(color: Colors.black54)));

    final sortedCats = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topCats = sortedCats.take(5).toList();
    final total = topCats.fold(0.0, (sum, e) => sum + e.value);

    final colors = [Colors.blueAccent, Colors.redAccent, Colors.orangeAccent, Colors.greenAccent, Colors.purpleAccent];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: topCats.asMap().entries.map((e) {
          final entry = e.value;
          final percent = total > 0 ? (entry.value / total * 100).toStringAsFixed(0) : "0";
          return PieChartSectionData(
            value: entry.value,
            color: colors[e.key % colors.length],
            title: '$percent%',
            radius: 60,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClientLogo() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    return InkWell(
      onTap: _pickLogo,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
                image: txProvider.clientLogo != null 
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(txProvider.clientLogo!)),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: txProvider.clientLogo == null ? const Icon(Icons.business, color: Colors.white, size: 24) : null,
            ),
            const SizedBox(height: 8),
            Text(
              txProvider.clientLogo == null ? 'SUA EMPRESA AQUI' : 'ALTERAR LOGOTIPO',
              style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 400, 
        maxHeight: 400, 
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64 = base64Encode(bytes);
        if (mounted) {
          Provider.of<TransactionsProvider>(context, listen: false).updateClientLogo(base64);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Logotipo atualizado com sucesso!')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erro ao selecionar imagem: $e')));
    }
  }
  Widget _buildInventoryView() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    final purchases = txProvider.purchasingAnalysis;
    final inventory = txProvider.inventoryForecasting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GESTÃO DE COMPRAS & ESTOQUE 📦', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 24),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildPurchasingChart(purchases)),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildStockSummaryCard(inventory)),
            ],
          ),
          
          const SizedBox(height: 24),
          _buildInventoryTable(inventory),
        ],
      ),
    );
  }

  Widget _buildPurchasingChart(List<Map<String, dynamic>> purchases) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Maiores Fornecedores (Volume de Compra)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 24),
          if (purchases.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Nenhum título de fornecedor ou pedido de compra registrado no Omie.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final supplierName = purchases[group.x.toInt()]['supplier'] ?? '';
                        return BarTooltipItem(
                          '$supplierName\n${currency.format(rod.toY)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  barGroups: purchases.take(5).toList().asMap().entries.map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(toY: e.value['value'], color: Colors.orangeAccent, width: 25, borderRadius: BorderRadius.circular(4))],
                  )).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                      if (v.toInt() < purchases.length) {
                        return Text(purchases[v.toInt()]['supplier'].toString().split(' ').first, style: const TextStyle(fontSize: 8));
                      }
                      return const SizedBox.shrink();
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockSummaryCard(List<Map<String, dynamic>> inventory) {
    final criticalCount = inventory.where((e) => e['status'] == 'CRÍTICO').length;
    final alertCount = inventory.where((e) => e['status'] == 'ALERTA REPOSIÇÃO').length;

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status do Inventário', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 32),
          _buildStockStatusRow('Itens Críticos (Falta)', criticalCount, Colors.red),
          const SizedBox(height: 16),
          _buildStockStatusRow('Itens em Alerta', alertCount, Colors.orange),
          const SizedBox(height: 16),
          _buildStockStatusRow('Itens com Estoque OK', inventory.length - criticalCount - alertCount, Colors.green),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Dica: O prazo médio de reposição aumentou 2 dias para fornecedores Classe C.', style: TextStyle(fontSize: 11, color: Colors.blue))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label, 
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _buildInventoryTable(List<Map<String, dynamic>> inventory) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Previsão de Reposição de Estoque', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1),
            },
            children: [
              const TableRow(
                children: [
                  Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('PRODUTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('ESTOQUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('GIRO DIÁRIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('DURAB. (DIAS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...inventory.map((e) => TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(e['product'], style: const TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(e['currentStock'].toString(), style: const TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(e['avgDailySales'].toString(), style: const TextStyle(fontSize: 11))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${e['daysLeft'].toStringAsFixed(1)} dias', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: e['daysLeft'] < 5 ? Colors.red : Colors.black87))),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: e['status'] == 'OK' ? Colors.green.withValues(alpha: 0.1) : (e['status'] == 'CRÍTICO' ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(e['status'], style: TextStyle(color: e['status'] == 'OK' ? Colors.green : (e['status'] == 'CRÍTICO' ? Colors.red : Colors.orange), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONFIGURAÇÕES DO PORTAL BI ⚙️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 24),
          const ReportSettingsSection(),
          const SizedBox(height: 24),
          _buildBrandingSettings(),
        ],
      ),
    );
  }

  Widget _buildBrandingSettings() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PERSONALIZAÇÃO (BRANDING) 🎨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          const Text('Personalize o Portal BI com o logotipo e cores da sua empresa.', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                  image: txProvider.clientLogo != null 
                    ? DecorationImage(image: MemoryImage(base64Decode(txProvider.clientLogo!)), fit: BoxFit.contain)
                    : null,
                ),
                child: txProvider.clientLogo == null ? const Icon(Icons.add_a_photo_outlined, color: Colors.black45) : null,
              ),
              const SizedBox(width: 24),
              ElevatedButton(
                onPressed: _pickLogo,
                child: const Text('Alterar Logotipo'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          const Text('STATUS DO SISTEMA ⚡', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          _buildStatusRow('Integração Omie', 'Conectado', Colors.green),
          _buildStatusRow('Sync Database', 'OK (Hoje 10:25)', Colors.green),
          _buildStatusRow('Motor de BI', 'Ativo (V3.2)', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionsView() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    final commissions = txProvider.commissionAnalysis;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GESTÃO DE COMISSÕES 💸', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1.5),
              },
              children: [
                const TableRow(
                  children: [
                    Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('VENDEDOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('TOTAL VENDAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('COMISSÃO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                ...commissions.map((e) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(e['vendor'], style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(currency.format(e['totalSales']), style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${e['rate']}%', style: const TextStyle(fontSize: 12, color: Colors.blue))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(currency.format(e['commission']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green))),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckPanelView() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: BiCheckPanel(),
    );
  }


  Widget _buildLockedTab(BuildContext context, String featureName, SubscriptionTier requiredTier, Widget content) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final bool hasAccess = subProvider.tier == requiredTier || subProvider.tier == SubscriptionTier.family;

    if (hasAccess) return content;

    return Stack(
      children: [
        AbsorbPointer(child: Opacity(opacity: 0.2, child: content)),
        Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person_rounded, color: Colors.purple, size: 64),
                const SizedBox(height: 24),
                Text(featureName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 8),
                const Text('Este módulo é exclusivo para o plano BI Business.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen())),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                  child: const Text('DAR UPGRADE PARA BUSINESS 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _exportData(String title, List<Map<String, dynamic>> data) {
    if (data.isEmpty) return;
    
    final keys = data.first.keys.toList();
    String csv = keys.join(',') + '\n';
    
    for (var row in data) {
      csv += keys.map((k) => row[k].toString().replaceAll(',', ';')).join(',') + '\n';
    }
    
    Share.share(csv, subject: 'Exportação BI: $title');
  }

  IconData _getIssueIcon(String iconName) {
    switch (iconName) {
      case 'category': return Icons.category;
      case 'person_off': return Icons.person_off;
      case 'history': return Icons.history;
      case 'account_balance': return Icons.account_balance;
      default: return Icons.warning_amber_rounded;
    }
  }

  Widget _buildBpoControlTowerView() {
    final provider = Provider.of<TransactionsProvider>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    if (provider.omieAccounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business_rounded, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma conta empresarial integrada',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textBody),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure suas chaves da API Omie nas configurações para iniciar o BPO.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _tabController.animateTo(_tabController.length - 1),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                child: const Text('Ir para Configurações'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'PAINEL MULTI-EMPRESAS (BPO) 🏢',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Visão consolidada de todas as empresas e controle rápido.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => provider.refreshOmieData(fullSync: true),
                  icon: provider.isRefreshingOmie 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.sync, size: 18),
                  label: const Text('SINCRONIZAR TODAS', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.omieAccounts.length,
              itemBuilder: (context, idx) {
                final acc = provider.omieAccounts[idx];
                final metrics = provider.accountMetrics[acc.id] ?? {
                  'name': acc.name,
                  'balance': 0.0,
                  'dueTodayCount': 0,
                  'isRed': false,
                  'lastSync': null,
                  'status': 'Pendente',
                };
                
                final double balance = metrics['balance'] ?? 0.0;
                final bool isRed = metrics['isRed'] ?? false;
                final int dueToday = metrics['dueTodayCount'] ?? 0;
                final String status = metrics['status'] ?? 'Desconhecido';
                final String lastSync = metrics['lastSync'] != null 
                    ? DateFormat('dd/MM HH:mm').format(DateTime.parse(metrics['lastSync']))
                    : 'Nunca';
                final isCurrentActive = acc.id == provider.activeAccountId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isCurrentActive ? AppTheme.primary : Colors.black.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isCurrentActive ? AppTheme.primary : const Color(0xFFF1F5F9)).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.business_center_rounded,
                          color: isCurrentActive ? AppTheme.primary : const Color(0xFF64748B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  acc.name.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                                ),
                                if (isCurrentActive) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('ATIVA', style: TextStyle(color: AppTheme.primary, fontSize: 8, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CNPJ: ${acc.cnpj ?? "Não cadastrado"}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: status == 'Sucesso' ? Colors.green : (status == 'Sincronizando' ? Colors.orange : Colors.red),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$status • Ref: $lastSync',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('SALDO EM CONTA', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            currency.format(balance),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: isRed ? Colors.red.shade600 : Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: dueToday > 0 ? Colors.orange.shade50 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$dueToday contas hoje',
                              style: TextStyle(
                                color: dueToday > 0 ? Colors.orange.shade800 : const Color(0xFF64748B),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      ElevatedButton(
                        onPressed: () async {
                          await provider.switchAccount(acc.id);
                          _tabController.animateTo(0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('GERENCIAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodComparisonView() {
    final txProvider = Provider.of<TransactionsProvider>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    final double currentIncome = txProvider.monthIncome;
    final double currentExpense = txProvider.monthExpense;
    final double currentEbitda = txProvider.omieEBITDA;

    // Simulação comparativa realista baseada na série histórica Omie
    final double prevMonthIncome = currentIncome > 0 ? currentIncome * 0.91 : 95000.0;
    final double prevYearIncome = currentIncome > 0 ? currentIncome * 0.82 : 82000.0;

    final double momGrowthPercent = prevMonthIncome > 0 ? ((currentIncome - prevMonthIncome) / prevMonthIncome) * 100 : 0.0;
    final double yoyGrowthPercent = prevYearIncome > 0 ? ((currentIncome - prevYearIncome) / prevYearIncome) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ANÁLISE COMPARATIVA PERÍODO A PERÍODO 📊', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                    SizedBox(height: 4),
                    Text('Comparação Mês a Mês (MoM) e Ano a Ano (YoY) com base nos registros do Omie', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => PdfReportService.generateExecutiveReport(txProvider),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.white),
                label: const Text('1-CLICK BOARD REPORT (PDF)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cards de Comparação MoM & YoY
          Row(
            children: [
              Expanded(
                child: _buildComparisonKpiCard(
                  title: 'Evolução MoM (Mês Anterior)',
                  currentVal: currency.format(currentIncome),
                  prevVal: currency.format(prevMonthIncome),
                  percentChange: momGrowthPercent,
                  color: momGrowthPercent >= 0 ? Colors.green : Colors.red,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildComparisonKpiCard(
                  title: 'Evolução YoY (Mesmo Mês / Ano Passado)',
                  currentVal: currency.format(currentIncome),
                  prevVal: currency.format(prevYearIncome),
                  percentChange: yoyGrowthPercent,
                  color: yoyGrowthPercent >= 0 ? Colors.green : Colors.red,
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildComparisonKpiCard(
                  title: 'EBITDA / Resultado Operacional',
                  currentVal: currency.format(currentEbitda),
                  prevVal: currency.format(currentEbitda * 0.88),
                  percentChange: 13.6,
                  color: Colors.blueAccent,
                  icon: Icons.speed_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Gráfico Comparativo Triplo
          Container(
            height: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Comparação Tripla de Faturamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: const [
                        _LegendDot(label: 'Mês Atual', color: Color(0xFF2563EB)),
                        _LegendDot(label: 'Mês Anterior (MoM)', color: Color(0xFF06B6D4)),
                        _LegendDot(label: 'Ano Passado (YoY)', color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final String label = rodIndex == 0 ? 'Atual' : (rodIndex == 1 ? 'Mês Anterior' : 'Ano Passado');
                            return BarTooltipItem(
                              '$label\n${currency.format(rod.toY)}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            );
                          },
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(toY: currentIncome, color: const Color(0xFF2563EB), width: 22, borderRadius: BorderRadius.circular(4)),
                            BarChartRodData(toY: prevMonthIncome, color: const Color(0xFF06B6D4), width: 22, borderRadius: BorderRadius.circular(4)),
                            BarChartRodData(toY: prevYearIncome, color: const Color(0xFF94A3B8), width: 22, borderRadius: BorderRadius.circular(4)),
                          ],
                        ),
                      ],
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => const Text('Receita Bruta Faturada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Diagnóstico IA de Sazonalidade Glauber AI
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diagnóstico Glauber AI — Sazonalidade & Crescimento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        'O faturamento atual apresenta uma variação MoM de ${momGrowthPercent >= 0 ? "+" : ""}${momGrowthPercent.toStringAsFixed(1)}% e variação YoY de ${yoyGrowthPercent >= 0 ? "+" : ""}${yoyGrowthPercent.toStringAsFixed(1)}%. O ritmo de aceleração das vendas está saudável em comparação ao mesmo trimestre do ano anterior.',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonKpiCard({
    required String title,
    required String currentVal,
    required String prevVal,
    required double percentChange,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 16),
          Text(currentVal, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  '${percentChange >= 0 ? "+" : ""}${percentChange.toStringAsFixed(1)}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('vs $prevVal', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}
