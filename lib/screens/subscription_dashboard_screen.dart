import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/subscription_provider.dart';
import 'upgrade_screen.dart';

class SubscriptionDashboardScreen extends StatelessWidget {
  const SubscriptionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final days = subProvider.daysRemaining;
    final isPremium = subProvider.isPro;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Assinatura'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTierBadge(subProvider.tier),
            const SizedBox(height: 24),
            _buildCountdownCard(days, isPremium),
            const SizedBox(height: 32),
            const Text(
              'Benefícios Ativos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBody),
            ),
            const SizedBox(height: 16),
            _buildBenefitsList(subProvider.tier),
            const SizedBox(height: 48),
            _buildActionButtons(context, isPremium),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBadge(SubscriptionTier tier) {
    String label = 'Plano Gratuito';
    Color color = AppTheme.textMuted;
    
    if (tier == SubscriptionTier.pro) {
      label = 'PLANO PRO';
      color = AppTheme.primary;
    } else if (tier == SubscriptionTier.family) {
      label = 'PLANO BUSINESS';
      color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildCountdownCard(int days, bool isPremium) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.textBody.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            isPremium ? '$days' : '0',
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: AppTheme.textBody),
          ),
          Text(
            'dias de acesso premium restantes',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          if (isPremium) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (days / 365).clamp(0, 1),
                backgroundColor: Colors.white10,
                color: AppTheme.primary,
                minHeight: 8,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBenefitsList(SubscriptionTier tier) {
    bool isPro = tier != SubscriptionTier.free;
    bool isBusiness = tier == SubscriptionTier.family;

    return Column(
      children: [
        _buildBenefitItem('Scanner OCR Inteligente', isPro ? 'Ilimitado' : '3/mês', true),
        _buildBenefitItem('Consultoria IA Avançada', 'Habilitado', isPro),
        _buildBenefitItem('Relatórios Financeiros BI', 'Profissional', isPro),
        _buildBenefitItem('Gestão Multi-CNPJ', 'Business', isBusiness),
        _buildBenefitItem('Suporte Prioritário 24h', 'Habilitado', isBusiness),
      ],
    );
  }

  Widget _buildBenefitItem(String title, String status, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.lock,
            color: isActive ? AppTheme.primary : AppTheme.textMuted,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textMuted,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: isActive ? AppTheme.primary.withValues(alpha: 0.7) : AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isPremium) {
    return Column(
      children: [
        if (isPremium)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Link para ajuda/suporte
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Suporte prioritário ativado. Contatando equipe...')),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.textMuted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('AJUDA E SUPORTE', style: TextStyle(color: AppTheme.textBody)),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UpgradeScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPremium ? Colors.white.withValues(alpha: 0.05) : AppTheme.primary,
              foregroundColor: isPremium ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isPremium ? 'MUDAR MEU PLANO' : 'ATIVE O PREMIUM AGORA',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
