import 'package:flutter/material.dart';
import '../services/anomaly_service.dart';

class FraudPreventionWidget extends StatelessWidget {
  final AnomalyResult result;
  final VoidCallback? onDismiss;
  final VoidCallback? onReport;

  const FraudPreventionWidget({
    super.key,
    required this.result,
    this.onDismiss,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    if (!result.isSuspect) return const SizedBox.shrink();

    final isCritical = result.isCritical || result.type == AnomalyType.cnpjmismatch;
    final primaryColor = isCritical ? Colors.red.shade700 : Colors.amber.shade800;
    final bgColor = isCritical ? Colors.red.shade50 : Colors.amber.shade50;
    final borderColor = isCritical ? Colors.red.shade200 : Colors.amber.shade300;

    IconData iconData;
    switch (result.type) {
      case AnomalyType.duplicate:
        iconData = Icons.copy_rounded;
        break;
      case AnomalyType.cnpjmismatch:
        iconData = Icons.shield_rounded;
        break;
      case AnomalyType.magnitude:
        iconData = Icons.trending_up_rounded;
        break;
      case AnomalyType.nocturnal:
        iconData = Icons.nightlight_round;
        break;
      default:
        iconData = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: primaryColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.reason,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(result.score * 100).toInt()}% Risco',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (result.details != null && result.details!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              result.details!,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ],
          if (onReport != null || onDismiss != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onDismiss != null)
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Ignorar', style: TextStyle(fontSize: 12)),
                  ),
                if (onReport != null)
                  ElevatedButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.verified_user_outlined, size: 14),
                    label: const Text('Validar com Cliente', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
