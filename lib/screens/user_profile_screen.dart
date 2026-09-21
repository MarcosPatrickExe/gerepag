import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/user_stats_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/transactions_provider.dart';
import 'badges_screen.dart';
import 'settings_screen.dart';
import 'my_subscriptions_screen.dart';
import 'upgrade_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _picker = ImagePicker();

  Future<void> _pickProfileImage(TransactionsProvider provider) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 75,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        await provider.updateClientLogo(base64String);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil atualizada com sucesso! 📸'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  void _showEditNameDialog(BuildContext context, TransactionsProvider provider) {
    final nameController = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Editar Nome ✏️',
          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            labelText: 'Nome do Usuário',
            labelStyle: const TextStyle(color: Colors.black54),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black12),
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await provider.updateUserName(newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome atualizado com sucesso!'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SALVAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<UserStatsProvider>(context);
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final transProvider = Provider.of<TransactionsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Ultra clean Slate background
      body: Stack(
        children: [
          // Subtle constellation dot painter overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(),
            ),
          ),
          CustomScrollView(
            slivers: [
              _buildAppBar(context, statsProvider, transProvider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      if (transProvider.userNiche != 'bpo') ...[
                        _buildXpProgress(statsProvider),
                        const SizedBox(height: 24),
                        _buildStatsGrid(statsProvider),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Assinatura & Plano'),
                        const SizedBox(height: 16),
                        _buildSubscriptionCard(context, subProvider),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Minhas Conquistas'),
                        const SizedBox(height: 16),
                        _buildAchievementsPreview(context, statsProvider),
                        const SizedBox(height: 32),
                      ],
                      _buildSectionTitle('Configurações & Dados'),
                      const SizedBox(height: 16),
                      _buildActionList(context),
                      const SizedBox(height: 48),
                      _buildLogoutButton(context),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, UserStatsProvider stats, TransactionsProvider transProvider) {
    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2563EB),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2563EB),
                Color(0xFF1D4ED8),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              GestureDetector(
                onTap: () => _pickProfileImage(transProvider),
                child: Hero(
                  tag: 'user-avatar',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: const Color(0xFFF1F5F9),
                          backgroundImage: transProvider.clientLogo != null
                              ? MemoryImage(base64Decode(transProvider.clientLogo!))
                              : null,
                          child: transProvider.clientLogo == null
                              ? Text(
                                  transProvider.userName.isNotEmpty
                                      ? transProvider.userName[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.outfit(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2563EB),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF2563EB), size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    transProvider.userName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
                    onPressed: () => _showEditNameDialog(context, transProvider),
                  ),
                ],
              ),
              Text(
                transProvider.userNiche == 'bpo'
                    ? 'Membro desde ${FirebaseAuth.instance.currentUser?.metadata.creationTime != null ? DateFormat('MMMM yyyy', 'pt_BR').format(FirebaseAuth.instance.currentUser!.metadata.creationTime!) : 'Sempre'}'
                    : 'Nível ${stats.level} • Membro desde ${FirebaseAuth.instance.currentUser?.metadata.creationTime != null ? DateFormat('MMMM yyyy', 'pt_BR').format(FirebaseAuth.instance.currentUser!.metadata.creationTime!) : 'Sempre'}',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpProgress(UserStatsProvider stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                'Progresso do Nível',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF0F172A)),
              ),
              Text(
                '${stats.xp % 1000} / 1000 XP',
                style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: stats.progressToNextLevel,
              minHeight: 12,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ).animate().shimmer(duration: 2.seconds),
          const SizedBox(height: 12),
          Text(
            'Faltam ${stats.xpToNextLevel} XP para o Nível ${stats.level + 1}',
            style: GoogleFonts.inter(color: Colors.black45, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(UserStatsProvider stats) {
    return Row(
      children: [
        _buildStatCard(
          'Ofensiva',
          '${stats.streak} dias',
          Icons.local_fire_department_rounded,
          Colors.orangeAccent,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Total XP',
          '${stats.xp}',
          Icons.auto_awesome_rounded,
          Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionProvider provider) {
    final bool isPro = provider.isPro;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPro ? Colors.amber.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPro ? Colors.amber.withValues(alpha: 0.15) : const Color(0xFF2563EB).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPro ? Icons.workspace_premium_rounded : Icons.star_outline_rounded,
              color: isPro ? Colors.amber : const Color(0xFF2563EB),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPro ? 'Plano Pro Ativo' : 'Plano Gratuito',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPro ? 'Acesso ilimitado liberado' : 'Suba para o Pro e ganhe IA',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isPro ? const MySubscriptionsScreen() : const UpgradeScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPro ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFF2563EB),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isPro ? 'GERENCIAR' : 'UPGRADE',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: isPro ? Colors.amber : Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsPreview(BuildContext context, UserStatsProvider stats) {
    if (stats.badges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: Center(
          child: Text(
            'Nenhuma conquista liberada ainda. Continue usando o app! 🏆',
            style: GoogleFonts.inter(color: Colors.black45, fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      height: 105,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.badges.length > 5 ? 5 : stats.badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final badge = stats.badges[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BadgesScreen())),
            child: Container(
              width: 85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(badge.icon, size: 28, color: const Color(0xFF2563EB)),
                  const SizedBox(height: 8),
                  Text(
                    badge.title.split(' ').first,
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionList(BuildContext context) {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.settings_outlined,
          title: 'Configurações do App',
          subtitle: 'Preferências, notificações e segurança',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
        ),
        _buildActionTile(
          icon: Icons.shield_outlined,
          title: 'Privacidade & Dados',
          subtitle: 'Gerencie como usamos seus dados',
          onTap: () {},
        ),
        _buildActionTile(
          icon: Icons.help_outline_rounded,
          title: 'Central de Ajuda',
          subtitle: 'Dúvidas frequentes e suporte',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A))),
        subtitle: Text(subtitle, style: GoogleFonts.inter(color: Colors.black45, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 24),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
        label: Text(
          'SAIR DA CONTA',
          style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.015)
      ..strokeWidth = 1.0;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
