import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/transactions_provider.dart';

class OmieProjectWidget extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieProjectWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final projects = provider.omieProjectData;
    if (projects.isEmpty || (projects.length == 1 && projects.containsKey('Sem Projeto'))) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ALOCAÇÃO POR PROJETO 🏗️', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...projects.entries.where((e) => e.value > 0).take(4).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(NumberFormat.simpleCurrency(locale: 'pt_BR').format(e.value), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (e.value / projects.values.reduce((a, b) => a + b)).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: Colors.white,
                    minHeight: 2,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
