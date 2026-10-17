import '../../core/utils/month.dart';
import '../models/enums.dart';
import 'product_plan.dart';

enum PriorityFit {
  onTime('No prazo', Signal.good),
  late('Não cabe no prazo', Signal.critical),
  noDate('Sem data', Signal.neutral);

  const PriorityFit(this.label, this.signal);
  final String label;
  final Signal signal;
}

/// Resultado de "quando dá para comprar" com uma economia mensal.
sealed class PurchaseMonth {
  const PurchaseMonth();
}

class AlreadyPossible extends PurchaseMonth {
  const AlreadyPossible();
}

class NoSavings extends PurchaseMonth {
  const NoSavings();
}

class InMonth extends PurchaseMonth {
  const InMonth(this.month);
  final DateTime month;
}

/// `ROUNDUP(acumulado ÷ economia)` → mês de compra (sem o teto de 24 meses).
PurchaseMonth purchaseMonth({
  required double cumulative,
  required double monthlySaving,
  required DateTime planStart,
}) {
  if (cumulative <= 0) return const AlreadyPossible();
  if (monthlySaving <= 0) return const NoSavings();
  final months = (cumulative / monthlySaving).ceil();
  return InMonth(Month.add(planStart, months - 1));
}

/// Uma linha da aba Prioridades.
class PriorityRow {
  const PriorityRow({
    required this.order,
    required this.plan,
    required this.cumulative,
    required this.monthsNeeded,
    required this.purchase,
    required this.deadline,
    required this.fit,
    required this.suggestedDate,
    required this.requiredMonthly,
    required this.increaseNeeded,
  });

  final int order;
  final ProductPlan plan;

  /// "Acumulado necessário": soma do que falta deste e dos anteriores na fila.
  final double cumulative;

  /// "Meses necessários" (nulo = sem economia).
  final int? monthsNeeded;
  final PurchaseMonth purchase;

  /// "Prazo (mês)".
  final DateTime? deadline;
  final PriorityFit fit;

  /// "Nova data sugerida": fim do mês possível quando não cabe no prazo.
  final DateTime? suggestedDate;

  /// "Economia/mês p/ cumprir o prazo".
  final double? requiredMonthly;
  final double? increaseNeeded;
}

class PriorityPlan {
  PriorityPlan._(this.rows, this.available);

  final List<PriorityRow> rows;
  final double available;

  /// `MinimoMensal` = maior "economia/mês p/ cumprir o prazo".
  late final double minimumMonthly = rows.fold<double>(
    0,
    (max, r) => (r.requiredMonthly ?? 0) > max ? r.requiredMonthly! : max,
  );

  late final double increaseNeeded =
      minimumMonthly - available > 0 ? minimumMonthly - available : 0;

  int get onTimeCount => rows.where((r) => r.fit == PriorityFit.onTime).length;
  int get lateCount => rows.where((r) => r.fit == PriorityFit.late).length;

  /// Ordem: prioridade (Alta → Baixa), depois data mais próxima (sem data por último),
  /// depois a posição na tabela de produtos.
  static List<ProductPlan> queue(List<ProductPlan> plans) {
    final sorted = [...plans];
    sorted.sort((a, b) {
      final byRank = a.product.priority.rank.compareTo(b.product.priority.rank);
      if (byRank != 0) return byRank;
      final aDate = a.product.targetDate, bDate = b.product.targetDate;
      if (aDate != bDate) {
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      }
      return a.position.compareTo(b.position);
    });
    return sorted;
  }

  static PriorityPlan build({
    required List<ProductPlan> plans,
    required double available,
    required DateTime planStart,
  }) {
    final rows = <PriorityRow>[];
    var cumulative = 0.0;
    var order = 0;
    for (final plan in queue(plans)) {
      order++;
      cumulative += plan.remaining;

      final int? needed = cumulative <= 0
          ? 0
          : available <= 0
              ? null
              : (cumulative / available).ceil();
      final deadlineMonths = plan.monthsLeft;

      final PriorityFit fit;
      if (deadlineMonths == null) {
        fit = PriorityFit.noDate;
      } else if (needed != null && needed <= deadlineMonths) {
        fit = PriorityFit.onTime;
      } else {
        fit = PriorityFit.late;
      }

      final requiredMonthly = deadlineMonths == null
          ? null
          : cumulative <= 0
              ? 0.0
              : cumulative / deadlineMonths;

      rows.add(PriorityRow(
        order: order,
        plan: plan,
        cumulative: cumulative,
        monthsNeeded: needed,
        purchase: purchaseMonth(
          cumulative: cumulative,
          monthlySaving: available,
          planStart: planStart,
        ),
        deadline: deadlineMonths == null ? null : Month.add(planStart, deadlineMonths - 1),
        fit: fit,
        suggestedDate: fit == PriorityFit.late && needed != null
            ? Month.endOf(planStart, needed - 1)
            : null,
        requiredMonthly: requiredMonthly,
        increaseNeeded: requiredMonthly == null
            ? null
            : (requiredMonthly - available > 0 ? requiredMonthly - available : 0),
      ));
    }
    return PriorityPlan._(rows, available);
  }
}
