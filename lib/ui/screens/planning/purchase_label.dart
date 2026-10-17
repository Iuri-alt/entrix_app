import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../domain/calc/priority_plan.dart';
import '../../../domain/models/enums.dart';
import '../../widgets/signal_badge.dart';

/// "Mês possível de compra" com a cor da legenda da aba Simulação.
Widget purchaseBadge(PurchaseMonth purchase, DateTime planLastMonth) => switch (purchase) {
      AlreadyPossible() => const SignalBadge(signal: Signal.info, label: 'Já possível', dense: true),
      NoSavings() => const SignalBadge(signal: Signal.critical, label: 'Sem economia', dense: true),
      InMonth(:final month) => SignalBadge(
          signal: month.isAfter(planLastMonth) ? Signal.warning : Signal.good,
          label: Fmt.monthYear(month),
          dense: true,
        ),
    };

String purchaseText(PurchaseMonth purchase) => switch (purchase) {
      AlreadyPossible() => 'Já possível',
      NoSavings() => 'Sem economia',
      InMonth(:final month) => Fmt.monthYear(month),
    };
