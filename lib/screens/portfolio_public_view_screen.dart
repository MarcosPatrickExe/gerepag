import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/realtime_db_service.dart';
import 'package:intl/intl.dart';

class PortfolioPublicViewScreen extends StatefulWidget {
  final String slug;
  
  const PortfolioPublicViewScreen({super.key, required this.slug});

  @override
  State<PortfolioPublicViewScreen> createState() => _PortfolioPublicViewScreenState();
}

class _PortfolioPublicViewScreenState extends State<PortfolioPublicViewScreen> {
  String _selectedFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final RealtimeDbService dbService = RealtimeDbService();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate Dark background
      body: FutureBuilder<Map<String, dynamic>?>(
        future: dbService.getPublicPortfolioBySlug(widget.slug),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildNotFoundState(context);
          }

          final data = snapshot.data!;
          final profile = Map<String, dynamic>.from(data['profile'] ?? {});
          final List<dynamic> rawProjects = data['projects'] ?? [];
          final List<Map<String, dynamic>> projects = rawProjects
              .map((p) => Map<String, dynamic>.from(p))
              .toList();

          // Calcular estatísticas do Freelancer
          final int totalProjects = projects.length;
          double totalFaturamento = 0.0;
          double sumRating = 0.0;
          for (var p in projects) {
            totalFaturamento += double.tryParse(p['value']?.toString() ?? '0') ?? 0.0;
            sumRating += double.tryParse(p['rating']?.toString() ?? '5') ?? 5.0;
          }
          final double avgRating = totalProjects > 0 ? sumRating / totalProjects : 5.0;

          final String title = profile['title'] ?? 'Freelancer de Elite';
          final String bio = profile['bio'] ?? 'Desenvolvedor profissional parceiro GerePague.';
          final String whatsapp = profile['whatsapp'] ?? '';

          // Obter tecnologias únicas para o filtro
          final Set<String> techFilters = {'Todos'};
          for (var p in projects) {
            final List<dynamic> techs = p['technologies'] ?? [];
            for (var t in techs) {
              techFilters.add(t.toString());
            }
          }

          // Filtrar projetos
          final List<Map<String, dynamic>> filteredProjects = projects.where((p) {
            if (_selectedFilter == 'Todos') return true;
            final List<dynamic> techs = p['technologies'] ?? [];
            return techs.map((t) => t.toString()).contains(_selectedFilter);
          }).toList();

          return CustomScrollView(
            slivers: [
              // 🔝 TOP PREMIUM BAR
              SliverAppBar(
                expandedHeight: 260.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1E293B),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.tealAccent),
                    tooltip: 'Compartilhar Portfólio',
                    onPressed: () {
                      final url = 'gerepague.com/portfolio/${widget.slug}';
                      Share.share('Confira meu portfólio de cases de sucesso faturados no GerePague: $url');
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Color(0xFF0F766E), Color(0xFF0F172A)],
                          ),
                        ),
                      ),
                      // Decorative circles
                      Positioned(
                        right: -30,
                        top: -30,
                        child: CircleAvatar(
                          radius: 120,
                          backgroundColor: Colors.tealAccent.withValues(alpha: 0.05),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.tealAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_user_rounded, color: Colors.tealAccent, size: 12),
                                    const SizedBox(width: 6),
                                    Text(
                                      'MEMBRO VERIFICADO GEREPAGUE',
                                      style: GoogleFonts.inter(
                                        color: Colors.tealAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < avgRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: Colors.amberAccent,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${avgRating.toStringAsFixed(1)}/5 (${totalProjects} projetos)',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 📝 BIO & ESTÁTICAS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SOBRE MIM',
                              style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              bio,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStatsRow(totalProjects, totalFaturamento, currency),
                      const SizedBox(height: 32),
                      
                      // Filtro de Tecnologias horizontal
                      if (techFilters.length > 2) ...[
                        const Text(
                          'FILTRAR POR TECNOLOGIA:',
                          style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: techFilters.map((tech) {
                              final isSelected = tech == _selectedFilter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(tech, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white70)),
                                  selected: isSelected,
                                  selectedColor: Colors.tealAccent,
                                  backgroundColor: const Color(0xFF1E293B),
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() => _selectedFilter = tech);
                                    }
                                  },
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  side: BorderSide(color: isSelected ? Colors.tealAccent : const Color(0xFF334155)),
                                  showCheckmark: false,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      Text(
                        'ÚLTIMOS PROJETOS CONCLUÍDOS 🎯',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // 📁 CASE LIST
              filteredProjects.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyProjects())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final p = filteredProjects[index];
                          final String pTitle = p['title'] ?? 'Case de Portfólio';
                          final String pDesc = p['description'] ?? '';
                          final String pResult = p['result'] ?? '';
                          final double pValue = double.tryParse(p['value']?.toString() ?? '0') ?? 0.0;
                          final double pRating = double.tryParse(p['rating']?.toString() ?? '5') ?? 5.0;
                          final List<dynamic> techs = p['technologies'] ?? [];

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          pTitle,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          currency.format(pValue),
                                          style: GoogleFonts.outfit(
                                            color: Colors.tealAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Row(
                                        children: List.generate(5, (index) {
                                          return Icon(
                                            index < pRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                                            color: Colors.amberAccent,
                                            size: 14,
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Cliente Satisfeito',
                                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  if (pDesc.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Text(
                                      pDesc,
                                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.5),
                                    ),
                                  ],
                                  if (pResult.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.insights_rounded, color: Color(0xFF34D399), size: 16),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('RESULTADOS OBTIDOS:', style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  pResult,
                                                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, height: 1.4),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (techs.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: techs.map((t) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF1E293B)),
                                          ),
                                          child: Text(
                                            t.toString(),
                                            style: const TextStyle(color: Colors.tealAccent, fontSize: 10),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: filteredProjects.length,
                      ),
                    ),

              // Bottom spacing for CTA
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              )
            ],
          );
        },
      ),
      // 💬 PERSISTENT CTA BUTTON (WHATSAPP)
      bottomSheet: Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: dbService.getPublicPortfolioBySlug(widget.slug),
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null) return const SizedBox.shrink();

            final profile = data['profile'] ?? {};
            final String whatsapp = profile['whatsapp'] ?? '';

            return SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: whatsapp.isEmpty
                    ? null
                    : () async {
                        final String url = "https://wa.me/$whatsapp?text=${Uri.encodeComponent('Olá, vi seu portfólio no GerePague e gostaria de solicitar um orçamento comercial!')}";
                        final Uri uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('⚠️ Não foi possível abrir o WhatsApp comercial.')),
                          );
                        }
                      },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('CHAMAR NO WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: const Color(0xFF0F172A),
                  disabledBackgroundColor: const Color(0xFF1E293B),
                  disabledForegroundColor: const Color(0xFF475569),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow(int projects, double faturamento, NumberFormat format) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem('PROJETOS ENTREGUES', projects.toString(), Colors.tealAccent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem('VOLUME NEGOCIADO', format.format(faturamento), const Color(0xFF34D399)),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProjects() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF475569)),
          const SizedBox(height: 12),
          Text(
            'Nenhum case publicado neste portfólio.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.orangeAccent, size: 50),
            const SizedBox(height: 16),
            Text(
              'Portfólio Não Encontrado',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'O subdomínio consultado não está registrado ou foi desativado pelo freelancer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('VOLTAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
