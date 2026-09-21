import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AdminUserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const AdminUserDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final uid = user['uid'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(user['name'] ?? 'Detalhes do Usuário', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(currency),
            const SizedBox(height: 32),
            const Text('CARTEIRAS / BANCOS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _buildDataList(context, 'wallets/$uid', (data) => _buildWalletCard(data, currency)),
            const SizedBox(height: 32),
            const Text('METAS E OBJETIVOS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _buildDataList(context, 'goals/$uid', (data) => _buildGoalCard(data, currency)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
            child: Text(user['name']?[0]?.toUpperCase() ?? 'U', style: const TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? 'Sem Nome', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user['email'] ?? 'Sem E-mail', style: const TextStyle(color: Colors.white38, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBadge(user['accountType']?.toUpperCase() ?? 'PESSOAL', Colors.blueAccent),
                    const SizedBox(width: 8),
                    _buildBadge(user['role'] == 'admin' ? 'ADMIN' : 'USER', Colors.orangeAccent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDataList(BuildContext context, String path, Widget Function(Map<String, dynamic>) itemBuilder) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref(path).onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Text('Nenhum dado encontrado.', style: TextStyle(color: Colors.white24));
        }

        final Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
        final List<Map<String, dynamic>> items = [];
        data.forEach((key, value) {
          if (value is Map) {
            items.add(Map<String, dynamic>.from(value));
          }
        });

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => itemBuilder(items[index]),
        );
      },
    );
  }

  Widget _buildWalletCard(Map<String, dynamic> wallet, NumberFormat currency) {
    final balance = double.tryParse(wallet['balance']?.toString() ?? '0') ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(wallet['name'] ?? 'Carteira', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          Text(currency.format(balance), style: TextStyle(color: balance >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, NumberFormat currency) {
    final current = double.tryParse(goal['currentAmount']?.toString() ?? '0') ?? 0;
    final target = double.tryParse(goal['targetAmount']?.toString() ?? '0') ?? 0;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal['name'] ?? 'Meta', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text('${currency.format(current)} de ${currency.format(target)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
