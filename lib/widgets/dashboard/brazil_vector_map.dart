import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';

class BrazilVectorMap extends StatefulWidget {
  final Map<String, double> data;

  const BrazilVectorMap({super.key, required this.data});

  @override
  State<BrazilVectorMap> createState() => _BrazilVectorMapState();
}

class _BrazilVectorMapState extends State<BrazilVectorMap> {
  String? _selectedState;

  // Proporções geográficas aproximadas mapeadas para um canvas (x, y) de 0.0 a 1.0
  final Map<String, Offset> _stateOffsets = {
    'AC': const Offset(0.08, 0.40),
    'AM': const Offset(0.20, 0.22),
    'RR': const Offset(0.23, 0.08),
    'RO': const Offset(0.25, 0.45),
    'PA': const Offset(0.48, 0.20),
    'AP': const Offset(0.52, 0.08),
    'TO': const Offset(0.58, 0.38),
    'MA': const Offset(0.66, 0.22),
    'PI': const Offset(0.72, 0.28),
    'CE': const Offset(0.80, 0.22),
    'RN': const Offset(0.88, 0.24),
    'PB': const Offset(0.90, 0.28),
    'PE': const Offset(0.88, 0.32),
    'AL': const Offset(0.90, 0.36),
    'SE': const Offset(0.88, 0.40),
    'BA': const Offset(0.76, 0.44),
    'MT': const Offset(0.42, 0.50),
    'DF': const Offset(0.58, 0.56),
    'GO': const Offset(0.55, 0.58),
    'MS': const Offset(0.40, 0.68),
    'MG': const Offset(0.68, 0.65),
    'ES': const Offset(0.78, 0.67),
    'RJ': const Offset(0.73, 0.74),
    'SP': const Offset(0.62, 0.75),
    'PR': const Offset(0.52, 0.82),
    'SC': const Offset(0.54, 0.88),
    'RS': const Offset(0.48, 0.94),
  };

  final Map<String, String> _stateNames = {
    'AC': 'Acre', 'AL': 'Alagoas', 'AP': 'Amapá', 'AM': 'Amazonas', 'BA': 'Bahia',
    'CE': 'Ceará', 'DF': 'Distrito Federal', 'ES': 'Espírito Santo', 'GO': 'Goiás',
    'MA': 'Maranhão', 'MT': 'Mato Grosso', 'MS': 'Mato Grosso do Sul', 'MG': 'Minas Gerais',
    'PA': 'Pará', 'PB': 'Paraíba', 'PR': 'Paraná', 'PE': 'Pernambuco', 'PI': 'Piauí',
    'RJ': 'Rio de Janeiro', 'RN': 'Rio Grande do Norte', 'RS': 'Rio Grande do Sul',
    'RO': 'Rondônia', 'RR': 'Roraima', 'SC': 'Santa Catarina', 'SP': 'São Paulo',
    'SE': 'Sergipe', 'TO': 'Tocantins',
  };

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    // Remove estados desconhecidos ("??") e faz os cálculos
    final cleanData = Map<String, double>.from(widget.data)..remove('??');
    final double totalSales = cleanData.values.fold(0.0, (sum, val) => sum + val);
    final double maxSales = cleanData.isEmpty ? 0.0 : cleanData.values.fold(0.0, (max, val) => val > max ? val : max);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) {
            const double padding = 20.0;
            final double mapWidth = constraints.maxWidth - (padding * 2);
            final double mapHeight = constraints.maxHeight - (padding * 2);

            Offset getPixelOffset(Offset relOffset) {
              return Offset(
                padding + (relOffset.dx * mapWidth),
                padding + (relOffset.dy * mapHeight),
              );
            }

            String? clickedState;
            double minDistance = 25.0; // raio de clique em pixels

            _stateOffsets.forEach((uf, relOffset) {
              final pos = getPixelOffset(relOffset);
              final dist = (details.localPosition - pos).distance;
              if (dist < minDistance) {
                minDistance = dist;
                clickedState = uf;
              }
            });

            setState(() {
              _selectedState = clickedState;
            });
          },
          child: Stack(
            children: [
              // O Mapa Vetorial Estilizado
              Positioned.fill(
                child: CustomPaint(
                  painter: BrazilConstellationPainter(
                    data: cleanData,
                    stateOffsets: _stateOffsets,
                    selectedState: _selectedState,
                    maxSales: maxSales,
                  ),
                ),
              ),

              // Tooltip Flutuante de Informação do Estado Selecionado
              if (_selectedState != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(maxWidth: 220),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedState!,
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                              onPressed: () => setState(() => _selectedState = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stateNames[_selectedState] ?? 'Estado',
                          style: const TextStyle(
                            color: AppTheme.textBody,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'TOTAL DE VENDAS',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currency.format(cleanData[_selectedState] ?? 0.0),
                          style: const TextStyle(
                            color: AppTheme.textBody,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (totalSales > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Representa ${((cleanData[_selectedState] ?? 0.0) / totalSales * 100).toStringAsFixed(1)}% do total',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_outlined, color: Colors.white70, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Toque em um estado',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class BrazilConstellationPainter extends CustomPainter {
  final Map<String, double> data;
  final Map<String, Offset> stateOffsets;
  final String? selectedState;
  final double maxSales;

  BrazilConstellationPainter({
    required this.data,
    required this.stateOffsets,
    required this.selectedState,
    required this.maxSales,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double padding = 20.0;
    final double mapWidth = size.width - (padding * 2);
    final double mapHeight = size.height - (padding * 2);

    // Converte offset relativo (0..1) para pixel no canvas
    Offset getPixelOffset(Offset relOffset) {
      return Offset(
        padding + (relOffset.dx * mapWidth),
        padding + (relOffset.dy * mapHeight),
      );
    }

    // 1. Desenhar a Grade de Coordenadas de Radar
    final gridPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    
    for (int i = 1; i < 6; i++) {
      double y = padding + (i * mapHeight / 6);
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
      
      double x = padding + (i * mapWidth / 6);
      canvas.drawLine(Offset(x, padding), Offset(x, size.height - padding), gridPaint);
    }

    // 2. Desenhar conexões de constelação (Vizinhos Geográficos de Venda)
    final linePaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    final List<List<String>> connections = [
      ['AM', 'RR'], ['AM', 'PA'], ['AM', 'AC'], ['AM', 'RO'], ['AM', 'MT'],
      ['PA', 'AP'], ['PA', 'MA'], ['PA', 'TO'], ['PA', 'MT'],
      ['RO', 'MT'], ['MT', 'MS'], ['MT', 'GO'], ['MT', 'TO'],
      ['MS', 'PR'], ['MS', 'SP'], ['MS', 'GO'],
      ['GO', 'DF'], ['GO', 'TO'], ['GO', 'MG'], ['GO', 'BA'],
      ['TO', 'MA'], ['TO', 'PI'], ['TO', 'BA'],
      ['MA', 'PI'], ['PI', 'CE'], ['PI', 'PE'], ['PI', 'BA'],
      ['CE', 'RN'], ['CE', 'PB'], ['CE', 'PE'],
      ['RN', 'PB'], ['PB', 'PE'], ['PE', 'AL'], ['PE', 'BA'],
      ['AL', 'SE'], ['SE', 'BA'],
      ['BA', 'MG'], ['BA', 'ES'],
      ['MG', 'ES'], ['MG', 'RJ'], ['MG', 'SP'],
      ['SP', 'RJ'], ['SP', 'PR'],
      ['PR', 'SC'], ['SC', 'RS'],
    ];

    for (var conn in connections) {
      final off1 = stateOffsets[conn[0]];
      final off2 = stateOffsets[conn[1]];
      if (off1 != null && off2 != null) {
        canvas.drawLine(getPixelOffset(off1), getPixelOffset(off2), linePaint);
      }
    }

    // 3. Desenhar os Nós dos Estados
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    stateOffsets.forEach((uf, relOffset) {
      final pos = getPixelOffset(relOffset);
      final sales = data[uf] ?? 0.0;
      final bool isSelected = selectedState == uf;

      double radius = 5.0;
      Color nodeColor = Colors.blueAccent.withValues(alpha: 0.2);
      Paint glowPaint = Paint()..color = Colors.transparent;

      if (sales > 0.0) {
        double ratio = maxSales > 0 ? (sales / maxSales) : 0.0;
        radius = 6.0 + (ratio * 14.0);
        
        if (ratio > 0.6) {
          nodeColor = Colors.greenAccent;
        } else if (ratio > 0.25) {
          nodeColor = Colors.cyanAccent;
        } else {
          nodeColor = Colors.blueAccent;
        }

        glowPaint = Paint()
          ..color = nodeColor.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      }

      if (isSelected) {
        glowPaint = Paint()
          ..color = Colors.blueAccent.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        
        final focusPaint = Paint()
          ..color = Colors.blueAccent.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(pos, radius + 6, focusPaint);
      }

      if (glowPaint.color != Colors.transparent) {
        canvas.drawCircle(pos, radius + 3, glowPaint);
      }

      final nodePaint = Paint()
        ..color = isSelected ? Colors.white : nodeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius, nodePaint);

      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: isSelected ? 0.8 : 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(pos, radius, borderPaint);

      textPainter.text = TextSpan(
        text: uf,
        style: TextStyle(
          color: isSelected 
              ? Colors.black 
              : (sales > 0 ? Colors.white : AppTheme.textBody.withValues(alpha: 0.5)),
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(pos.dx - (textPainter.width / 2), pos.dy - (textPainter.height / 2)),
      );
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
