import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/models/enums.dart';

/// Indicador de situação: ícone + texto, nunca só a cor.
class SignalBadge extends StatelessWidget {
  const SignalBadge({super.key, required this.signal, required this.label, this.dense = false});

  final Signal signal;
  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.signal(signal);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 10, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppColors.signalIcon(signal), size: dense ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: dense ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de alerta (aba Resumo → Alertas automáticos).
class AlertLine extends StatelessWidget {
  const AlertLine({super.key, required this.signal, required this.message});

  final Signal signal;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppColors.signalIcon(signal), size: 18, color: AppColors.signal(signal)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
