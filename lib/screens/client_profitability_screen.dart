import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transactions_provider.dart';
import '../models/transaction_model.dart';
import '../core/app_theme.dart';

class ClientProfitabilityScreen extends StatefulWidget {
  const ClientProfitabilityScreen({super.key});

  @override
  State<ClientProfitabilityScreen> createState() =>
      _ClientProfitabilityScreenState();
}

class _ClientProfitabilityScreenState extends State<ClientProfitabilityScreen> {
  String _searchQuery = '';
  String _selectedPeriod = 'Este Mês';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionsProvider>(context);
    final transactions = provider.transactions;

    // Agrupar receitas e custos por título/cliente ou categoria
    final Map<String, _ClientFinancials> clientMap = {};

    for (final t in transactions) {
      final clientName = t.title.trim().isNotEmpty
          ? t.title.trim()
          : 'Não Identificado';

      clientMap.putIfAbsent(
        clientName,
        () => _ClientFinancials(name: clientName),
      );

      if (t.type == TransactionType.income) {
        clientMap[clientName]!.revenue += t.amount;
      } else {
        clientMap[clientName]!.expenses += t.amount;
      }
    }

    final List<_ClientFinancials> clientList = clientMap.values.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Ordenar por maior Lucro/Margem
    clientList.sort((a, b) => b.profit.compareTo(a.profit));

    final totalRevenue = clientList.fold(0.0, (sum, c) => sum + c.revenue);
    final totalExpenses = clientList.fold(0.0, (sum, c) => sum + c.expenses);
    final totalProfit = totalRevenue - totalExpenses;
    final marginPercent = totalRevenue > 0
        ? (totalProfit / totalRevenue) * 100
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Rentabilidade por Cliente & Projeto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de Métricas Globais
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricTile(
                        'Receita Total',
                        'R\$ ${totalRevenue.toStringAsFixed(2)}',
                        Colors.greenAccent,
                      ),
                      _buildMetricTile(
                        'Custo Operacional',
                        'R\$ ${totalExpenses.toStringAsFixed(2)}',
                        Colors.redAccent,
                      ),
                      _buildMetricTile(
                        'Margem Global',
                        '${marginPercent.toStringAsFixed(1)}%',
                        Colors.cyanAccent,
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lucro Geral da Operação:',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      Text(
                        'R\$ ${totalProfit.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: totalProfit >= 0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Barra de Pesquisa e Filtros
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar cliente ou projeto...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Ranking de Margem de Contribuição',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Lista de Clientes
            if (clientList.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Nenhum cliente ou projeto encontrado.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clientList.length,
                itemBuilder: (context, index) {
                  final client = clientList[index];
                  final isProfitable = client.profit >= 0;
                  final margin = client.marginPercent;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isProfitable
                            ? Colors.greenAccent.withOpacity(0.2)
                            : Colors.redAccent.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isProfitable
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                  radius: 16,
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  client.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isProfitable ? Colors.green : Colors.red)
                                        .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${margin.toStringAsFixed(1)}% Margem',
                                style: TextStyle(
                                  color: isProfitable
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Receita: R\$ ${client.revenue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Custo: R\$ ${client.expenses.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Lucro: R\$ ${client.profit.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isProfitable
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: client.revenue > 0
                                ? (client.profit.clamp(0, client.revenue) /
                                      client.revenue)
                                : 0,
                            backgroundColor: Colors.redAccent.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isProfitable
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ClientFinancials {
  final String name;
  double revenue = 0.0;
  double expenses = 0.0;

  _ClientFinancials({required this.name});

  double get profit => revenue - expenses;
  double get marginPercent => revenue > 0 ? (profit / revenue) * 100 : 0.0;
}
