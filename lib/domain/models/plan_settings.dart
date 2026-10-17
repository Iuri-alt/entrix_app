import '../../core/utils/month.dart';
import 'enums.dart';

/// Abas Config, Renda (orçamento previsto) e Simulação (cenários).
class PlanSettings {
  PlanSettings({
    this.todayOverride,
    required DateTime planStart,
    required this.planEnd,
    this.daysSoon = 30,
    this.tightLimit = 0.7,
    this.budgetIncome = 0,
    this.budgetFixed = 0,
    this.budgetVariable = 0,
    this.budgetOther = 0,
    this.planBase = PlanBase.forecast,
    this.scenarios = const [300, 500, 700, 1000],
    this.productCategories = const [],
    this.incomeCategories = const [],
    this.expenseCategories = const [],
  }) : planStart = Month.start(planStart);

  final DateTime? todayOverride;
  final DateTime planStart;
  final DateTime planEnd;
  final int daysSoon;
  final double tightLimit;
  final double budgetIncome;
  final double budgetFixed;
  final double budgetVariable;
  final double budgetOther;
  final PlanBase planBase;
  final List<double> scenarios;
  final List<String> productCategories;
  final List<String> incomeCategories;
  final List<String> expenseCategories;

  /// `Hoje` (Config!B4): data digitada ou a data do dia.
  DateTime today([DateTime? now]) => Month.day(todayOverride ?? now ?? DateTime.now());

  /// `MesesPlano` (Config!B9) sem o teto de 24 meses da planilha.
  int get planMonths {
    final months = Month.index(planStart, planEnd);
    return months < 1 ? 1 : months;
  }

  /// "Dinheiro disponível para economia (previsto)" = renda − gastos previstos.
  double get forecastAvailable =>
      budgetIncome - budgetFixed - budgetVariable - budgetOther;

  List<String> categoriesFor(TransactionKind kind) =>
      kind == TransactionKind.income ? incomeCategories : expenseCategories;

  factory PlanSettings.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        json[key] == null ? null : DateTime.parse(json[key] as String);
    double number(String key) => (json[key] as num? ?? 0).toDouble();
    List<String> strings(String key) =>
        (json[key] as List<dynamic>? ?? const []).cast<String>();

    return PlanSettings(
      todayOverride: date('today_override'),
      planStart: date('plan_start')!,
      planEnd: date('plan_end')!,
      daysSoon: json['days_soon'] as int? ?? 30,
      tightLimit: number('tight_limit'),
      budgetIncome: number('budget_income'),
      budgetFixed: number('budget_fixed'),
      budgetVariable: number('budget_variable'),
      budgetOther: number('budget_other'),
      planBase: PlanBase.fromCode(json['plan_base'] as String? ?? 'forecast'),
      scenarios: (json['scenarios'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toDouble())
          .toList(),
      productCategories: strings('product_categories'),
      incomeCategories: strings('income_categories'),
      expenseCategories: strings('expense_categories'),
    );
  }

  Map<String, dynamic> toJson() => {
        'today_override': todayOverride == null ? null : isoDate(todayOverride!),
        'plan_start': isoDate(planStart),
        'plan_end': isoDate(planEnd),
        'days_soon': daysSoon,
        'tight_limit': tightLimit,
        'budget_income': budgetIncome,
        'budget_fixed': budgetFixed,
        'budget_variable': budgetVariable,
        'budget_other': budgetOther,
        'plan_base': planBase.code,
        'scenarios': scenarios,
        'product_categories': productCategories,
        'income_categories': incomeCategories,
        'expense_categories': expenseCategories,
      };

  PlanSettings copyWith({
    DateTime? todayOverride,
    bool clearTodayOverride = false,
    DateTime? planStart,
    DateTime? planEnd,
    int? daysSoon,
    double? tightLimit,
    double? budgetIncome,
    double? budgetFixed,
    double? budgetVariable,
    double? budgetOther,
    PlanBase? planBase,
    List<double>? scenarios,
    List<String>? productCategories,
    List<String>? incomeCategories,
    List<String>? expenseCategories,
  }) =>
      PlanSettings(
        todayOverride: clearTodayOverride ? null : todayOverride ?? this.todayOverride,
        planStart: planStart ?? this.planStart,
        planEnd: planEnd ?? this.planEnd,
        daysSoon: daysSoon ?? this.daysSoon,
        tightLimit: tightLimit ?? this.tightLimit,
        budgetIncome: budgetIncome ?? this.budgetIncome,
        budgetFixed: budgetFixed ?? this.budgetFixed,
        budgetVariable: budgetVariable ?? this.budgetVariable,
        budgetOther: budgetOther ?? this.budgetOther,
        planBase: planBase ?? this.planBase,
        scenarios: scenarios ?? this.scenarios,
        productCategories: productCategories ?? this.productCategories,
        incomeCategories: incomeCategories ?? this.incomeCategories,
        expenseCategories: expenseCategories ?? this.expenseCategories,
      );
}
