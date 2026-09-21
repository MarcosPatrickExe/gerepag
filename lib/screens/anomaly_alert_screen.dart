import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class AnomalyAlertScreen extends StatefulWidget {
  final TransactionModel transaction;
  final String reason;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const AnomalyAlertScreen({
    super.key,
    required this.transaction,
    required this.reason,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<AnomalyAlertScreen> createState() => _AnomalyAlertScreenState();
}

class _AnomalyAlertScreenState extends State<AnomalyAlertScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fundo Pulsante
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              return Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8 * _pulse.value,
                  height: MediaQuery.of(context).size.width * 0.8 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.2),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 80),
                  const SizedBox(height: 32),
                  const Text(
                    'ALERTA DA SENTINELA 🛡️',
                    style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.textBody.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.reason,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textBody, fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.textMuted),
                        const SizedBox(height: 24),
                        Text(
                          widget.transaction.category.toUpperCase(),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        Text(
                          currency.format(widget.transaction.amount),
                          style: const TextStyle(color: AppTheme.textBody, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        widget.onConfirm();
                        Navigator.pop(context);
                      },
                      child: const Text('FUI EU (RECONHECER)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      widget.onCancel();
                      Navigator.pop(context);
                    },
                    child: const Text('NÃO RECONHEÇO (BLOQUEAR)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
