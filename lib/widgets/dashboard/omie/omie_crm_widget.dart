import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/transactions_provider.dart';
import '../../../core/app_theme.dart';
import '../../ai_negotiation_card.dart';

class OmieCRMWidget extends StatelessWidget {
  final TransactionsProvider provider;

  const OmieCRMWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.2), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CRM E HISTÓRICO DE CLIENTES 👥', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          const Text('Pesquise e centralize toda a jornada financeira e de serviços dos seus clientes.', style: TextStyle(color: AppTheme.textBody, fontSize: 13, height: 1.4)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showClientSearchSheet(context, provider),
              icon: const Icon(Icons.search, color: Colors.blueAccent),
              label: const Text('PESQUISAR CLIENTE', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showClientSearchSheet(BuildContext context, TransactionsProvider provider) {
    if (provider.omieClients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum cliente sincronizado.')));
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String searchQuery = '';
        List<MapEntry<String, String>> filteredClients = provider.omieClients.entries.toList();

        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: true,
              builder: (context, scrollController) {
                return Container(
                   padding: const EdgeInsets.all(24),
                   child: Column(
                     children: [
                       Row(
                         children: [
                           const Expanded(child: Text('Pesquisar Clientes', style: TextStyle(color: AppTheme.textBody, fontSize: 18, fontWeight: FontWeight.bold))),
                           IconButton(icon: const Icon(Icons.close, color: AppTheme.textMuted), onPressed: () => Navigator.pop(context)),
                         ]
                       ),
                       const SizedBox(height: 16),
                       TextField(
                         style: const TextStyle(color: AppTheme.textBody),
                         decoration: InputDecoration(
                           hintText: 'Nome do Cliente ou Código...',
                           hintStyle: const TextStyle(color: AppTheme.textMuted),
                           filled: true,
                           fillColor: Colors.white.withValues(alpha: 0.05),
                           prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                         ),
                         onChanged: (val) {
                           setState(() {
                             searchQuery = val.toLowerCase();
                             filteredClients = provider.omieClients.entries.where((e) {
                               return e.value.toLowerCase().contains(searchQuery) || e.key.toLowerCase().contains(searchQuery);
                             }).toList();
                           });
                         },
                       ),
                       const SizedBox(height: 16),
                       Expanded(
                         child: ListView.builder(
                           controller: scrollController,
                           itemCount: filteredClients.length,
                           itemBuilder: (context, index) {
                             final client = filteredClients[index];
                             final bool isChurnRisk = provider.getChurnAlerts().contains(client.key);
                             return ListTile(
                               leading: CircleAvatar(
                                 backgroundColor: isChurnRisk ? Colors.redAccent.withValues(alpha: 0.1) : Colors.blueAccent.withValues(alpha: 0.1),
                                 child: Icon(
                                   isChurnRisk ? Icons.warning_rounded : Icons.person,
                                   color: isChurnRisk ? Colors.redAccent : Colors.blueAccent,
                                   size: 20
                                 ),
                               ),
                               title: Row(
                                 children: [
                                   Expanded(child: Text(client.value, style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 14))),
                                   if (isChurnRisk)
                                     Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                       decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                                       child: const Text('RISCO CHURN', style: TextStyle(color: AppTheme.textBody, fontSize: 8, fontWeight: FontWeight.bold)),
                                     ),
                                 ],
                               ),
                               subtitle: Text('Cód: ${client.key}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                               onTap: () {
                                 Navigator.pop(context);
                                 _showClientHistorySheet(context, client.key, client.value, provider);
                               },
                             );
                           },
                         ),
                       ),
                     ],
                   )
                );
              }
            );
          }
        );
      }
    );
  }

  void _showClientHistorySheet(BuildContext context, String clientId, String clientName, TransactionsProvider provider) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    final clientOS = provider.omieOS.where((os) {
      final cab = os['Cabecalho'] ?? os['cabecalho'] ?? {};
      return cab['nCodCli']?.toString() == clientId;
    }).toList();
    
    final clientOrders = provider.omieOrders.where((p) {
      final cab = p['Cabecalho'] ?? p['cabecalho'] ?? {};
      return (cab['nCodCli'] ?? cab['codigo_cliente'])?.toString() == clientId;
    }).toList();
    
    final clientReceivables = provider.omieAccountsReceivable.where((r) {
      return (r['codigo_cliente_omie'] ?? r['codigo_cliente_fornecedor'])?.toString() == clientId;
    }).toList();
    
    double totalAberto = 0;
    double totalPago = 0;
    
    for(var raw in clientReceivables) {
      final val = double.tryParse(raw['vlr_liquido']?.toString() ?? '0') ?? double.tryParse(raw['valor_documento']?.toString() ?? '0') ?? 0;
      final status = raw['status_titulo']?.toString();
      if (status == 'PAGO') totalPago += val;
      else totalAberto += val;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: true,
          builder: (context, scrollController) {
            return DefaultTabController(
              length: 4,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 28, backgroundColor: Colors.white10, child: Text(clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C', style: const TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(clientName, style: const TextStyle(color: AppTheme.textBody, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2),
                              const SizedBox(height: 4),
                              Text('Cód: $clientId', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close, color: AppTheme.textMuted), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildBusinessMetric('A RECEBER', currency.format(totalAberto), Colors.orangeAccent)),
                        Container(width: 1, height: 40, color: AppTheme.textMuted),
                        Expanded(child: _buildBusinessMetric('TOTAL PAGO', currency.format(totalPago), Colors.greenAccent)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const TabBar(
                      indicatorColor: Colors.blueAccent,
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: Colors.white54,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: 'Timeline', icon: Icon(Icons.history)),
                        Tab(text: 'Financeiro', icon: Icon(Icons.attach_money)),
                        Tab(text: 'Ordens (OS)', icon: Icon(Icons.build)),
                        Tab(text: 'Pedidos', icon: Icon(Icons.shopping_cart)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          (() {
                            final clientHistory = provider.billingHistory.where((h) => h['clientId'] == clientId).toList();
                            if (clientHistory.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Nenhuma cobrança registrada na timeline.',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                ),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              controller: scrollController,
                              itemCount: clientHistory.length,
                              itemBuilder: (ctx, idx) {
                                final record = clientHistory[idx];
                                final sentAt = record['sentAt'] != null 
                                    ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(record['sentAt'])) 
                                    : 'Data desconhecida';
                                final val = record['amount'] ?? 0.0;
                                
                                return Card(
                                  color: Colors.white.withValues(alpha: 0.02),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.green,
                                      child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                                    ),
                                    title: Text(
                                      'Cobrança via WhatsApp - R\$ ${val.toStringAsFixed(2)}',
                                      style: const TextStyle(color: AppTheme.textBody, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Enviado em: $sentAt\nRef: ${record['description'] ?? 'Serviço'}',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                      ),
                                    ),
                                    trailing: TextButton.icon(
                                      onPressed: () async {
                                        final url = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(record['whatsappText'] ?? '')}';
                                        final uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      icon: const Icon(Icons.sync, size: 14, color: Colors.greenAccent),
                                      label: const Text('Reenviar', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                );
                              },
                            );
                          })(),
                          clientReceivables.isEmpty 
                            ? const Center(child: Text('Sem histórico financeiro', style: TextStyle(color: AppTheme.textMuted)))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: clientReceivables.length,
                                itemBuilder: (ctx, i) {
                                  final item = clientReceivables[i];
                                  final val = double.tryParse(item['valor_documento']?.toString() ?? '0') ?? 0;
                                  final status = item['status_titulo']?.toString() ?? 'DESCONHECIDO';
                                  final due = item['data_vencimento']?.toString() ?? '--/--/----';
                                  
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(status == 'PAGO' ? Icons.check_circle : Icons.schedule, color: status == 'PAGO' ? Colors.greenAccent : Colors.orangeAccent),
                                    title: Text('Vencimento: $due', style: const TextStyle(color: AppTheme.textBody, fontSize: 13)),
                                    subtitle: Text('Status: $status', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                    trailing: Text(currency.format(val), style: const TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold, fontSize: 14)),
                                    onTap: status == 'PAGO' ? null : () {
                                      AiNegotiationCard.show(
                                        context,
                                        contactName: clientName.split('|').first,
                                        amount: val,
                                        dueDate: due,
                                        description: item['descricao'] ?? item['cDesCategor'] ?? 'Prestação de Serviços',
                                        type: 'receber',
                                      );
                                    },
                                  );
                                },
                              ),
                          const Center(child: Text('Ordens de Serviço', style: TextStyle(color: AppTheme.textMuted))),
                          const Center(child: Text('Pedidos de Venda', style: TextStyle(color: AppTheme.textMuted))),
                        ]
                      )
                    )
                  ]
                )
              )
            );
          }
        );
      }
    );
  }

  Widget _buildBusinessMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
