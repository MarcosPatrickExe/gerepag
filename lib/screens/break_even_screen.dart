import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../services/realtime_db_service.dart';

class BreakEvenScreen extends StatefulWidget {
  const BreakEvenScreen({super.key});

  @override
  State<BreakEvenScreen> createState() => _BreakEvenScreenState();
}

class _BreakEvenScreenState extends State<BreakEvenScreen> {
  final _realtimeService = RealtimeDbService();
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  double _extraSavingsBuffer = 0.0; // Buffer extra desejado pelo usuário (slider)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Simulador Ponto de Equilíbrio ⚖️',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBody),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _realtimeService.getSubscriptions(),
        builder: (context, subSnapshot) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _realtimeService.getSavingGoals(),
            builder: (context, goalSnapshot) {
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _realtimeService.getLocalServices(),
                builder: (context, servicesSnapshot) {
                  if (subSnapshot.connectionState == ConnectionState.waiting ||
                      goalSnapshot.connectionState == ConnectionState.waiting ||
                      servicesSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                  }

                  final subs = subSnapshot.data ?? [];
                  final goals = goalSnapshot.data ?? [];
                  final services = servicesSnapshot.data ?? [];

                  // 1. Somar custos fixos das assinaturas recorrentes
                  double fixedCosts = 0.0;
                  for (var s in subs) {
                    fixedCosts += double.tryParse(s['price']?.toString() ?? '0') ?? 0.0;
                  }

                  // 2. Somar o alvo restante das metas de poupança
                  double goalsTarget = 0.0;
                  for (var g in goals) {
                    final double target = double.tryParse(g['targetAmount']?.toString() ?? '0') ?? 0.0;
                    final double current = double.tryParse(g['currentAmount']?.toString() ?? '0') ?? 0.0;
                    if (target > current) {
                      goalsTarget += (target - current);
                    }
                  }

                  // Limitar meta de poupança mensal sugerida (ex: 20% do alvo total das metas)
                  double monthlyGoalsSaving = goalsTarget * 0.1; // Planejado poupar 10% do total restante por mês

                  // 3. Calcular ticket médio dos projetos no Kanban
                  double totalProjectValue = 0.0;
                  int projectCount = 0;
                  for (var item in services) {
                    final double amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                    if (amt > 0) {
                      totalProjectValue += amt;
                      projectCount++;
                    }
                  }
                  double avgProjectValue = projectCount > 0 ? (totalProjectValue / projectCount) : 1000.0;

                  // 4. Ponto de Equilíbrio Mínimo (Custos Fixos)
                  double breakEvenMin = fixedCosts;

                  // Ponto de Equilíbrio Desejado (Custos + Poupança + Buffer)
                  double breakEvenTarget = fixedCosts + monthlyGoalsSaving + _extraSavingsBuffer;

                  // Quantidade de projetos necessários
                  double projectsNeeded = avgProjectValue > 0 ? (breakEvenTarget / avgProjectValue) : 0.0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBreakEvenHeaderCard(breakEvenTarget, breakEvenMin),
                        const SizedBox(height: 24),
                        _buildDetailedBreakdown(fixedCosts, monthlyGoalsSaving),
                        const SizedBox(height: 24),
                        _buildInteractiveControls(),
                        const SizedBox(height: 24),
                        _buildActionPlanCard(avgProjectValue, projectsNeeded, breakEvenTarget),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBreakEvenHeaderCard(double target, double min) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'META DE FATURAMENTO MENSAL',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          Text(
            currency.format(target),
            style: const TextStyle(color: AppTheme.primary, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mínimo Sobrevivência (DAS/Custos):',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
              ),
              Text(
                currency.format(min),
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBreakdown(double fixedCosts, double monthlySaving) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Composição da Meta',
          style: TextStyle(color: AppTheme.textBody, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildBreakdownRow('Despesas Fixas / Assinaturas 🔁', fixedCosts, Colors.amberAccent),
        const SizedBox(height: 12),
        _buildBreakdownRow('Reserva sugerida para Metas 🎯', monthlySaving, Colors.blueAccent),
        const SizedBox(height: 12),
        _buildBreakdownRow('Buffer de Lucro Extra / Caixa 📈', _extraSavingsBuffer, Colors.greenAccent),
      ],
    );
  }

  Widget _buildBreakdownRow(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textBody, fontSize: 13)),
          Text(
            currency.format(value),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Simular Margem de Segurança (Lucro)',
            style: TextStyle(color: AppTheme.textBody, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Arraste para adicionar um colchão financeiro extra além das despesas e metas:',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Buffer Extra:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Text(
                currency.format(_extraSavingsBuffer),
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _extraSavingsBuffer,
            min: 0,
            max: 5000,
            divisions: 50,
            activeColor: AppTheme.primary,
            inactiveColor: Colors.white10,
            onChanged: (val) {
              setState(() {
                _extraSavingsBuffer = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionPlanCard(double avgProj, double needed, double target) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plano de Ação Sugerido 📈',
            style: TextStyle(color: AppTheme.primary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Valor Médio dos seus Contratos:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Text(currency.format(avgProj), style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fechar ${needed.ceil()} entregas',
                      style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trabalhando a uma média de ${currency.format(avgProj)} por contrato para bater a meta de ${currency.format(target)}.',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
