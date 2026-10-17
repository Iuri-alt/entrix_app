import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../widgets/kpi_tile.dart';
import '../../widgets/plan_table.dart';
import '../../widgets/section_card.dart';
import '../../widgets/signal_badge.dart';
import 'purchase_label.dart';
import 'tab_body.dart';

class PrioritiesTab extends StatelessWidget {
  const PrioritiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PlanTabBody(builder: (context, plan) {
      final p = plan.priorities;
      String money(double? v) => v == null ? '—' : Fmt.money(v);
      return [
        ResponsiveGrid(
          minItemWidth: 170,
          maxColumns: 4,
          children: [
            KpiTile(label: 'Economia mensal disponível', value: Fmt.money(plan.available)),
            KpiTile(label: 'Mínimo p/ cumprir os prazos', value: Fmt.money(p.minimumMonthly)),
            KpiTile(label: 'Aumento necessário/mês', value: Fmt.money(p.increaseNeeded)),
            KpiTile(
              label: 'Cabem / não cabem no prazo',
              value: '${p.onTimeCount} / ${p.lateCount}',
            ),
          ],
        ),
        SectionCard(
          title: 'Sistema de prioridades',
          subtitle: 'O dinheiro vai primeiro para Alta, depois Média e Baixa — um produto por vez. '
              'Empate: data mais próxima.',
          child: PlanTable(
            columns: const [
              PlanColumn('Ordem', numeric: true),
              PlanColumn('Produto'),
              PlanColumn('Prioridade'),
              PlanColumn('Data desejada'),
              PlanColumn('Valor restante', numeric: true),
              PlanColumn('Acumulado necessário', numeric: true),
              PlanColumn('Mês possível'),
              PlanColumn('Prazo (mês)'),
              PlanColumn('Situação'),
              PlanColumn('Nova data sugerida'),
              PlanColumn('Economia/mês p/ prazo', numeric: true),
              PlanColumn('Aumento/mês', numeric: true),
            ],
            rows: [
              for (final r in p.rows)
                [
                  '${r.order}',
                  r.plan.product.name,
                  r.plan.product.priority.label,
                  r.plan.product.targetDate == null ? '—' : Fmt.date(r.plan.product.targetDate!),
                  Fmt.money(r.plan.remaining),
                  Fmt.money(r.cumulative),
                  purchaseText(r.purchase),
                  r.deadline == null ? '—' : Fmt.monthYear(r.deadline!),
                  SignalBadge(signal: r.fit.signal, label: r.fit.label, dense: true),
                  r.suggestedDate == null ? '—' : Fmt.date(r.suggestedDate!),
                  money(r.requiredMonthly),
                  money(r.increaseNeeded),
                ],
            ],
          ),
        ),
        const HowToRead(
          '"Mês possível" = mês em que o dinheiro disponível termina de pagar este produto e todos '
          'os de prioridade maior. Se passar do prazo, a linha sugere a nova data ou quanto aumentar '
          'a economia mensal. Para mudar a ordem, altere a prioridade do produto.',
        ),
      ];
    });
  }
}
