import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/realtime_db_service.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final RealtimeDbService _realtimeService = RealtimeDbService();
  final List<Map<String, dynamic>> _defaultCategories = [
    {'name': 'Comida', 'icon': Icons.fastfood},
    {'name': 'Transporte', 'icon': Icons.directions_car},
    {'name': 'Lazer', 'icon': Icons.sports_esports},
    {'name': 'Saúde', 'icon': Icons.medical_services},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Categorias'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onPressed: () => _showAddCategory(context),
          ),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: _realtimeService.getCategories(),
        builder: (context, snapshot) {
          final customCategories = snapshot.data ?? [];
          final allCategories = [..._defaultCategories.map((c) => c['name']), ...customCategories];

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: allCategories.length,
            itemBuilder: (context, index) {
              final catName = allCategories[index];
              final isDefault = index < _defaultCategories.length;
              final icon = isDefault ? _defaultCategories[index]['icon'] : Icons.label;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: AppTheme.primary),
                    const SizedBox(width: 16),
                    Text(catName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (!isDefault)
                      const Text('Personalizada', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCategory(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Nova Categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome da categoria'),
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _realtimeService.addCategory(controller.text);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('ADICIONAR', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
