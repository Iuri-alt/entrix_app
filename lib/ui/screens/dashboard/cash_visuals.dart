import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/format/formatters.dart';
import '../../charts/chart_kit.dart';
import '../../widgets/section_card.dart';
import 'dashboard_data.dart';

/// Receitas × despesas por mês (colunas agrupadas). Tocar num mês filtra o painel.
class IncomeExpenseChart extends StatelessWidget {
  const IncomeExpenseChart({super.key, required this.data, required this.onSelectMonth});

  final DashboardData data;
  final ValueChanged<int?> onSelectMonth;

  @override
  Widget build(BuildContext context) {
    final selected = data.period.month;
    final max = ChartKit.niceMax(
      data.months.fold(0.0, (m, t) => [m, t.income, t.expenses].reduce((a, b) => a > b ? a : b)),
    );

    Color tone(Color base, int month) =>
        selected == null || selected == month ? base : base.withValues(alpha: 0.28);

    return SectionCard(
      title: 'Receitas × despesas por mês',
      subtitle: '${data.period.year} · toque num mês para filtrar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ChartLegend(items: [
            LegendItem(ChartColors.income, 'Receitas'),
            LegendItem(ChartColors.expense, 'Despesas'),
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
                  bottomTitles: ChartKit.labelAxis((i) => Fmt.monthShort[i]),
                ),
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    if (event is! FlTapUpEvent) return;
                    final index = response?.spot?.touchedBarGroupIndex;
                    if (index == null) return;
                    final month = index + 1;
                    onSelectMonth(selected == month ? null : month);
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: ChartKit.tooltipColor,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final totals = data.months[groupIndex];
                      return BarTooltipItem(
                        '${Fmt.monthYear(DateTime(data.period.year, groupIndex + 1))}\n',
                        ChartKit.tooltipTitle,
                        textAlign: TextAlign.left,
                        children: [
                          TextSpan(
                            text: 'Receitas  ${Fmt.money(totals.income)}\n'
                                'Despesas  ${Fmt.money(totals.expenses)}\n'
                                'Saldo  ${Fmt.money(totals.balance)}',
                            style: ChartKit.tooltipBody,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < 12; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: [
                        BarChartRodData(
                          toY: data.months[i].income,
                          width: 7,
                          color: tone(ChartColors.income, i + 1),
                          borderRadius: ChartKit.barRadius,
                        ),
                        BarChartRodData(
                          toY: data.months[i].expenses,
                          width: 7,
                          color: tone(ChartColors.expense, i + 1),
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

/// Saldo acumulado no fim de cada mês do ano.
class AccumulatedBalanceChart extends StatelessWidget {
  const AccumulatedBalanceChart({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final values = data.accumulatedBalance;
    final selected = data.period.month;
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final maxY = ChartKit.niceMax(high > 0 ? high : 1);
    final minY = low < 0 ? -ChartKit.niceMax(-low) : 0.0;

    return SectionCard(
      title: 'Saldo acumulado',
      subtitle: 'Receitas − despesas, somando os meses anteriores',
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            minX: 0,
            maxX: 11,
            gridData: ChartKit.horizontalGrid(),
            borderData: ChartKit.baseline(),
            titlesData: FlTitlesData(
              leftTitles: ChartKit.moneyAxis(),
              rightTitles: ChartKit.hidden(),
              topTitles: ChartKit.hidden(),
              bottomTitles: ChartKit.labelAxis((i) => Fmt.monthShort[i]),
            ),
            extraLinesData: ExtraLinesData(horizontalLines: [
              if (minY < 0) HorizontalLine(y: 0, color: ChartColors.axis, strokeWidth: 1),
            ]),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: ChartKit.tooltipColor,
                fitInsideHorizontally: true,
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    LineTooltipItem(
                      '${Fmt.monthYear(DateTime(data.period.year, spot.x.toInt() + 1))}\n',
                      ChartKit.tooltipTitle,
                      textAlign: TextAlign.left,
                      children: [TextSpan(text: Fmt.money(spot.y), style: ChartKit.tooltipBody)],
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < 12; i++) FlSpot(i.toDouble(), values[i])],
                color: ChartColors.series[0],
                barWidth: 2,
                isCurved: false,
                belowBarData: BarAreaData(
                  show: true,
                  color: ChartColors.series[0].withValues(alpha: 0.12),
                ),
                dotData: FlDotData(
                  checkToShowDot: (spot, _) => selected == null || spot.x.toInt() == selected - 1,
                  getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                    radius: 4,
                    color: ChartColors.series[0],
                    strokeWidth: 2,
                    strokeColor: AppColors.surface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Despesas por categoria (ranking). Mostra 8 categorias e agrupa o resto em "Outras".
class CategoryRanking extends StatelessWidget {
  const CategoryRanking({super.key, required this.data});

  final DashboardData data;
  static const _visible = 8;

  @override
  Widget build(BuildContext context) {
    final items = data.categories;
    // Agrupar uma única categoria em "Outras" não economiza espaço.
    final limit = items.length <= _visible + 1 ? items.length : _visible;
    final shown = items.take(limit).toList();
    final restAmount = items.skip(limit).fold(0.0, (s, c) => s + c.amount);
    final restShare = items.skip(limit).fold(0.0, (s, c) => s + c.share);
    final max = items.isEmpty ? 0.0 : items.first.amount;

    return SectionCard(
      title: 'Despesas por categoria',
      subtitle: data.period.label,
      child: items.isEmpty
          ? const _NoData()
          : Column(
              children: [
                for (final c in shown)
                  HorizontalBarRow(
                    label: c.category,
                    valueLabel: '${Fmt.money(c.amount)} · ${Fmt.percent(c.share)}',
                    segments: [(c.amount, ChartColors.series[0])],
                    max: max,
                  ),
                if (restAmount > 0)
                  HorizontalBarRow(
                    label: 'Outras (${items.length - limit})',
                    valueLabel: '${Fmt.money(restAmount)} · ${Fmt.percent(restShare)}',
                    segments: [(restAmount, ChartColors.dimmed)],
                    max: max > restAmount ? max : restAmount,
                  ),
              ],
            ),
    );
  }
}

/// Composição das despesas por grupo (Fixas, Variáveis, Outros compromissos).
class ExpenseGroupDonut extends StatefulWidget {
  const ExpenseGroupDonut({super.key, required this.data});

  final DashboardData data;

  @override
  State<ExpenseGroupDonut> createState() => _ExpenseGroupDonutState();
}

class _ExpenseGroupDonutState extends State<ExpenseGroupDonut> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final t = widget.data.totals;
    final groups = [
      ('Fixas', t.fixed, ChartColors.series[0]),
      ('Variáveis', t.variable, ChartColors.series[1]),
      ('Outros compromissos', t.other, ChartColors.series[2]),
    ];
    final total = t.expenses;

    return SectionCard(
      title: 'Despesas por grupo',
      subtitle: '${widget.data.period.label} · sem grupo conta como variável',
      child: total <= 0
          ? const _NoData()
          : Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 46,
                          startDegreeOffset: -90,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) => setState(() {
                              _touched = event.isInterestedForInteractions
                                  ? response?.touchedSection?.touchedSectionIndex
                                  : null;
                            }),
                          ),
                          sections: [
                            for (final (i, (_, value, color)) in groups.indexed)
                              PieChartSectionData(
                                value: value <= 0 ? 0.0001 : value,
                                color: color,
                                radius: _touched == i ? 26 : 22,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Total', style: ChartKit.axisLabel),
                          Text(Fmt.compactMoney(total),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, (label, value, color)) in groups.indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: color, borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _touched == i ? FontWeight.w700 : FontWeight.w400,
                                        )),
                                    Text('${Fmt.money(value)} · ${Fmt.percent(value / total)}',
                                        style: ChartKit.axisLabel),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 120,
        child: Center(
          child: Text('Sem despesas no período', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
}
