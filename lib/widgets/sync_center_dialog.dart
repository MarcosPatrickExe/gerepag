import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transactions_provider.dart';
import '../core/app_theme.dart';
import '../screens/admin_settings_screen.dart';
import '../screens/bank_sync_inbox_screen.dart';

class SyncCenterDialog extends StatelessWidget {
  const SyncCenterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final accounts = provider.omieAccounts;
    final syncTimes = provider.accountSyncTimes;
    final syncStatuses = provider.accountSyncStatuses;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: AppTheme.surface.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppTheme.textMuted),
        ),
        title: Row(
          children: [
            const Icon(Icons.sync_problem_rounded, color: Colors.blueAccent),
            const SizedBox(width: 12),
            const Text('Saúde da Conexão', style: TextStyle(color: AppTheme.textBody)),
            const Spacer(),
            if (provider.isRefreshingOmie)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
              ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Abaixo você confere o status de atualização de cada conta conectada à Omie.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ...accounts.map((acc) {
                final status = syncStatuses[acc.id] ?? 'Aguardando';
                final time = syncTimes[acc.id];
                final color = _getStatusColor(status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.1),
                        radius: 12,
                        child: Icon(Icons.circle, color: color, size: 8),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(acc.name, style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
                            Text(
                              time != null 
                                ? 'Última sincronização: ${DateFormat('HH:mm').format(time)}' 
                                : 'Aguardando primeira carga...',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.textMuted),
              const SizedBox(height: 8),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BankSyncInboxScreen()));
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.blueAccent, size: 20),
                ),
                title: const Text('Caixa de Entrada Bancária', style: TextStyle(color: AppTheme.textBody, fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Auditoria e conciliação de notificações', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSettingsScreen()));
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_alt, color: AppTheme.primary, size: 20),
                ),
                title: const Text('Configurar GereIA', style: TextStyle(color: AppTheme.textBody, fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Trocar entre Gemini e ChatGPT-4o-mini', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: provider.isRefreshingOmie ? null : () => provider.refreshOmieData(fullSync: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('FORÇAR REFRESH'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sucesso': return Colors.greenAccent;
      case 'Sincronizando': return Colors.blueAccent;
      case 'Erro': return Colors.redAccent;
      default: return Colors.white24;
    }
  }
}
