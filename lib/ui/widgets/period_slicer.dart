import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format/formatters.dart';

/// Filtro de período (ano + mês) no estilo "segmentação de dados" do Power BI.
class PeriodSlicer extends StatefulWidget {
  const PeriodSlicer({
    super.key,
    required this.year,
    required this.month,
    required this.years,
    required this.onChanged,
  });

  final int year;

  /// Nulo = ano todo.
  final int? month;
  final List<int> years;
  final void Function(int year, int? month) onChanged;

  @override
  State<PeriodSlicer> createState() => _PeriodSlicerState();
}

class _PeriodSlicerState extends State<PeriodSlicer> {
  /// Índice 0 = "Ano todo", 1–12 = meses.
  final _chipKeys = List.generate(13, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _revealSelected();
  }

  @override
  void didUpdateWidget(PeriodSlicer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month) _revealSelected();
  }

  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _chipKeys[widget.month ?? 0].currentContext;
      if (chip != null && chip.mounted) {
        Scrollable.ensureVisible(chip,
            alignment: 0.5, duration: const Duration(milliseconds: 200));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final years = widget.years;
    final year = widget.year;
    final first = years.isEmpty ? year : years.first;
    final last = years.isEmpty ? year : years.last;
    final roomy = MediaQuery.sizeOf(context).width >= 600;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          if (roomy)
            IconButton(
              tooltip: 'Ano anterior',
              visualDensity: VisualDensity.compact,
              onPressed: () => widget.onChanged(year - 1, widget.month),
              icon: const Icon(Icons.chevron_left_rounded),
            )
          else
            const SizedBox(width: 12),
          PopupMenuButton<int>(
            tooltip: 'Escolher ano',
            initialValue: year,
            onSelected: (y) => widget.onChanged(y, widget.month),
            itemBuilder: (_) => [
              for (var y = (last > year ? last : year) + 1; y >= (first < year ? first : year) - 5; y--)
                PopupMenuItem(value: y, child: Text('$y')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$year', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Icon(Icons.arrow_drop_down_rounded, size: 20),
                ],
              ),
            ),
          ),
          if (roomy)
            IconButton(
              tooltip: 'Próximo ano',
              visualDensity: VisualDensity.compact,
              onPressed: () => widget.onChanged(year + 1, widget.month),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(0, 'Ano todo', widget.month == null, () => widget.onChanged(year, null)),
                  for (var m = 1; m <= 12; m++)
                    _chip(
                      m,
                      Fmt.monthShort[m - 1],
                      widget.month == m,
                      () => widget.onChanged(year, widget.month == m ? null : m),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(int index, String label, bool selected, VoidCallback onTap) => Padding(
        key: _chipKeys[index],
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.brand,
          labelStyle: TextStyle(
            color: selected ? AppColors.onBrand : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          visualDensity: VisualDensity.compact,
        ),
      );
}
