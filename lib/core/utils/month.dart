/// Helpers de data equivalentes às funções do Excel usadas na planilha.
abstract final class Month {
  /// `DATE(YEAR(d), MONTH(d), 1)`.
  static DateTime start(DateTime date) => DateTime(date.year, date.month);

  /// Remove horas/minutos (as datas da planilha não têm hora).
  static DateTime day(DateTime date) => DateTime(date.year, date.month, date.day);

  /// `EDATE(date, months)` para o primeiro dia do mês.
  static DateTime add(DateTime monthStart, int months) =>
      DateTime(monthStart.year, monthStart.month + months);

  /// `EOMONTH(date, months)`.
  static DateTime endOf(DateTime date, int months) =>
      DateTime(date.year, date.month + months + 1, 0);

  /// `(YEAR(b)-YEAR(a))*12 + MONTH(b)-MONTH(a) + 1`: posição 1-based de [b] a partir de [a].
  static int index(DateTime a, DateTime b) =>
      (b.year - a.year) * 12 + b.month - a.month + 1;

  /// Diferença em dias entre duas datas, ignorando horário de verão.
  static int daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays;

  static bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
}

/// `AAAA-MM-DD`, formato trocado com a API.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
