import '../../../domain/calc/cash_flow.dart';
import '../../../domain/calc/finance_plan.dart';
import '../../../domain/models/transaction.dart';
import 'dashboard_period.dart';

/// Agregações do painel para um período (calculadas uma vez por filtro).
class DashboardData {
  DashboardData(this.plan, this.period)
      : transactions = plan.cashFlow.inYear(period.year, month: period.month).toList(growable: false);

  final FinancePlan plan;
  final DashboardPeriod period;
  final List<FinanceTransaction> transactions;

  late final FlowTotals totals = FlowTotals.of(transactions);

  /// Receitas/despesas de cada mês do ano filtrado.
  late final List<FlowTotals> months = [
    for (var m = 1; m <= 12; m++) plan.cashFlow.totalsOf(DateTime(period.year, m)),
  ];

  /// Saldo acumulado no fim de cada mês do ano (inclui o saldo dos anos anteriores).
  late final List<double> accumulatedBalance = () {
    var running = 0.0;
    final first = plan.cashFlow.firstMonth;
    if (first != null) {
      for (var m = first; m.isBefore(DateTime(period.year)); m = DateTime(m.year, m.month + 1)) {
        running += plan.cashFlow.totalsOf(m).balance;
      }
    }
    return [for (final t in months) running += t.balance];
  }();

  late final List<CategoryTotal> categories = (CashFlow.byCategory(
    transactions,
    plan.settings.expenseCategories,
  )..sort((a, b) => b.amount.compareTo(a.amount)))
      .where((c) => c.amount > 0)
      .toList(growable: false);

  /// Situação do período comparada com a meta mínima (mês) ou meta × meses (ano).
  MonthSituation get situation => MonthSituation.evaluate(
        totals,
        plan.minimumMonthly * (period.isWholeYear ? 12 : 1),
        plan.settings.tightLimit,
      );
}
