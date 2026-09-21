import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/app_theme.dart';

class RadialMenu extends StatefulWidget {
  final Function(int) onActionSelected;
  const RadialMenu({super.key, required this.onActionSelected});

  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          _buildMenuItem(0, Icons.add_shopping_cart, 'Despesa', Colors.redAccent),
          _buildMenuItem(1, Icons.account_balance_wallet, 'Receita', Colors.greenAccent),
          _buildMenuItem(2, Icons.swap_horiz, 'Transf.', Colors.blueAccent),
          
          // Main Button
          GestureDetector(
            onTap: _toggle,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * math.pi / 4,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label, Color color) {
    final double angle = (index * 45 + 180) * math.pi / 180;
    const double radius = 110;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double currentRadius = _controller.value * radius;
        final double x = currentRadius * math.cos(angle);
        final double y = currentRadius * math.sin(angle);

        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: _controller.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    _toggle();
                    widget.onActionSelected(index);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
