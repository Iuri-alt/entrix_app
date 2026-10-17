import 'package:intl/intl.dart';

abstract final class Fmt {
  static final NumberFormat _money =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);
  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 1,
  );
  static final NumberFormat _percent = NumberFormat.decimalPercentPattern(
    locale: 'pt_BR',
    decimalDigits: 1,
  );

  static const monthNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];
  static const monthShort = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  static final NumberFormat _axis = NumberFormat.compact(locale: 'pt_BR');

  static String money(double value) => _money.format(value);

  /// Rótulo curto para eixos de gráfico ("2,5 mil", "500").
  static String axis(double value) => _axis.format(value);
  static String compactMoney(double value) =>
      value.abs() < 1000 ? _money.format(value) : _compact.format(value);
  static String percent(double ratio) => _percent.format(ratio);

  static String date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// "out/2026".
  static String monthYear(DateTime d) => '${monthShort[d.month - 1]}/${d.year}';

  /// "Outubro de 2026".
  static String monthYearLong(DateTime d) => '${monthNames[d.month - 1]} de ${d.year}';

  /// Lê valores digitados como "1.234,56", "1234.56" ou "R$ 10".
  static double? parseMoney(String input) {
    var text = input.replaceAll(RegExp(r'[^\d,.\-]'), '');
    if (text.isEmpty) return null;
    if (text.contains(',') && text.contains('.')) {
      final decimalIsComma = text.lastIndexOf(',') > text.lastIndexOf('.');
      text = decimalIsComma
          ? text.replaceAll('.', '').replaceAll(',', '.')
          : text.replaceAll(',', '');
    } else if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(text);
  }
}
