import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_user_details_screen.dart';
import '../providers/global_settings_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AdminProvider>(context, listen: false).fetchAllUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('CENTRAL DE COMANDO 👑', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
        actions: [
          _buildActionButton(Icons.settings_outlined, () => _showGlobalSettings(context)),
          const SizedBox(width: 8),
          _buildActionButton(Icons.refresh, () => adminProvider.fetchAllUsers()),
          const SizedBox(width: 16),
        ],
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(adminProvider, currency),
                  const SizedBox(height: 32),
                  _buildGrowthChart(adminProvider),
                  const SizedBox(height: 32),
                  _buildSearchBar(adminProvider),
                  const SizedBox(height: 16),
                  _buildFilterBar(adminProvider),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GESTÃO DE USUÁRIOS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Text('${adminProvider.users.length} encontrados', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildUserList(adminProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.blueAccent, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildGrowthChart(AdminProvider provider) {
    final data = provider.userGrowthData;
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CRESCIMENTO DE USUÁRIOS (7D)', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AdminProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Todos', 'all', provider),
          const SizedBox(width: 8),
          _buildFilterChip('Empresarial', 'empresarial', provider),
          const SizedBox(width: 8),
          _buildFilterChip('Família', 'familia', provider),
          const SizedBox(width: 8),
          _buildFilterChip('Pessoal', 'pessoal', provider),
          const SizedBox(width: 8),
          _buildSortButton(provider),
          const SizedBox(width: 8),
          _buildInactiveToggle(provider),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, AdminProvider provider) {
    final isSelected = provider.filterType == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => provider.setFilter(value),
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }

  Widget _buildSortButton(AdminProvider provider) {
    return PopupMenuButton<String>(
      initialValue: provider.sortType,
      onSelected: provider.setSort,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.sort, color: Colors.white54, size: 16),
            SizedBox(width: 8),
            Text('Ordenar', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'date', child: Text('Mais Novos')),
        const PopupMenuItem(value: 'balance', child: Text('Maior Saldo')),
        const PopupMenuItem(value: 'name', child: Text('Nome (A-Z)')),
      ],
    );
  }

  Widget _buildInactiveToggle(AdminProvider provider) {
    return FilterChip(
      label: const Text('Inativos', style: TextStyle(fontSize: 12, color: Colors.white54)),
      selected: provider.showInactiveOnly,
      onSelected: (_) => provider.toggleInactiveFilter(),
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: Colors.redAccent.withValues(alpha: 0.2),
      checkmarkColor: Colors.redAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildSearchBar(AdminProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (value) => provider.setSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Buscar por nome ou e-mail...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white38),
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                  setState(() {});
                },
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AdminProvider provider, NumberFormat currency) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('TOTAL USUÁRIOS', provider.users.length.toString(), Colors.blueAccent, Icons.people_outline, [Colors.blueAccent.withValues(alpha: 0.2), Colors.transparent]),
        _buildStatCard('MRR ESTIMADO', currency.format(provider.totalMRR), Colors.greenAccent, Icons.payments_outlined, [Colors.greenAccent.withValues(alpha: 0.2), Colors.transparent]),
        _buildStatCard('PREMIUM (BI)', provider.users.where((u) => u['accountType'] == 'empresarial').length.toString(), Colors.purpleAccent, Icons.business_center_outlined, [Colors.purpleAccent.withValues(alpha: 0.2), Colors.transparent]),
        _buildStatCard('TAXA CHURN', '2.4%', Colors.orangeAccent, Icons.trending_down, [Colors.orangeAccent.withValues(alpha: 0.2), Colors.transparent]),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildUserList(AdminProvider provider) {
    if (provider.users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(Icons.person_search, size: 60, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              const Text('Nenhum usuário encontrado', style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = provider.users[index];
        final type = (user['accountType'] ?? 'pessoal').toString();
        final role = (user['role'] ?? 'user').toString();
        final name = (user['name'] ?? 'Usuário').toString();
        
        return InkWell(
          onTap: () => _viewUserDetails(user),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_getTypeColor(type).withValues(alpha: 0.2), _getTypeColor(type).withValues(alpha: 0.05)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: _getTypeColor(type).withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U', 
                      style: TextStyle(color: _getTypeColor(type), fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(user['email'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _getTypeColor(type).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(color: _getTypeColor(type), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (role == 'admin') const Icon(Icons.verified, color: Colors.orangeAccent, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          role == 'admin' ? 'SUPER ADMIN' : 'USUÁRIO', 
                          style: TextStyle(color: role == 'admin' ? Colors.orangeAccent : Colors.white24, fontSize: 10, fontWeight: FontWeight.w600)
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: const Color(0xFF1E293B),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(provider, user);
                    } else if (value == 'view') {
                      _viewUserDetails(user);
                    } else {
                      provider.changeUserRole(user['uid'], value);
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, color: Colors.white54, size: 20),
                          SizedBox(width: 12),
                          Text('Ver Detalhes', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    const PopupMenuItem(
                      value: 'admin',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.orangeAccent, size: 20),
                          SizedBox(width: 12),
                          Text('Tornar Admin', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'user',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.blueAccent, size: 20),
                          SizedBox(width: 12),
                          Text('Tornar Usuário', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                          SizedBox(width: 12),
                          Text('Deletar Usuário', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewUserDetails(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminUserDetailsScreen(user: user)),
    );
  }

  void _showGlobalSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => const _GlobalSettingsSheet(),
    );
  }

  void _confirmDelete(AdminProvider provider, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('DELETAR USUÁRIO?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Esta ação é irreversível. Todos os dados de ${user['name']} serão removidos permanentemente.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final uid = user['uid'];
              final name = user['name'];
              Navigator.pop(dialogContext);
              await provider.deleteUser(uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Usuário $name removido.')),
              );
            },
            child: const Text('DELETAR AGORA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'empresarial': return Colors.purpleAccent;
      case 'familia': return Colors.blueAccent;
      default: return Colors.greenAccent;
    }
  }
}

class _GlobalSettingsSheet extends StatelessWidget {
  const _GlobalSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<GlobalSettingsProvider>(context);
    final settings = settingsProvider.settings;

    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONFIGURAÇÕES GLOBAIS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildToggle(
            'Modo Manutenção',
            'Bloqueia o acesso de todos os usuários.',
            settings['maintenanceMode'] ?? false,
            (val) => settingsProvider.updateSetting('maintenanceMode', val),
          ),
          const SizedBox(height: 24),
          _buildPriceField(
            context,
            'Preço Empresarial',
            settings['premiumPrice']?.toString() ?? '199.90',
            (val) => settingsProvider.updateSetting('premiumPrice', double.tryParse(val) ?? 199.90),
          ),
          const SizedBox(height: 16),
          _buildPriceField(
            context,
            'Preço Família',
            settings['familyPrice']?.toString() ?? '49.90',
            (val) => settingsProvider.updateSetting('familyPrice', double.tryParse(val) ?? 49.90),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('SALVAR E FECHAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildPriceField(BuildContext context, String label, String initialValue, Function(String) onSubmitted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            prefixText: 'R\$ ',
            prefixStyle: const TextStyle(color: Colors.blueAccent),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onSubmitted: onSubmitted,
          controller: TextEditingController(text: initialValue),
        ),
      ],
    );
  }
}
