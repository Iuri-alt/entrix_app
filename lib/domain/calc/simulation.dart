import 'priority_plan.dart';

enum ScenarioOutcome { buysAll, buysSome, buysNothing }

/// Uma coluna da aba Simulação.
class Scenario {
  Scenario._({
    required this.monthlySaving,
    required this.alreadySaved,
    required this.willSave,
    required this.affordableCount,
    required this.missing,
    required this.purchases,
  });

  final double monthlySaving;
  final double alreadySaved;

  /// "Vou guardar até o fim do plano".
  final double willSave;

  /// "Produtos que consigo comprar até o fim do plano".
  final int affordableCount;

  /// "Quanto vai faltar para comprar tudo".
  final double missing;

  /// Mês de compra de cada produto, na ordem da aba Prioridades.
  final List<PurchaseMonth> purchases;

  /// "Quanto acumularei até o prazo final".
  double get accumulated => alreadySaved + willSave;

  ScenarioOutcome get outcome => missing <= 0
      ? ScenarioOutcome.buysAll
      : affordableCount > 0
          ? ScenarioOutcome.buysSome
          : ScenarioOutcome.buysNothing;

  static Scenario build({
    required double monthlySaving,
    required PriorityPlan priorities,
    required int planMonths,
    required double totalSaved,
    required double totalMissing,
    required DateTime planStart,
  }) {
    final willSave = monthlySaving * planMonths;
    final missing = totalMissing - willSave;
    return Scenario._(
      monthlySaving: monthlySaving,
      alreadySaved: totalSaved,
      willSave: willSave,
      affordableCount: priorities.rows.where((r) => r.cumulative <= willSave).length,
      missing: missing > 0 ? missing : 0,
      purchases: [
        for (final row in priorities.rows)
          purchaseMonth(
            cumulative: row.cumulative,
            monthlySaving: monthlySaving,
            planStart: planStart,
          ),
      ],
    );
  }
}
