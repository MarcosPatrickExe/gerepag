import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../services/realtime_db_service.dart';

class ClientsManagerScreen extends StatefulWidget {
  const ClientsManagerScreen({super.key});

  @override
  State<ClientsManagerScreen> createState() => _ClientsManagerScreenState();
}

class _ClientsManagerScreenState extends State<ClientsManagerScreen> {
  final _realtimeService = RealtimeDbService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Meus Clientes 👥',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textBody),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBody),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _realtimeService.getLocalClients(),
        builder: (context, clientSnapshot) {
          if (clientSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final clients = clientSnapshot.data ?? [];

          if (clients.isEmpty) {
            return _buildEmptyState();
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _realtimeService.getLocalServices(),
            builder: (context, serviceSnapshot) {
              final services = serviceSnapshot.data ?? [];

              // Calcular faturamento por ID do cliente
              final Map<String, double> paidByClient = {};
              final Map<String, double> pendingByClient = {};

              for (var s in services) {
                final String cId = s['clientId'] ?? '';
                final double amount = double.tryParse(s['amount']?.toString() ?? '0') ?? 0.0;
                final String status = s['status'] ?? 'todo';

                if (cId.isNotEmpty) {
                  if (status == 'paid') {
                    paidByClient[cId] = (paidByClient[cId] ?? 0.0) + amount;
                  } else {
                    pendingByClient[cId] = (pendingByClient[cId] ?? 0.0) + amount;
                  }
                }
              }

              // Encontrar o ID do cliente VIP (maior faturamento pago)
              String vipClientId = '';
              double maxPaid = 0.0;
              paidByClient.forEach((cId, val) {
                if (val > maxPaid) {
                  maxPaid = val;
                  vipClientId = cId;
                }
              });

              return ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  final String id = client['id'] ?? '';
                  final double paid = paidByClient[id] ?? 0.0;
                  final double pending = pendingByClient[id] ?? 0.0;
                  final bool isVip = id == vipClientId && paid > 0.0;

                  return _buildClientTile(client, paid: paid, pending: pending, isVip: isVip);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showClientFormDialog(context),
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded, size: 64, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhum cliente cadastrado',
            style: TextStyle(color: AppTheme.textBody, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.0),
            child: Text(
              'Cadastre seus clientes recorrentes para autopreencher os dados na tela de cobrança por WhatsApp.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientTile(Map<String, dynamic> client, {required double paid, required double pending, required bool isVip}) {
    final String name = client['name'] ?? 'Sem Nome';
    final String phone = client['phone'] ?? '';
    final String email = client['email'] ?? '';
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVip ? Colors.amber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
          width: isVip ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: isVip ? Colors.amber.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'C',
            style: TextStyle(color: isVip ? Colors.amber : AppTheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isVip) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'VIP',
                      style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            if (phone.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.phone_iphone_rounded, size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(phone, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.mail_outline_rounded, size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(email, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PAGO', style: TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(currency.format(paid), style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EM ABERTO', style: TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(currency.format(pending), style: TextStyle(color: pending > 0 ? Colors.amberAccent : AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 20),
              onPressed: () => _showClientFormDialog(context, client: client),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.expense, size: 20),
              onPressed: () => _confirmDeleteClient(context, client),
            ),
          ],
        ),
      ),
    );
  }

  void _showClientFormDialog(BuildContext context, {Map<String, dynamic>? client}) {
    final nameController = TextEditingController(text: client?['name'] ?? '');
    final phoneController = TextEditingController(text: client?['phone'] ?? '');
    final emailController = TextEditingController(text: client?['email'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          client == null ? 'Novo Cliente 👤' : 'Editar Cliente 👤',
          style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textBody),
                decoration: const InputDecoration(
                  labelText: 'Nome do Cliente',
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                style: const TextStyle(color: AppTheme.textBody),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Celular / WhatsApp (DDD + Número)',
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                  hintText: 'Ex: 11999999999',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o celular';
                  final cleaned = v.replaceAll(RegExp(r'\D'), '');
                  if (cleaned.length < 10) return 'Insira um celular válido com DDD';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                style: const TextStyle(color: AppTheme.textBody),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail (Opcional)',
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final String id = client?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
              await _realtimeService.saveLocalClient(id, {
                'name': nameController.text.trim(),
                'phone': phoneController.text.replaceAll(RegExp(r'\D'), ''),
                'email': emailController.text.trim(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(client == null ? 'Cliente cadastrado com sucesso!' : 'Cliente atualizado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClient(BuildContext context, Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Excluir Cliente?'),
        content: Text('Tem certeza que deseja remover ${client['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NÃO', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              await _realtimeService.deleteLocalClient(client['id']);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente removido com sucesso.')),
                );
              }
            },
            child: const Text('SIM, EXCLUIR', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }
}
