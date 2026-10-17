import '../../core/utils/month.dart';
import '../models/enums.dart';
import '../models/plan_settings.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import 'cash_flow.dart';
import 'income_plan.dart';
import 'priority_plan.dart';
import 'product_plan.dart';
import 'savings_schedule.dart';
import 'simulation.dart';

class PriorityMoney {
  const PriorityMoney(this.priority, this.saved, this.missing);
  final Priority priority;
  final double saved;
  final double missing;
}

/// Todas as abas calculadas a partir de Config, Produtos e Lançamentos.
///
/// Imutável: cada alteração de dados gera um novo plano. Os blocos são `late final`,
/// então só o que a tela usa é calculado, e uma única vez.
class FinancePlan {
  FinancePlan({
    required this.settings,
    required List<Product> products,
    required List<FinanceTransaction> transactions,
    DateTime? now,
  })  : products = List.unmodifiable(products),
        transactions = List.unmodifiable(transactions),
        today = settings.today(now);

  final PlanSettings settings;
  final List<Product> products;
  final List<FinanceTransaction> transactions;

  /// `Hoje`.
  final DateTime today;

  int get planMonths => settings.planMonths;
  DateTime get planStart => settings.planStart;
  DateTime get planLastMonth => Month.add(planStart, planMonths - 1);

  // ---------- Produtos / Por Produto ----------
  late final List<ProductPlan> productPlans = [
    for (var i = 0; i < products.length; i++)
      ProductPlan.build(
        product: products[i],
        position: i,
        today: today,
        planStart: planStart,
        planMonths: planMonths,
        daysSoon: settings.daysSoon,
      ),
  ];

  // ---------- Resumo financeiro ----------
  late final double totalProducts = products.fold(0.0, (s, p) => s + p.price);
  late final double totalMissing = products.fold(0.0, (s, p) => s + p.remaining);

  /// "Total que já tenho guardado" (o excedente acima do preço não conta).
  double get totalSaved => totalProducts - totalMissing;

  /// `MetaMensal`: guardando para todos os produtos ao mesmo tempo.
  late final double monthlyGoal = _sum((p) => p.perMonth);
  late final double weeklyGoal = _sum((p) => p.perWeek);
  late final double dailyGoal = _sum((p) => p.perDay);

  double get progress => totalProducts == 0 ? 0 : totalSaved / totalProducts;

  double _sum(double? Function(ProductPlan) pick) =>
      productPlans.fold(0.0, (s, p) => s + (pick(p) ?? 0));

  late final List<PriorityMoney> moneyByPriority = [
    for (final priority in Priority.values)
      () {
        final items = products.where((p) => p.priority == priority);
        final price = items.fold(0.0, (s, p) => s + p.price);
        final missing = items.fold(0.0, (s, p) => s + p.remaining);
        return PriorityMoney(priority, price - missing, missing);
      }(),
  ];

  // ---------- Lançamentos / Fluxo de caixa ----------
  late final CashFlow cashFlow = CashFlow(transactions);

  /// Meses do plano (Fluxo de caixa da planilha).
  late final List<CashFlowMonth> planCashFlow = cashFlow.table(
    from: planStart,
    to: planLastMonth,
    target: minimumMonthly,
    tightLimit: settings.tightLimit,
  );

  /// `MesAtual`.
  DateTime get currentPlanMonth => schedule.currentRow.month;

  // ---------- Renda / Prioridades / Cronograma / Simulação ----------
  late final IncomePlan income = IncomePlan.build(
    settings: settings,
    planMonths: cashFlow.table(
      from: planStart,
      to: planLastMonth,
      target: 0,
      tightLimit: settings.tightLimit,
    ),
    today: today,
  );

  /// `Disponivel`.
  double get available => income.available;

  late final PriorityPlan priorities = PriorityPlan.build(
    plans: productPlans,
    available: available,
    planStart: planStart,
  );

  /// `MinimoMensal`.
  double get minimumMonthly => priorities.minimumMonthly;

  late final SavingsSchedule schedule = SavingsSchedule.build(
    plans: productPlans,
    planStart: planStart,
    planMonths: planMonths,
    today: today,
    totalSaved: totalSaved,
  );

  late final List<Scenario> scenarios = [
    for (final value in [...settings.scenarios, available])
      Scenario.build(
        monthlySaving: value,
        priorities: priorities,
        planMonths: planMonths,
        totalSaved: totalSaved,
        totalMissing: totalMissing,
        planStart: planStart,
      ),
  ];

  IncomeSituation get incomeSituation =>
      income.situation(minimum: minimumMonthly, totalMissing: totalMissing);

  List<ProductAlert> get productAlerts =>
      [for (final p in productPlans) if (p.alert != null) p.alert!];

  /// Anos com dados ou cobertos pelo plano (filtro do painel).
  late final List<int> availableYears = () {
    final years = {...cashFlow.years, today.year};
    for (var y = planStart.year; y <= planLastMonth.year; y++) {
      years.add(y);
    }
    return years.toList()..sort();
  }();
}
