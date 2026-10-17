import '../../core/utils/month.dart';
import '../models/enums.dart';
import '../models/product.dart';

enum ProductStatus {
  done('Concluído', Signal.good),
  late('Atrasado', Signal.critical),
  soon('Próximo', Signal.info),
  saving('Economizando', Signal.warning);

  const ProductStatus(this.label, this.signal);
  final String label;
  final Signal signal;
}

enum ProductAlertKind { canBuy, late, dueSoon }

class ProductAlert {
  const ProductAlert(this.kind, this.product, {this.daysLeft = 0});
  final ProductAlertKind kind;
  final Product product;
  final int daysLeft;
}

/// Uma linha das abas Produtos (status) + Por Produto (cálculos individuais).
class ProductPlan {
  ProductPlan._({
    required this.product,
    required this.position,
    required this.status,
    required this.monthsLeft,
    required this.perMonth,
    required this.perWeek,
    required this.perDay,
    required this.alert,
  });

  final Product product;

  /// Linha na tabela (desempate final da fila de prioridade).
  final int position;
  final ProductStatus status;

  /// `Meses restantes` (nulo quando o produto não tem data).
  final int? monthsLeft;
  final double? perMonth;
  final double? perWeek;
  final double? perDay;
  final ProductAlert? alert;

  double get remaining => product.remaining;

  /// Coluna auxiliar I: `Preço ÷ meses`.
  double? get priceShare => monthsLeft == null ? null : product.price / monthsLeft!;

  /// Coluna auxiliar J: `MIN(guardado, preço) ÷ meses`.
  double? get savedShare {
    if (monthsLeft == null) return null;
    final saved = product.saved < product.price ? product.saved : product.price;
    return saved / monthsLeft!;
  }

  static ProductPlan build({
    required Product product,
    required int position,
    required DateTime today,
    required DateTime planStart,
    required int planMonths,
    required int daysSoon,
  }) {
    final remaining = product.remaining;
    final target = product.targetDate;
    final daysLeft = target == null ? null : Month.daysBetween(today, target);

    final ProductStatus status;
    if (remaining <= 0) {
      status = ProductStatus.done;
    } else if (daysLeft == null) {
      status = ProductStatus.saving;
    } else if (daysLeft < 0) {
      status = ProductStatus.late;
    } else if (daysLeft <= daysSoon) {
      status = ProductStatus.soon;
    } else {
      status = ProductStatus.saving;
    }

    int? monthsLeft;
    double? perMonth, perWeek, perDay;
    if (target != null) {
      final raw = Month.index(planStart, target);
      monthsLeft = raw.clamp(1, planMonths < 1 ? 1 : planMonths);
      perMonth = remaining / monthsLeft;
      final weeks = (daysLeft! / 7).ceil();
      perWeek = remaining / (weeks < 1 ? 1 : weeks);
      perDay = remaining / (daysLeft < 1 ? 1 : daysLeft);
    }

    ProductAlert? alert;
    if (remaining <= 0) {
      alert = ProductAlert(ProductAlertKind.canBuy, product);
    } else if (daysLeft != null && daysLeft < 0) {
      alert = ProductAlert(ProductAlertKind.late, product);
    } else if (daysLeft != null && daysLeft <= daysSoon) {
      alert = ProductAlert(ProductAlertKind.dueSoon, product, daysLeft: daysLeft);
    }

    return ProductPlan._(
      product: product,
      position: position,
      status: status,
      monthsLeft: monthsLeft,
      perMonth: perMonth,
      perWeek: perWeek,
      perDay: perDay,
      alert: alert,
    );
  }
}
