import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../core/utils/month.dart';
import '../../../domain/calc/finance_plan.dart';
import '../../charts/chart_kit.dart';
import '../../widgets/section_card.dart';

/// Mesmo par de cores em todos os visuais de "guardado × falta".
const _savedColor = Color(0xFF199E70);
const _missingColor = Color(0xFF3987E5);

/// Meta total × valor acumulado (gráfico de bala).
class GoalProgressVisual extends StatelessWidget {
  const GoalProgressVisual({super.key, required this.plan});

  final FinancePlan plan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: 'Meta total × valor acumulado',
      subtitle: 'Soma dos produtos que você quer comprar',
      child: plan.totalProducts <= 0
          ? const Text('Cadastre produtos para acompanhar a meta.',
              style: TextStyle(color: AppColors.textMuted))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(Fmt.percent(plan.progress),
                        style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('do objetivo',
                          style: text.bodySmall?.copyWith(color: AppColors.textMuted)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                HorizontalBarRow(
                  label: 'Guardado',
                  valueLabel: '${Fmt.money(plan.totalSaved)} de ${Fmt.money(plan.totalProducts)}',
                  segments: [(plan.totalSaved, _savedColor), (plan.totalMissing, _missingColor)],
                  max: plan.totalProducts,
                ),
                const SizedBox(height: 8),
                const ChartLegend(items: [
                  LegendItem(_savedColor, 'Já guardado'),
                  LegendItem(_missingColor, 'Falta guardar'),
                ]),
                const Divider(height: 28),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    _Figure('Por mês (todos juntos)', Fmt.money(plan.monthlyGoal)),
                    _Figure('Por semana', Fmt.money(plan.weeklyGoal)),
                    _Figure('Por dia', Fmt.money(plan.dailyGoal)),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ChartKit.axisLabel),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}

/// Cronograma: meta de economia × quanto guardar, mês a mês do plano.
class SavingsScheduleChart extends StatelessWidget {
  const SavingsScheduleChart({super.key, required this.plan, this.highlight});

  final FinancePlan plan;
  final DateTime? highlight;

  @override
  Widget build(BuildContext context) {
    final rows = plan.schedule.rows;
    final max = ChartKit.niceMax(rows.fold(0.0, (m, r) => r.target > m ? r.target : m));
    final step = (rows.length / 8).ceil();

    Color tone(Color c, DateTime month) =>
        highlight == null || Month.sameMonth(highlight!, month) ? c : c.withValues(alpha: 0.3);

    return SectionCard(
      title: 'Economia mensal: meta × quanto guardar',
      subtitle: 'Cronograma do plano · ${Fmt.monthYear(plan.planStart)} a ${Fmt.monthYear(plan.planLastMonth)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartLegend(items: [
            LegendItem(ChartColors.series[0], 'Meta de economia'),
            LegendItem(ChartColors.series[1], 'Quanto guardar'),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: max,
                alignment: BarChartAlignment.spaceAround,
                gridData: ChartKit.horizontalGrid(),
                borderData: ChartKit.baseline(),
                titlesData: FlTitlesData(
                  leftTitles: ChartKit.moneyAxis(),
                  rightTitles: ChartKit.hidden(),
                  topTitles: ChartKit.hidden(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i % step != 0) return const SizedBox.shrink();
                        final m = rows[i].month;
                        final label = m.month == 1 || i == 0
                            ? "${Fmt.monthShort[m.month - 1]}/${m.year % 100}"
                            : Fmt.monthShort[m.month - 1];
                        return SideTitleWidget(meta: meta, child: Text(label, style: ChartKit.axisLabel));
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: ChartKit.tooltipColor,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final r = rows[groupIndex];
                      return BarTooltipItem(
                        '${Fmt.monthYear(r.month)}\n',
                        ChartKit.tooltipTitle,
                        textAlign: TextAlign.left,
                        children: [
                          TextSpan(
                            text: 'Meta  ${Fmt.money(r.target)}\n'
                                'Já guardado  ${Fmt.money(r.alreadySaved)}\n'
                                'Quanto guardar  ${Fmt.money(r.toSave)}',
                            style: ChartKit.tooltipBody,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (final (i, r) in rows.indexed)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: [
                        BarChartRodData(
                          toY: r.target,
                          width: rows.length > 18 ? 4 : 7,
                          color: tone(ChartColors.series[0], r.month),
                          borderRadius: ChartKit.barRadius,
                        ),
                        BarChartRodData(
                          toY: r.toSave,
                          width: rows.length > 18 ? 4 : 7,
                          color: tone(ChartColors.series[1], r.month),
                          borderRadius: ChartKit.barRadius,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dinheiro por prioridade (guardado + falta), barras empilhadas.
class PriorityMoneyVisual extends StatelessWidget {
  const PriorityMoneyVisual({super.key, required this.plan});

  final FinancePlan plan;

  @override
  Widget build(BuildContext context) {
    final rows = plan.moneyByPriority;
    final max = rows.fold(0.0, (m, r) => r.saved + r.missing > m ? r.saved + r.missing : m);
    return SectionCard(
      title: 'Dinheiro por prioridade',
      subtitle: 'Já guardado + falta guardar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in rows)
            HorizontalBarRow(
              label: r.priority.label,
              valueLabel: '${Fmt.money(r.saved)} / ${Fmt.money(r.saved + r.missing)}',
              segments: [(r.saved, _savedColor), (r.missing, _missingColor)],
              max: max,
            ),
          const SizedBox(height: 8),
          const ChartLegend(items: [
            LegendItem(_savedColor, 'Já guardado'),
            LegendItem(_missingColor, 'Falta guardar'),
          ]),
        ],
      ),
    );
  }
}

/// Preço de cada produto (10 primeiros), com a parte já guardada.
class ProductPriceVisual extends StatelessWidget {
  const ProductPriceVisual({super.key, required this.plan});

  final FinancePlan plan;

  @override
  Widget build(BuildContext context) {
    final items = plan.products.take(10).toList();
    final max = items.fold(0.0, (m, p) => p.price > m ? p.price : m);
    return SectionCard(
      title: 'Preço de cada produto',
      subtitle: plan.products.length > 10 ? '10 primeiros de ${plan.products.length}' : null,
      child: items.isEmpty
          ? const Text('Nenhum produto cadastrado.', style: TextStyle(color: AppColors.textMuted))
          : Column(
              children: [
                for (final p in items)
                  HorizontalBarRow(
                    label: p.name,
                    valueLabel: Fmt.money(p.price),
                    tooltip: 'Guardado ${Fmt.money(p.price - p.remaining)} · falta ${Fmt.money(p.remaining)}',
                    segments: [(p.price - p.remaining, _savedColor), (p.remaining, _missingColor)],
                    max: max,
                  ),
                const SizedBox(height: 8),
                const ChartLegend(items: [
                  LegendItem(_savedColor, 'Já guardado'),
                  LegendItem(_missingColor, 'Falta guardar'),
                ]),
              ],
            ),
    );
  }
}
