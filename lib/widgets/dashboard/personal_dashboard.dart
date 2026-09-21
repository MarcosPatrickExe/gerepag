import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';
import '../daily_spending_radar.dart';
import '../challenges_section.dart';
import '../financial_health_bar.dart';
import '../spending_donut_chart.dart';
import '../spending_limits_card.dart';
import '../credit_card_summaries.dart';
import '../../../screens/home_screen.dart';
import '../budget_dashboard_view.dart';
import '../../../screens/my_subscriptions_screen.dart';
import '../installments_projection_view.dart';
import '../../../screens/credit_cards_screen.dart';
import '../../../screens/wallets_screen.dart';
import '../../../screens/whatsapp_cobranca_screen.dart';
import '../../../screens/freelancer_kanban_screen.dart';
import '../../../screens/saving_goals_screen.dart';
import '../../../screens/break_even_screen.dart';
import '../../../services/realtime_db_service.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../user_header.dart';

class PersonalDashboard extends StatelessWidget {
  final TransactionsProvider provider;
  final DashboardType currentDashboard;
  final Widget Function(TransactionsProvider) buildCoachBanner;
  final Widget Function(TransactionsProvider) buildRecurrenceSuggestions;
  final Widget Function(TransactionsProvider) buildBalanceCard;
  final Widget Function(TransactionsProvider) buildProactiveInsights;
  final Widget Function(TransactionsProvider) buildActivityFeed;

  const PersonalDashboard({
    super.key,
    required this.provider,
    required this.currentDashboard,
    required this.buildCoachBanner,
    required this.buildRecurrenceSuggestions,
    required this.buildBalanceCard,
    required this.buildProactiveInsights,
    required this.buildActivityFeed,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentDashboard) {
      case DashboardType.budget:
        return BudgetDashboardView();
      case DashboardType.subscriptions:
        return const MySubscriptionsScreen();
      case DashboardType.installments:
        return InstallmentsProjectionView();
      case DashboardType.creditCards:
        return const CreditCardsScreen();
      case DashboardType.wallets:
        return const WalletsScreen();
      case DashboardType.summary:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCoachBanner(provider),
            const SizedBox(height: 12),
            buildRecurrenceSuggestions(provider),
            const SizedBox(height: 24),
            _buildUserHeader(context, provider),
            const SizedBox(height: 16),
            StreamBuilder<Map<String, dynamic>?>(
              stream: RealtimeDbService().getClientPendingBpoFee(),
              builder: (context, feeSnap) {
                if (!feeSnap.hasData || feeSnap.data == null) return const SizedBox.shrink();
                final feeData = feeSnap.data!;
                final amount = double.tryParse(feeData['amount']?.toString() ?? '0') ?? 0.0;
                final dueDay = feeData['dueDay'] ?? 5;
                final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showPayBpoFeeBottomSheet(context, feeData),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Honorários Contábeis Pendentes 🏢',
                                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Vencimento dia $dueDay • Clique para pagar no app',
                                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                currency.format(amount),
                                style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Botão DRE Contábil
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showClientDreBottomSheet(context),
                icon: const Icon(Icons.analytics_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Ver Relatório DRE Contábil 📊',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            // Meta de Faturamento Contábil
            StreamBuilder<double>(
              stream: RealtimeDbService().getBpoClientRevenueGoal(),
              builder: (context, goalSnap) {
                final double goal = goalSnap.data ?? 0.0;
                if (goal <= 0) return const SizedBox.shrink();

                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                return StreamBuilder<List<TransactionModel>>(
                  stream: RealtimeDbService().getClientTransactions(uid),
                  builder: (context, txSnap) {
                    final txs = txSnap.data ?? [];
                    final now = DateTime.now();
                    
                    double totalFaturado = 0.0;
                    for (var t in txs) {
                      if (t.type == TransactionType.income && t.date.month == now.month && t.date.year == now.year) {
                        totalFaturado += t.amount;
                      }
                    }

                    final double pct = totalFaturado / goal;
                    final double progress = pct.clamp(0.0, 1.0);
                    final bool isGoalMet = totalFaturado >= goal;
                    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isGoalMet ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFF7C3AED).withValues(alpha: 0.2)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: 1.0,
                                  strokeWidth: 5,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 5,
                                  color: isGoalMet ? const Color(0xFF10B981) : const Color(0xFF7C3AED),
                                  strokeCap: StrokeCap.round,
                                ),
                                Center(
                                  child: Text(
                                    '${(progress * 100).toInt()}%',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Meta de Faturamento Contábil 🎯',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isGoalMet
                                      ? 'Parabéns! Meta de faturamento batida! 🎉✨'
                                      : 'Faturado: ${currency.format(totalFaturado)} de ${currency.format(goal)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isGoalMet ? const Color(0xFF10B981) : Colors.white70,
                                    fontWeight: isGoalMet ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05);
                  },
                );
              },
            ),

            // Mural de Recados do Contador
            StreamBuilder<Map<String, dynamic>?>(
              stream: RealtimeDbService().getContadorMessageForClient(),
              builder: (context, snapshot) {
                final m = snapshot.data;
                if (m == null || m['message'] == null || m['message'].toString().isEmpty) {
                  return const SizedBox.shrink();
                }

                final messageText = m['message'] ?? '';
                final contadorName = m['contadorName'] ?? 'Contador';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)], // Teal Gradient
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parecer do $contadorName 💼',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              messageText,
                              style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          await RealtimeDbService().clearContadorMessage();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Entendido',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.05);
              },
            ),

            // Mural de Recados BPO
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: RealtimeDbService().getBpoMessagesForClient(),
              builder: (context, snapshot) {
                final msgs = snapshot.data ?? [];
                if (msgs.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: msgs.map((m) {
                    final msgId = m['id'] ?? '';
                    final messageText = m['message'] ?? '';
                    final bpoName = m['bpoName'] ?? 'Contador';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mensagem de $bpoName ✉️',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  messageText,
                                  style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              await RealtimeDbService().markBpoMessageAsRead(msgId);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Entendido',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05);
                  }).toList(),
                );
              },
            ),
            buildBalanceCard(provider),
            const SizedBox(height: 16),
            _buildRunwayCard(context),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WhatsAppCobrancaScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Color(0xFF25D366),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cobrança por WhatsApp 💬',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Gere lembretes de cobrança com IA e envie direto para seus clientes.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: RealtimeDbService().getLocalServices(),
              builder: (context, snapshot) {
                final services = snapshot.data ?? [];
                int activeCount = 0;
                double pendingBilling = 0.0;
                
                for (var s in services) {
                  final status = s['status'] ?? 'todo';
                  if (status != 'paid') {
                    activeCount++;
                    pendingBilling += double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0;
                  }
                }
                
                final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
                
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FreelancerKanbanScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.view_kanban_outlined,
                                  color: AppTheme.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Projetos & Kanban 📋',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      activeCount > 0
                                          ? '$activeCount projetos ativos • ${currency.format(pendingBilling)} pendente'
                                          : 'Gerencie suas entregas e pipeline de cobrança.',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavingGoalsScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.savings_rounded,
                              color: Colors.blueAccent,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Metas & Cofrinhos 🎯',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Crie metas de poupança e guarde dinheiro com facilidade.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BreakEvenScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amberAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.scale_rounded,
                              color: Colors.amberAccent,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ponto de Equilíbrio ⚖️',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Saiba quanto precisa faturar para cobrir custos e metas.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            DailySpendingRadar(),
            const SizedBox(height: 24),
            buildProactiveInsights(provider),
            const SizedBox(height: 24),
            ChallengesSection(),
            const SizedBox(height: 24),
            FinancialHealthBar(onTap: null).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            SpendingDonutChart().animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            SpendingLimitsCard(),
            const SizedBox(height: 16),
            CreditCardSummaries(),
            const SizedBox(height: 32),
            const Text(
              'Histórico Recente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            buildActivityFeed(provider),
          ],
        );
    }
  }

  Widget _buildUserHeader(BuildContext context, TransactionsProvider provider) {
    return UserHeader(
      userName: provider.userName,
      avatarLetter: provider.userName.isNotEmpty ? provider.userName[0].toUpperCase() : 'U',
    );
  }

  Widget _buildRunwayCard(BuildContext context) {
    final double balance = provider.totalBalance;
    final double totalExp = provider.monthExpense;
    if (totalExp <= 0) {
      return const SizedBox.shrink();
    }
    final double runwayMonths = balance / totalExp;
    final String runwayText = runwayMonths >= 12 ? '12+ meses' : '${runwayMonths.toStringAsFixed(1)} meses';

    Color healthColor = Colors.redAccent;
    if (runwayMonths >= 6) {
      healthColor = Colors.greenAccent;
    } else if (runwayMonths >= 3) {
      healthColor = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fôlego Financeiro (Runway) 🔮',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  runwayText,
                  style: TextStyle(color: healthColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            runwayMonths <= 0 
                ? 'Você está com saldo negativo ou sem despesas registradas.'
                : 'Seu saldo atual cobriria as despesas do período por $runwayText sem novas receitas.',
            style: const TextStyle(color: AppTheme.textBody, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _showPayBpoFeeBottomSheet(BuildContext context, Map<String, dynamic> feeData) {
    final double amount = double.tryParse(feeData['amount']?.toString() ?? '0') ?? 0.0;
    final int dueDay = int.tryParse(feeData['dueDay']?.toString() ?? '5') ?? 5;
    final String bpoUid = feeData['bpoUid']?.toString() ?? '';
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monetization_on_rounded, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fatura de Honorários BPO 🏢',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Controle de Faturamento Nativo',
                          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Card do Valor
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VALOR DA FATURA',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(amount),
                          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        'Vence dia $dueDay',
                        style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Área de Pagamento (Chave Pix)
              FutureBuilder<String>(
                future: RealtimeDbService().getBpoPixKey(bpoUid),
                builder: (context, pixSnap) {
                  if (pixSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF10B981))));
                  }
                  
                  final pixKey = pixSnap.data ?? '';
                  if (pixKey.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_rounded, color: Color(0xFFD97706)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'O contador ainda não cadastrou uma Chave Pix no perfil dele. Entre em contato para pagar.',
                              style: GoogleFonts.inter(color: const Color(0xFFB45309), fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAGUE COM PIX 📱',
                        style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  pixKey,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: pixKey));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('✅ Pix Copia e Cola copiado!'),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              },
                              icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                              label: const Text('COPIAR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), elevation: 0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Botão de Confirmação de Pagamento
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('⏳ Processando pagamento...'),
                    ));
                    
                    await RealtimeDbService().payBpoFee(bpoUid, amount, dueDay);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('✅ Pagamento registrado com sucesso! Lançamentos salvos no fluxo de caixa.'),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                  label: const Text('MARCAR COMO PAGO NO APP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientDreBottomSheet(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: StreamBuilder<List<TransactionModel>>(
            stream: RealtimeDbService().getClientTransactions(uid),
            builder: (context, txSnap) {
              if (txSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
              }
              final transactions = txSnap.data ?? [];
              
              // 1. Cálculos de DRE Contábil
              final currentMonthTxs = transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
              
              double totalReceitas = 0.0;
              double totalDespesas = 0.0;
              double impostosTaxas = 0.0;
              double custosOperacionais = 0.0;

              for (var t in currentMonthTxs) {
                if (t.type == TransactionType.income) {
                  totalReceitas += t.amount;
                } else {
                  totalDespesas += t.amount;
                  if (t.category.toLowerCase().contains('imposto') || t.category.toLowerCase().contains('taxa') || t.category.toLowerCase().contains('guia')) {
                    impostosTaxas += t.amount;
                  } else {
                    custosOperacionais += t.amount;
                  }
                }
              }

              final double ebitda = totalReceitas - totalDespesas;
              final double margemLucro = totalReceitas > 0 ? (ebitda / totalReceitas) * 100 : 0.0;

              // 2. Gráfico de Evolução (5 Meses)
              final List<DateTime> lastMonths = List.generate(5, (i) => DateTime(now.year, now.month - (4 - i), 1));
              final Map<String, double> incomeByMonth = {};
              final Map<String, double> expenseByMonth = {};
              
              for (var m in lastMonths) {
                final key = '${m.month.toString().padLeft(2, '0')}/${m.year}';
                incomeByMonth[key] = 0.0;
                expenseByMonth[key] = 0.0;
              }

              for (var t in transactions) {
                final key = '${t.date.month.toString().padLeft(2, '0')}/${t.date.year}';
                if (incomeByMonth.containsKey(key)) {
                  if (t.type == TransactionType.income) {
                    incomeByMonth[key] = (incomeByMonth[key] ?? 0.0) + t.amount;
                  } else {
                    expenseByMonth[key] = (expenseByMonth[key] ?? 0.0) + t.amount;
                  }
                }
              }

              final List<FlSpot> incomeSpots = [];
              final List<FlSpot> expenseSpots = [];
              double maxY = 1000.0;

              for (int i = 0; i < lastMonths.length; i++) {
                final key = '${lastMonths[i].month.toString().padLeft(2, '0')}/${lastMonths[i].year}';
                final inc = incomeByMonth[key] ?? 0.0;
                final exp = expenseByMonth[key] ?? 0.0;
                incomeSpots.add(FlSpot(i.toDouble(), inc));
                expenseSpots.add(FlSpot(i.toDouble(), exp));
                if (inc > maxY) maxY = inc;
                if (exp > maxY) maxY = exp;
              }
              maxY = maxY * 1.25;

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.analytics_rounded, color: Color(0xFF7C3AED), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Demonstrativo DRE Contábil 📊',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textBody),
                            ),
                            Text(
                              'Relatório consolidado de performance do negócio.',
                              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // DRE Tabela Glassmorphism
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('DRE Contábil', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textBody)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                'Competência: ${DateFormat('MMMM/yyyy', 'pt_BR').format(now)}',
                                style: GoogleFonts.inter(color: const Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _dreRow('Receita Bruta (Faturamento) 🟢', totalReceitas, currency, isPrimary: true),
                        const Divider(height: 16, thickness: 0.5),
                        _dreRow('(-) Impostos e Taxas Fiscais 🧾', impostosTaxas, currency),
                        const SizedBox(height: 8),
                        _dreRow('(-) Despesas Operacionais / Custos 🛠️', custosOperacionais, currency),
                        const Divider(height: 16, thickness: 0.5),
                        _dreRow('(=) Resultado Operacional (EBITDA) 💰', ebitda, currency, isBold: true, isEbitda: true),
                        const Divider(height: 20, thickness: 1, color: Color(0xFFE2E8F0)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Margem Operacional Líquida', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textBody)),
                            Text(
                              '${margemLucro.toStringAsFixed(1)}%',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: margemLucro >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Gráfico de Evolução
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Evolução de Fluxo de Caixa', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textBody)),
                        Text('Histórico acumulado de faturamento vs despesas', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 160,
                          child: LineChart(
                            LineChartData(
                              maxY: maxY,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(color: Colors.black.withValues(alpha: 0.04), strokeWidth: 1),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    getTitlesWidget: (val, meta) {
                                      final idx = val.toInt();
                                      if (idx >= 0 && idx < lastMonths.length) {
                                        final m = lastMonths[idx];
                                        return Text(
                                          '${m.month.toString().padLeft(2, '0')}/${m.year.toString().substring(2)}',
                                          style: TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.bold),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: incomeSpots,
                                  isCurved: true,
                                  color: const Color(0xFF10B981),
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(show: true, color: const Color(0xFF10B981).withValues(alpha: 0.05)),
                                ),
                                LineChartBarData(
                                  spots: expenseSpots,
                                  isCurved: true,
                                  color: const Color(0xFFEF4444),
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(show: true, color: const Color(0xFFEF4444).withValues(alpha: 0.05)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legendDot(const Color(0xFF10B981), 'Faturamento'),
                            const SizedBox(width: 20),
                            _legendDot(const Color(0xFFEF4444), 'Despesas'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _dreRow(String label, double val, NumberFormat currency, {bool isPrimary = false, bool isBold = false, bool isEbitda = false}) {
    Color valColor = AppTheme.textBody;
    if (isPrimary) {
      valColor = const Color(0xFF10B981);
    } else if (isEbitda) {
      valColor = val >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    } else if (val > 0) {
      valColor = const Color(0xFFEF4444);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isPrimary ? 12 : 11,
            fontWeight: (isPrimary || isBold) ? FontWeight.bold : FontWeight.normal,
            color: isPrimary ? AppTheme.textBody : AppTheme.textMuted,
          ),
        ),
        Text(
          currency.format(val),
          style: GoogleFonts.outfit(
            fontSize: isPrimary ? 13 : 11,
            fontWeight: (isPrimary || isBold) ? FontWeight.bold : FontWeight.normal,
            color: valColor,
          ),
        ),
      ],
    );
  }
}
