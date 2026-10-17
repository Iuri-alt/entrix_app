import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../domain/models/enums.dart';
import '../../widgets/plan_table.dart';
import '../../widgets/section_card.dart';
import '../../widgets/signal_badge.dart';
import 'tab_body.dart';

class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PlanTabBody(builder: (context, plan) {
      final s = plan.schedule;
      return [
        SectionCard(
          title: 'Acompanhamento',
          child: PlanTable(
            columns: const [PlanColumn('Item'), PlanColumn('Valor')],
            rows: [
              ['Mês atual do plano', '${s.currentNumber}º · ${Fmt.monthYear(s.currentRow.month)}'],
              ['Total já guardado hoje (todos os produtos)', Fmt.money(s.totalSaved)],
              ['Meta acumulada esperada até o mês passado', Fmt.money(s.expectedUntilLastMonth)],
              [
                'Situação',
                s.onTrack
                    ? const SignalBadge(signal: Signal.good, label: 'Dentro do cronograma', dense: true)
                    : SignalBadge(
                        signal: Signal.warning,
                        label: 'Abaixo: faltam ${Fmt.money(s.shortfall)}',
                        dense: true,
                      ),
              ],
            ],
          ),
        ),
        SectionCard(
          title: 'Cronograma mensal de economia',
          subtitle: 'O valor a guardar cai conforme os produtos são concluídos',
          child: PlanTable(
            highlightRow: s.currentNumber - 1,
            columns: const [
              PlanColumn('Mês'),
              PlanColumn('Meta de economia', numeric: true),
              PlanColumn('Valor já guardado', numeric: true),
              PlanColumn('Quanto guardar', numeric: true),
              PlanColumn('Valor acumulado', numeric: true),
              PlanColumn('Meta acumulada', numeric: true),
            ],
            rows: [
              for (final r in s.rows)
                [
                  Fmt.monthYear(r.month),
                  Fmt.money(r.target),
                  Fmt.money(r.alreadySaved),
                  Fmt.money(r.toSave),
                  Fmt.money(r.accumulated),
                  Fmt.money(r.targetAccumulated),
                ],
            ],
            footer: [
              'TOTAL',
              Fmt.money(s.rows.fold(0.0, (a, r) => a + r.target)),
              Fmt.money(s.rows.fold(0.0, (a, r) => a + r.alreadySaved)),
              Fmt.money(s.rows.fold(0.0, (a, r) => a + r.toSave)),
              '',
              '',
            ],
          ),
        ),
        const HowToRead(
          'Meta de economia = Σ (preço ÷ meses) dos produtos ainda ativos no mês. Valor já guardado = '
          'parte dessa meta coberta pelo que você reservou. Quanto guardar = meta − já guardado. '
          'Valor acumulado = saldo de hoje + o que falta guardar mês a mês. Este cronograma assume '
          'guardar para todos ao mesmo tempo; o mínimo realista por prioridade está em Prioridades.',
        ),
      ];
    });
  }
}
