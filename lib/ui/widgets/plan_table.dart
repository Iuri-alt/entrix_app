import 'package:flutter/material.dart';

import '../../app/theme.dart';

class PlanColumn {
  const PlanColumn(this.label, {this.numeric = false, this.tooltip});
  final String label;
  final bool numeric;
  final String? tooltip;
}

/// Tabela com rolagem horizontal, no formato das abas da planilha.
class PlanTable extends StatelessWidget {
  const PlanTable({
    super.key,
    required this.columns,
    required this.rows,
    this.highlightRow,
    this.footer,
  });

  final List<PlanColumn> columns;

  /// Cada célula é um texto ou um widget.
  final List<List<Object>> rows;
  final int? highlightRow;
  final List<Object>? footer;

  @override
  Widget build(BuildContext context) {
    const cellStyle = TextStyle(fontSize: 13, fontFeatures: [FontFeature.tabularFigures()]);
    DataCell cell(Object value, {bool bold = false}) => DataCell(
          value is Widget
              ? value
              : Text('$value', style: bold ? cellStyle.copyWith(fontWeight: FontWeight.w700) : cellStyle),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 52,
        columnSpacing: 20,
        horizontalMargin: 12,
        headingTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        columns: [
          for (final c in columns)
            DataColumn(label: Text(c.label), numeric: c.numeric, tooltip: c.tooltip),
        ],
        rows: [
          for (final (i, row) in rows.indexed)
            DataRow(
              color: i == highlightRow
                  ? WidgetStatePropertyAll(AppColors.brand.withValues(alpha: 0.12))
                  : null,
              cells: [for (final value in row) cell(value)],
            ),
          if (footer != null)
            DataRow(
              color: const WidgetStatePropertyAll(AppColors.surfaceRaised),
              cells: [for (final value in footer!) cell(value, bold: true)],
            ),
        ],
      ),
    );
  }
}
