import '../models/enums.dart';
import '../models/plan_settings.dart';
import 'cash_flow.dart';

enum IncomeSituation {
  noGoal('Sem meta pendente', Signal.good),
  possible('Meta possível', Signal.good),
  tight('Meta apertada', Signal.warning),
  impossible('Meta impossível no momento', Signal.critical);

  const IncomeSituation(this.label, this.signal);
  final String label;
  final Signal signal;
}

/// Aba Renda.
class IncomePlan {
  IncomePlan._({
    required this.settings,
    required this.realizedAverage,
  });

  final PlanSettings settings;

  /// "Média realizada (meses já lançados)": nulo = sem dados ainda.
  final double? realizedAverage;

  double get forecast => settings.forecastAvailable;

  /// `Disponivel`: base Realizado usa a média; sem lançamentos, usa o previsto.
  double get available =>
      settings.planBase == PlanBase.actual && realizedAverage != null
          ? realizedAverage!
          : forecast;

  bool get usesRealized =>
      settings.planBase == PlanBase.actual && realizedAverage != null;

  IncomeSituation situation({required double minimum, required double totalMissing}) {
    if (totalMissing <= 0) return IncomeSituation.noGoal;
    if (available >= minimum) return IncomeSituation.possible;
    if (available >= minimum * settings.tightLimit) return IncomeSituation.tight;
    return IncomeSituation.impossible;
  }

  double shortfall(double minimum) => minimum - available > 0 ? minimum - available : 0;

  double minimumShareOfIncome(double minimum) =>
      settings.budgetIncome == 0 ? 0 : minimum / settings.budgetIncome;

  /// Média do saldo dos meses do plano que têm lançamento e já começaram.
  static IncomePlan build({
    required PlanSettings settings,
    required List<CashFlowMonth> planMonths,
    required DateTime today,
  }) {
    var sum = 0.0;
    var count = 0;
    for (final row in planMonths) {
      if (row.totals.isEmpty || row.month.isAfter(today)) continue;
      sum += row.totals.balance;
      count++;
    }
    return IncomePlan._(
      settings: settings,
      realizedAverage: count == 0 ? null : sum / count,
    );
  }
}
