import '../../../core/format/formatters.dart';
import '../../../domain/calc/cash_flow.dart';
import '../../../domain/calc/finance_plan.dart';
import '../../../domain/calc/product_plan.dart';
import '../../../domain/models/enums.dart';
import 'dashboard_data.dart';

class SummaryAlert {
  const SummaryAlert(this.signal, this.message);
  final Signal signal;
  final String message;
}

/// "Alertas automáticos" da aba Resumo, com o saldo do período filtrado.
List<SummaryAlert> summaryAlerts(FinancePlan plan, DashboardData data) {
  final minimum = plan.minimumMonthly;
  final available = plan.available;
  final noGoal = plan.totalMissing <= 0;
  final money = Fmt.money;

  return [
    noGoal
        ? const SummaryAlert(Signal.good, 'Tudo certo: todos os produtos já estão totalmente guardados.')
        : SummaryAlert(Signal.critical,
            'Você precisa guardar ${money(minimum)} por mês para atingir todas as metas no prazo.'),
    if (noGoal)
      const SummaryAlert(Signal.good, 'Sem meta mensal pendente.')
    else if (available >= minimum)
      SummaryAlert(Signal.good, 'Sua economia mensal (${money(available)}) cobre a meta.')
    else
      SummaryAlert(Signal.warning,
          'Sua economia atual (${money(available)}/mês) está abaixo da meta (${money(minimum)}/mês).'),
    plan.schedule.onTrack
        ? const SummaryAlert(Signal.good, 'Você está dentro do cronograma.')
        : SummaryAlert(Signal.warning,
            'Você está abaixo do cronograma: faltam ${money(plan.schedule.shortfall)} para estar em dia.'),
    if (plan.priorities.increaseNeeded > 0)
      SummaryAlert(Signal.warning,
          'Por prioridade, ${plan.priorities.lateCount} produto(s) não cabem no prazo: aumente a economia em '
          '${money(plan.priorities.increaseNeeded)}/mês ou adie as datas (Planejamento › Prioridades).')
    else
      const SummaryAlert(Signal.good, 'Com a sua economia, todos os produtos cabem no prazo (por prioridade).'),
    _periodAlert(data, minimum),
  ];
}

SummaryAlert _periodAlert(DashboardData data, double minimum) {
  final t = data.totals;
  final yearly = data.period.isWholeYear;
  final inPeriod = yearly ? 'neste ano' : 'neste mês';
  final ofPeriod = yearly ? 'do ano' : 'do mês';
  final target = Fmt.money(minimum * (yearly ? 12 : 1));
  return switch (data.situation) {
    MonthSituation.empty => SummaryAlert(Signal.neutral, 'Ainda sem lançamentos $inPeriod.'),
    MonthSituation.negative => SummaryAlert(Signal.critical,
        'Suas despesas $ofPeriod (${Fmt.money(t.expenses)}) estão acima das receitas (${Fmt.money(t.income)}).'),
    MonthSituation.reached => SummaryAlert(Signal.good,
        'O saldo $ofPeriod (${Fmt.money(t.balance)}) cobre a meta de economia ($target).'),
    MonthSituation.tight || MonthSituation.below => SummaryAlert(Signal.warning,
        'O saldo $ofPeriod (${Fmt.money(t.balance)}) está abaixo da meta de economia ($target).'),
  };
}

String productAlertText(ProductAlert alert) {
  final name = alert.product.name;
  final missing = Fmt.money(alert.product.remaining);
  return switch (alert.kind) {
    ProductAlertKind.canBuy => '$name poderá ser comprado este mês.',
    ProductAlertKind.late => '$name está atrasado — faltam $missing.',
    ProductAlertKind.dueSoon => '$name vence em ${alert.daysLeft} dia(s) — faltam $missing.',
  };
}

Signal productAlertSignal(ProductAlert alert) =>
    alert.kind == ProductAlertKind.late ? Signal.critical : Signal.info;
