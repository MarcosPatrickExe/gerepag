import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dre_node.dart';
import '../core/app_theme.dart';

class DreTreeView extends StatelessWidget {
  final Map<String, DreNode> nodes;
  final bool isSmall;

  const DreTreeView({super.key, required this.nodes, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    final sortedRoots = nodes.values.toList()
      ..sort((a, b) => a.code.compareTo(b.code));

    return Column(
      children: sortedRoots.map((node) => _buildNode(node)).toList(),
    );
  }

  Widget _buildNode(DreNode node) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final bool hasChildren = node.children.isNotEmpty;
    final bool isPositive = node.total >= 0;

    return Theme(
      data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey(node.code),
        tilePadding: EdgeInsets.only(left: (node.level - 1) * 16.0, right: 16),
        leading: Icon(
          node.level == 1 
            ? (node.code.startsWith('1') ? Icons.trending_up : Icons.trending_down)
            : (hasChildren ? Icons.folder_open : Icons.label_outline),
          color: node.level == 1 
            ? (node.code.startsWith('1') ? Colors.greenAccent : Colors.orangeAccent)
            : Colors.white30,
          size: 18,
        ),
        title: Text(
          node.name.toUpperCase(),
          style: TextStyle(
            color: node.level == 1 ? Colors.white : Colors.white70,
            fontSize: node.level == 1 ? 13 : 11,
            fontWeight: node.level == 1 ? FontWeight.bold : FontWeight.normal,
            letterSpacing: node.level == 1 ? 1.1 : 0.5,
          ),
        ),
        trailing: Text(
          currency.format(node.total),
          style: TextStyle(
            color: isPositive ? Colors.greenAccent : Colors.redAccent,
            fontSize: node.level == 1 ? 13 : 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        initiallyExpanded: node.level == 1,
        children: node.sortedChildren.map((child) => _buildNode(child)).toList(),
      ),
    );
  }
}
