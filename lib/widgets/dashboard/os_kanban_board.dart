import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/transactions_provider.dart';

class OSKanbanBoard extends StatefulWidget {
  final TransactionsProvider provider;

  const OSKanbanBoard({
    super.key,
    required this.provider,
  });

  @override
  State<OSKanbanBoard> createState() => _OSKanbanBoardState();
}

class _OSKanbanBoardState extends State<OSKanbanBoard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedColumnIndex = 0;

  @override
  void initState() {
    super.initState();
    final stages = widget.provider.omieOSByStage;
    _tabController = TabController(length: stages.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedColumnIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stages = widget.provider.omieOSByStage;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final mediaQuery = MediaQuery.of(context);
    final bool isMobile = mediaQuery.size.width < 750;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PIPELINE DE ORDENS DE SERVIÇO (KANBAN) ⚙️',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            if (isMobile)
              const Text(
                'Arraste para o lado ↔️',
                style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 520,
          child: isMobile 
              ? Column(
                  children: [
                    // Seletor de abas modernas deslizáveis
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicator: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.textMuted,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
                        tabs: stages.keys.toList().asMap().entries.map((e) {
                          final idx = e.key;
                          final stage = e.value;
                          final count = stages[stage]?.length ?? 0;
                          final bool isTabSelected = idx == _selectedColumnIndex;

                          return Tab(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(stage.toUpperCase()),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isTabSelected 
                                          ? Colors.white.withValues(alpha: 0.2) 
                                          : Colors.blueAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: isTabSelected ? Colors.white : Colors.blueAccent, 
                                        fontSize: 9, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Conteúdo das colunas deslizáveis (Abas)
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: stages.entries.toList().asMap().entries.map((e) {
                          final idx = e.key;
                          final entry = e.value;
                          final bool isColSelected = idx == _selectedColumnIndex;
                          return _buildColumnView(
                            context, 
                            entry.key, 
                            entry.value, 
                            currency, 
                            isMobile: true, 
                            isSelected: isColSelected
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: stages.entries.toList().asMap().entries.map((e) {
                      final idx = e.key;
                      final entry = e.value;
                      final bool isColSelected = idx == _selectedColumnIndex;

                      // DragTarget para cada coluna
                      return DragTarget<Map<String, dynamic>>(
                        onWillAcceptWithDetails: (details) => true,
                        onAcceptWithDetails: (details) {
                          final os = details.data;
                          final cab = os['Cabecalho'] ?? os['cabecalho'] ?? {};
                          final osId = cab['cNumOS']?.toString();
                          if (osId != null) {
                            String newEtapa = '00';
                            if (entry.key == 'Backlog') newEtapa = '00';
                            else if (entry.key == 'Em Produção') newEtapa = '10';
                            else if (entry.key == 'Revisão') newEtapa = '20';
                            else if (entry.key == 'Concluído') newEtapa = '50';
                            
                            widget.provider.updateOSStage(osId, newEtapa);
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          final bool isOver = candidateData.isNotEmpty;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColumnIndex = idx;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 280,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: isOver 
                                    ? Colors.blueAccent.withValues(alpha: 0.05) 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isOver 
                                      ? Colors.blueAccent 
                                      : (isColSelected ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.transparent),
                                  width: isOver || isColSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: _buildColumnView(
                                context, 
                                entry.key, 
                                entry.value, 
                                currency, 
                                isMobile: false, 
                                isSelected: isColSelected
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildColumnView(
    BuildContext context, 
    String stageName, 
    List<dynamic> items, 
    NumberFormat currency,
    {required bool isMobile, required bool isSelected}
  ) {
    return Container(
      width: isMobile ? double.infinity : 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.blueAccent.withValues(alpha: 0.05) 
            : AppTheme.textBody.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.4) : AppTheme.textMuted.withValues(alpha: 0.3)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stageName.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.blueAccent : AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.blueAccent.withValues(alpha: 0.2) 
                        : Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blueAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Nenhuma OS nesta etapa',
                        style: TextStyle(
                          color: isSelected ? Colors.white.withValues(alpha: 0.5) : AppTheme.textMuted.withValues(alpha: 0.6), 
                          fontSize: 11
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final os = items[index];
                      final cab = os['Cabecalho'] ?? os['cabecalho'] ?? {};
                      final clientId = cab['nCodCli']?.toString();
                      final clientName = widget.provider.omieClients[clientId] ?? 'Cliente Indefinido';
                      final value = double.tryParse((cab['nValorTotal'] ?? cab['valor_total'] ?? 0).toString()) ?? 0.0;
                      final date = cab['dDtPrevisao'] ?? cab['data_previsao'] ?? '--/--/----';
                      final osId = cab['cNumOS']?.toString() ?? 'N/A';

                      // Se for mobile, desabilitamos o arrasto para evitar conflitos de rolagem horizontal
                      if (isMobile) {
                        return GestureDetector(
                          onTap: () => _showMoveMenu(context, osId, stageName),
                          child: _buildOSCard(cab, clientName, value, date, currency, isSelected),
                        );
                      }

                      // Se for desktop, habilitamos LongPressDraggable para drag-and-drop
                      return LongPressDraggable<Map<String, dynamic>>(
                        data: Map<String, dynamic>.from(os),
                        feedback: Material(
                          color: Colors.transparent,
                          child: Opacity(
                            opacity: 0.85,
                            child: SizedBox(
                              width: 256,
                              child: _buildOSCard(cab, clientName, value, date, currency, isSelected),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: _buildOSCard(cab, clientName, value, date, currency, isSelected),
                        ),
                        child: GestureDetector(
                          onTap: () => _showMoveMenu(context, osId, stageName),
                          child: _buildOSCard(cab, clientName, value, date, currency, isSelected),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOSCard(
    Map<dynamic, dynamic> cab, 
    String clientName, 
    double value, 
    String date, 
    NumberFormat currency,
    bool isSelected
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2563EB) : AppTheme.surface,
        gradient: isSelected 
            ? const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], 
                begin: Alignment.topLeft, 
                end: Alignment.bottomRight
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue.shade300.withValues(alpha: 0.3) : AppTheme.textBody.withValues(alpha: 0.05)
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
            blurRadius: isSelected ? 8 : 4,
            offset: isSelected ? const Offset(0, 4) : const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OS #${cab['cNumOS'] ?? 'N/A'}',
                style: TextStyle(
                  color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            clientName,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textBody,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currency.format(value),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textBody,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isSelected ? Colors.white70 : AppTheme.textMuted,
                size: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMoveMenu(BuildContext context, String osId, String currentStage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MOVER ORDEM DE SERVIÇO #$osId',
                    style: const TextStyle(
                      color: AppTheme.textBody,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escolha a nova etapa da ordem de serviço:',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  _buildMoveOption(ctx, osId, 'Backlog', '00', Icons.assignment_outlined, Colors.amberAccent, currentStage),
                  const SizedBox(height: 12),
                  _buildMoveOption(ctx, osId, 'Em Produção', '10', Icons.play_circle_outline, Colors.blueAccent, currentStage),
                  const SizedBox(height: 12),
                  _buildMoveOption(ctx, osId, 'Revisão', '20', Icons.find_in_page_outlined, Colors.purpleAccent, currentStage),
                  const SizedBox(height: 12),
                  _buildMoveOption(ctx, osId, 'Concluído', '50', Icons.check_circle_outline, Colors.greenAccent, currentStage),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoveOption(
    BuildContext context, 
    String osId, 
    String stageName, 
    String etapaCode, 
    IconData icon, 
    Color color,
    String currentStage
  ) {
    final bool isCurrent = currentStage == stageName;
    return InkWell(
      onTap: isCurrent ? null : () {
        widget.provider.updateOSStage(osId, etapaCode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCurrent ? color.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent ? color : const Color(0xFFE2E8F0),
            width: isCurrent ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isCurrent ? color : AppTheme.textMuted, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                stageName,
                style: TextStyle(
                  color: isCurrent ? color : AppTheme.textBody,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            if (isCurrent)
              Text(
                'Etapa Atual',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              )
            else
              const Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 12),
          ],
        ),
      ),
    );
  }
}
