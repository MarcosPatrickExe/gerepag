import 'package:flutter/material.dart';

class BpoMobileScanner extends StatefulWidget {
  const BpoMobileScanner({super.key});

  @override
  State<BpoMobileScanner> createState() => _BpoMobileScannerState();
}

class _BpoMobileScannerState extends State<BpoMobileScanner> {
  bool _isScanning = false;

  void _simulateScan() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📸 Recibo escaneado com sucesso! Lançamento enviado para conciliação.'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SCANNER MOBILE & PWA DE RECIBOS 📱', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F172A))),
                  SizedBox(height: 4),
                  Text('Digitalização rápida de notas de balcão, cupons e comprovantes via smartphone', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _simulateScan,
                icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                label: const Text('TIRAR FOTO DO RECIBO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Simulador do Smartphone com Câmera
          Center(
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF1E293B), width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  // Notch superior
                  Container(width: 80, height: 16, decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 16),

                  // Área da Câmera com Mira
                  Container(
                    height: 380,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded, color: Colors.white24, size: 80),
                            SizedBox(height: 12),
                            Text('Posicione o comprovante na moldura', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),

                        // Moldura de Leitura Verde
                        Container(
                          margin: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF10B981), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        if (_isScanning)
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFF10B981)),
                              SizedBox(height: 12),
                              Text('Extraindo dados via IA...', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _simulateScan,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), minimumSize: const Size(double.infinity, 44)),
                    child: const Text('CAPTURAR RECIBO (AGORA)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
