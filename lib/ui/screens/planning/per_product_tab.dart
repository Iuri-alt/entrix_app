import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../widgets/plan_table.dart';
import '../../widgets/section_card.dart';
import '../../widgets/signal_badge.dart';
import '../dashboard/summary_alerts.dart';
import 'tab_body.dart';

class PerProductTab extends StatelessWidget {
  const PerProductTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PlanTabBody(builder: (context, plan) {
      String money(double? v) => v == null ? '—' : Fmt.money(v);
      return [
        SectionCard(
          title: 'Cálculo individual por produto',
          subtitle: 'Produto atrasado conta como 1 mês/semana/dia (guardar tudo já)',
          child: PlanTable(
            columns: const [
              PlanColumn('Produto'),
              PlanColumn('Valor restante', numeric: true),
              PlanColumn('Meses restantes', numeric: true),
              PlanColumn('Guardar/mês', numeric: true),
              PlanColumn('Guardar/semana', numeric: true),
              PlanColumn('Guardar/dia', numeric: true),
              PlanColumn('Alerta'),
            ],
            rows: [
              for (final p in plan.productPlans)
                [
                  p.product.name,
                  Fmt.money(p.remaining),
                  p.monthsLeft?.toString() ?? 'Sem data',
                  money(p.perMonth),
                  money(p.perWeek),
                  money(p.perDay),
                  p.alert == null
                      ? ''
                      : SignalBadge(
                          signal: productAlertSignal(p.alert!),
                          label: productAlertText(p.alert!),
                          dense: true,
                        ),
                ],
            ],
            footer: [
              'TOTAL',
              Fmt.money(plan.totalMissing),
              '',
              Fmt.money(plan.monthlyGoal),
              Fmt.money(plan.weeklyGoal),
              Fmt.money(plan.dailyGoal),
              '',
            ],
          ),
        ),
        const HowToRead(
          'Meses restantes: do 1º mês do plano até o mês da data desejada (mínimo 1; datas depois '
          'do prazo final contam como o prazo final). Semanas = dias ÷ 7, arredondado para cima. '
          'Produto sem data fica fora do cronograma.',
        ),
      ];
    });
  }
}
