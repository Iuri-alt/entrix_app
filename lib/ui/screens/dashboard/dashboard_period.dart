import '../../../core/format/formatters.dart';

/// Filtro do painel: um ano inteiro ou um mês específico.
class DashboardPeriod {
  const DashboardPeriod(this.year, [this.month]);

  final int year;

  /// 1–12; nulo = ano todo.
  final int? month;

  bool get isWholeYear => month == null;

  String get label => month == null ? 'Ano de $year' : Fmt.monthYearLong(DateTime(year, month!));

  DashboardPeriod withMonth(int? month) => DashboardPeriod(year, month);

  DashboardPeriod withYear(int year) => DashboardPeriod(year, month);

  @override
  bool operator ==(Object other) =>
      other is DashboardPeriod && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}
