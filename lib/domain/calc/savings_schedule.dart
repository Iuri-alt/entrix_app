import '../../core/utils/month.dart';
import 'product_plan.dart';

/// Uma linha da aba Cronograma.
class ScheduleRow {
  const ScheduleRow({
    required this.number,
    required this.month,
    required this.target,
    required this.alreadySaved,
    required this.toSave,
    required this.accumulated,
    required this.targetAccumulated,
  });

  final int number;
  final DateTime month;

  /// "Meta de economia" = Σ preço ÷ meses dos produtos ainda ativos no mês.
  final double target;

  /// "Valor já guardado" = parte da meta coberta pelo que já foi reservado.
  final double alreadySaved;

  /// "Quanto guardar" = meta − já guardado.
  final double toSave;

  /// "Valor acumulado" = total guardado hoje + Σ quanto guardar até o mês.
  final double accumulated;

  /// "Meta acumulada" = Σ meta até o mês.
  final double targetAccumulated;
}

class SavingsSchedule {
  SavingsSchedule._({
    required this.rows,
    required this.currentNumber,
    required this.totalSaved,
  });

  final List<ScheduleRow> rows;

  /// "Mês atual do plano (nº)".
  final int currentNumber;
  final double totalSaved;

  ScheduleRow get currentRow => rows[currentNumber - 1];

  /// "Meta acumulada esperada até o mês passado".
  double get expectedUntilLastMonth =>
      currentNumber <= 1 ? 0 : rows[currentNumber - 2].targetAccumulated;

  bool get onTrack => totalSaved >= expectedUntilLastMonth;
  double get shortfall => onTrack ? 0 : expectedUntilLastMonth - totalSaved;

  static SavingsSchedule build({
    required List<ProductPlan> plans,
    required DateTime planStart,
    required int planMonths,
    required DateTime today,
    required double totalSaved,
  }) {
    final rows = <ScheduleRow>[];
    var accumulated = totalSaved;
    var targetAccumulated = 0.0;

    for (var n = 1; n <= planMonths; n++) {
      var target = 0.0, saved = 0.0;
      for (final plan in plans) {
        final months = plan.monthsLeft;
        if (months != null && months >= n) {
          target += plan.priceShare!;
          saved += plan.savedShare!;
        }
      }
      final toSave = target - saved;
      accumulated += toSave;
      targetAccumulated += target;
      rows.add(ScheduleRow(
        number: n,
        month: Month.add(planStart, n - 1),
        target: target,
        alreadySaved: saved,
        toSave: toSave,
        accumulated: accumulated,
        targetAccumulated: targetAccumulated,
      ));
    }

    final current = Month.index(planStart, today).clamp(1, planMonths);
    return SavingsSchedule._(rows: rows, currentNumber: current, totalSaved: totalSaved);
  }
}
