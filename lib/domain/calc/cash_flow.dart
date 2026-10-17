import '../../core/utils/month.dart';
import '../models/enums.dart';
import '../models/transaction.dart';

/// Totais de um conjunto de lançamentos (um mês, um ano ou qualquer período).
class FlowTotals {
  double income = 0;
  double fixed = 0;
  double other = 0;
  double expenses = 0;
  double pending = 0;
  int count = 0;

  /// Despesa sem grupo entra em "variáveis" (Fluxo!D = total − fixas − outros).
  double get variable => expenses - fixed - other;
  double get balance => income - expenses;
  bool get isEmpty => income + expenses == 0;

  void add(FinanceTransaction t) {
    count++;
    if (t.isIncome) {
      income += t.amount;
      return;
    }
    expenses += t.amount;
    if (t.group == ExpenseGroup.fixed) fixed += t.amount;
    if (t.group == ExpenseGroup.other) other += t.amount;
    if (t.isPending) pending += t.amount;
  }

  static FlowTotals of(Iterable<FinanceTransaction> items) {
    final totals = FlowTotals();
    items.forEach(totals.add);
    return totals;
  }
}

enum MonthSituation {
  empty('Sem lançamentos', Signal.neutral),
  negative('Despesas acima da receita', Signal.critical),
  reached('Meta do mês atingida', Signal.good),
  tight('Meta apertada', Signal.warning),
  below('Abaixo da meta', Signal.critical);

  const MonthSituation(this.label, this.signal);
  final String label;
  final Signal signal;

  /// Fluxo de caixa!J.
  static MonthSituation evaluate(FlowTotals totals, double target, double tightLimit) {
    if (totals.isEmpty) return empty;
    if (totals.balance < 0) return negative;
    if (totals.balance >= target) return reached;
    if (totals.balance >= target * tightLimit) return tight;
    return below;
  }
}

class CashFlowMonth {
  CashFlowMonth(this.month, this.totals, this.accumulated, this.situation);
  final DateTime month;
  final FlowTotals totals;
  final double accumulated;
  final MonthSituation situation;
}

class CategoryTotal {
  CategoryTotal(this.category, this.amount, this.share);
  final String category;
  final double amount;
  final double share;
}

/// Agrupa os lançamentos por mês uma única vez; as consultas reaproveitam o índice.
class CashFlow {
  CashFlow(Iterable<FinanceTransaction> transactions) {
    for (final t in transactions) {
      (_byMonth[_key(t.month)] ??= []).add(t);
    }
  }

  final Map<int, List<FinanceTransaction>> _byMonth = {};
  final Map<int, FlowTotals> _totalsCache = {};

  static int _key(DateTime month) => month.year * 12 + month.month - 1;
  static DateTime _fromKey(int key) => DateTime(key ~/ 12, key % 12 + 1);

  bool get isEmpty => _byMonth.isEmpty;
  DateTime? get firstMonth => isEmpty ? null : _fromKey(_byMonth.keys.reduce((a, b) => a < b ? a : b));
  DateTime? get lastMonth => isEmpty ? null : _fromKey(_byMonth.keys.reduce((a, b) => a > b ? a : b));

  Set<int> get years => _byMonth.keys.map((k) => k ~/ 12).toSet();

  List<FinanceTransaction> transactionsOf(DateTime month) => _byMonth[_key(month)] ?? const [];

  FlowTotals totalsOf(DateTime month) =>
      _totalsCache.putIfAbsent(_key(month), () => FlowTotals.of(transactionsOf(month)));

  Iterable<FinanceTransaction> inYear(int year, {int? month}) sync* {
    for (var m = month ?? 1; m <= (month ?? 12); m++) {
      yield* transactionsOf(DateTime(year, m));
    }
  }

  /// Tabela mês a mês entre [from] e [to] (inclusive), com saldo acumulado.
  List<CashFlowMonth> table({
    required DateTime from,
    required DateTime to,
    required double target,
    required double tightLimit,
  }) {
    final rows = <CashFlowMonth>[];
    var accumulated = 0.0;
    for (var m = Month.start(from); !m.isAfter(to); m = Month.add(m, 1)) {
      final totals = totalsOf(m);
      accumulated += totals.balance;
      rows.add(CashFlowMonth(
        m,
        totals,
        accumulated,
        MonthSituation.evaluate(totals, target, tightLimit),
      ));
    }
    return rows;
  }

  /// "Despesas por categoria": lista configurada + categorias usadas fora dela,
  /// para que a soma bata com o total de despesas.
  static List<CategoryTotal> byCategory(
    Iterable<FinanceTransaction> items,
    List<String> configured,
  ) {
    final sums = <String, double>{for (final c in configured) c: 0};
    var total = 0.0;
    for (final t in items) {
      if (!t.isExpense) continue;
      sums[t.category] = (sums[t.category] ?? 0) + t.amount;
      total += t.amount;
    }
    return [
      for (final e in sums.entries)
        CategoryTotal(e.key, e.value, total == 0 ? 0 : e.value / total),
    ];
  }
}
