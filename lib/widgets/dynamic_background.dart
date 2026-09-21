import 'package:flutter/material.dart';

class DynamicBackground extends StatelessWidget {
  final Widget child;
  const DynamicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: child,
    );
  }
}
