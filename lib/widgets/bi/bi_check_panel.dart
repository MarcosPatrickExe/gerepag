import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_bi_provider.dart';
import '../../providers/transactions_provider.dart';

class BiCheckPanel extends StatelessWidget {
  const BiCheckPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final biProvider = Provider.of<BusinessBiProvider>(context);
    final txProvider = Provider.of<TransactionsProvider>(context);
    final issues = biProvider.runDiagnosticCheck(txProvider);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety_outlined, color: Colors.blueAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Check Panel — Diagnóstico de Qualidade Omie',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: issues.isEmpty ? Colors.green.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  issues.isEmpty ? '100% Consistente' : '${issues.length} Alertas Encontrados',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: issues.isEmpty ? Colors.green : Colors.amber[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (issues.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
                    SizedBox(height: 8),
                    Text('Nenhum erro de preenchimento ou inconsistência no Omie.', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: issues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final issue = issues[index];
                Color badgeColor;
                switch (issue.severity) {
                  case 'High':
                    badgeColor = Colors.red;
                    break;
                  case 'Medium':
                    badgeColor = Colors.orange;
                    break;
                  default:
                    badgeColor = Colors.blue;
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: badgeColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              issue.description,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
