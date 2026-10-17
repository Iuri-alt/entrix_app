import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format/formatters.dart';

/// Estilo comum dos visuais: grade discreta, eixos recessivos, tooltip escuro.
abstract final class ChartKit {
  static const axisLabel = TextStyle(color: AppColors.textMuted, fontSize: 11);
  static const tooltipTitle = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
    fontSize: 12,
  );
  static const tooltipBody = TextStyle(color: AppColors.textSecondary, fontSize: 12);

  static FlGridData horizontalGrid() => FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(color: ChartColors.grid, strokeWidth: 1),
      );

  static FlBorderData baseline() => FlBorderData(
        show: true,
        border: const Border(bottom: BorderSide(color: ChartColors.axis)),
      );

  static AxisTitles hidden() => const AxisTitles(sideTitles: SideTitles(showTitles: false));

  static AxisTitles moneyAxis({double reserved = 44}) => AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: reserved,
          getTitlesWidget: (value, meta) {
            if (value == meta.max && meta.max != meta.min) return const SizedBox.shrink();
            return SideTitleWidget(
              meta: meta,
              child: Text(Fmt.axis(value), style: axisLabel, maxLines: 1),
            );
          },
        ),
      );

  static AxisTitles labelAxis(String Function(int index) label, {double reserved = 24}) =>
      AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: reserved,
          interval: 1,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(label(value.toInt()), style: axisLabel),
          ),
        ),
      );

  static Color tooltipColor(_) => AppColors.surfaceRaised;

  /// Arredonda o topo do eixo para um valor "redondo".
  static double niceMax(double value) {
    if (value <= 0) return 1;
    final magnitude = _pow10((value).toStringAsFixed(0).length - 1);
    final step = magnitude / 2;
    return ((value / step).ceil() * step).toDouble();
  }

  static double _pow10(int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  static const barRadius = BorderRadius.vertical(top: Radius.circular(4));
  static const barRadiusHorizontal = BorderRadius.horizontal(right: Radius.circular(4));
}

class LegendItem {
  const LegendItem(this.color, this.label);
  final Color color;
  final String label;
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.items});

  final List<LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 6),
              Text(item.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
      ],
    );
  }
}

/// Barra horizontal com rótulo e valor (usada em rankings: categorias, produtos).
class HorizontalBarRow extends StatelessWidget {
  const HorizontalBarRow({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.segments,
    required this.max,
    this.onTap,
    this.tooltip,
  });

  final String label;
  final String valueLabel;

  /// Segmentos empilhados (valor, cor), da esquerda para a direita.
  final List<(double, Color)> segments;
  final double max;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 8),
              Text(valueLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  )),
            ],
          ),
          const SizedBox(height: 5),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final visible = segments.where((s) => s.$1 > 0).length;
            final usable = width - (visible > 1 ? (visible - 1) * 2 : 0);
            return Container(
              height: 10,
              width: width,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  for (final (i, (value, color)) in segments.indexed)
                    if (value > 0)
                      Container(
                        width: max <= 0 ? 0 : (value / max * usable).clamp(0, usable),
                        margin: EdgeInsets.only(right: i < segments.length - 1 ? 2 : 0),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: i == segments.length - 1 || segments.length == 1
                              ? const BorderRadius.horizontal(right: Radius.circular(4))
                              : null,
                        ),
                      ),
                ],
              ),
            );
          }),
        ],
      ),
    );
    final interactive = onTap == null
        ? row
        : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: row);
    return tooltip == null ? interactive : Tooltip(message: tooltip!, child: interactive);
  }
}
