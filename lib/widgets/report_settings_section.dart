import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ReportConfigModel {
  final String id;
  final String title;
  final String frequency; // Diário, Semanal, Mensal
  final String email;
  final bool isActive;

  ReportConfigModel({
    required this.id,
    required this.title,
    required this.frequency,
    required this.email,
    this.isActive = true,
  });
}

class ReportSettingsSection extends StatefulWidget {
  const ReportSettingsSection({super.key});

  @override
  State<ReportSettingsSection> createState() => _ReportSettingsSectionState();
}

class _ReportSettingsSectionState extends State<ReportSettingsSection> {
  final List<ReportConfigModel> _configs = [
    ReportConfigModel(id: '1', title: 'Resumo Executivo Diário', frequency: 'Diário', email: 'diretoria@empresa.com'),
    ReportConfigModel(id: '2', title: 'Relatório de Vendas Semanal', frequency: 'Semanal', email: 'vendas@empresa.com'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'ENVIO AUTOMÁTICO DE RELATÓRIOS 📧', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Novo Agendamento'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Configure relatórios automáticos em PDF para serem enviados diretamente para seu e-mail ou de sua equipe.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ..._configs.map((config) => _buildConfigTile(config)),
        ],
      ),
    );
  }

  Widget _buildConfigTile(ReportConfigModel config) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.picture_as_pdf, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Frequência: ${config.frequency} • Destinatário: ${config.email}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: config.isActive,
            onChanged: (val) {},
            activeColor: AppTheme.primary,
          ),
          IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.black45), onPressed: () {}),
        ],
      ),
    );
  }
}
