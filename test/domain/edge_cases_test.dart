import 'package:entrix/core/format/formatters.dart';
import 'package:entrix/domain/calc/cash_flow.dart';
import 'package:entrix/domain/calc/finance_plan.dart';
import 'package:entrix/domain/calc/income_plan.dart';
import 'package:entrix/domain/calc/priority_plan.dart';
import 'package:entrix/domain/calc/product_plan.dart';
import 'package:entrix/domain/calc/simulation.dart';
import 'package:entrix/domain/models/enums.dart';
import 'package:entrix/domain/models/plan_settings.dart';
import 'package:entrix/domain/models/product.dart';
import 'package:entrix/domain/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 10, 17);
final _settings = PlanSettings(planStart: DateTime(2026, 10), planEnd: DateTime(2027, 12, 31));

FinancePlan _plan({
  PlanSettings? settings,
  List<Product> products = const [],
  List<FinanceTransaction> transactions = const [],
}) =>
    FinancePlan(
      settings: settings ?? _settings,
      products: products,
      transactions: transactions,
      now: _today,
    );

FinanceTransaction _expense(DateTime date, double amount, {ExpenseGroup? group}) => FinanceTransaction(
      date: date,
      description: 'x',
      kind: TransactionKind.expense,
      group: group,
      category: 'Outros',
      amount: amount,
    );

void main() {
  group('sem dados', () {
    test('tudo zerado, sem divisões por zero', () {
      final plan = _plan();
      expect(plan.totalProducts, 0);
      expect(plan.progress, 0);
      expect(plan.minimumMonthly, 0);
      expect(plan.monthlyGoal, 0);
      expect(plan.priorities.rows, isEmpty);
      expect(plan.schedule.rows, hasLength(15));
      expect(plan.schedule.onTrack, isTrue);
      expect(plan.income.realizedAverage, isNull);
      expect(plan.incomeSituation, IncomeSituation.noGoal);
      expect(plan.planCashFlow.every((m) => m.situation == MonthSituation.empty), isTrue);
      expect(plan.scenarios.every((s) => s.outcome == ScenarioOutcome.buysAll), isTrue);
    });
  });

  group('produtos', () {
    test('concluído, atrasado e sem data', () {
      final plan = _plan(products: [
        Product(name: 'Pago', price: 100, saved: 150, targetDate: DateTime(2027, 1, 1)),
        Product(name: 'Atrasado', price: 300, targetDate: DateTime(2026, 9, 1)),
        Product(name: 'Sem data', price: 50),
      ]);
      final [done, late, noDate] = plan.productPlans;

      expect(done.status, ProductStatus.done);
      expect(done.remaining, 0);
      expect(done.alert!.kind, ProductAlertKind.canBuy);

      // Atrasado conta como 1 mês/semana/dia: guardar tudo já.
      expect(late.status, ProductStatus.late);
      expect(late.monthsLeft, 1);
      expect(late.perMonth, 300);
      expect(late.perWeek, 300);
      expect(late.perDay, 300);
      expect(late.alert!.kind, ProductAlertKind.late);

      expect(noDate.status, ProductStatus.saving);
      expect(noDate.monthsLeft, isNull);
      expect(noDate.perMonth, isNull);

      // O excedente guardado acima do preço não conta.
      expect(plan.totalSaved, 100);
      expect(plan.totalMissing, 350);
      // Produto sem data fica fora do cronograma.
      expect(plan.schedule.rows.first.target, 100 / 4 + 300);

      final noDateRow = plan.priorities.rows.firstWhere((r) => r.plan.product.name == 'Sem data');
      expect(noDateRow.fit, PriorityFit.noDate);
      expect(noDateRow.requiredMonthly, isNull);
    });

    test('data além do prazo final conta como o prazo final', () {
      final plan = _plan(products: [Product(name: 'Longe', price: 1500, targetDate: DateTime(2030, 1, 1))]);
      expect(plan.productPlans.single.monthsLeft, 15);
    });

    test('prioridade: com economia suficiente tudo cabe no prazo', () {
      final plan = _plan(
        settings: _settings.copyWith(budgetIncome: 5000, budgetFixed: 1000),
        products: [
          Product(name: 'A', price: 1000, priority: Priority.low, targetDate: DateTime(2026, 12, 1)),
          Product(name: 'B', price: 2000, priority: Priority.high, targetDate: DateTime(2027, 3, 1)),
        ],
      );
      expect(plan.available, 4000);
      expect(plan.priorities.rows.map((r) => r.plan.product.name), ['B', 'A']);
      expect(plan.priorities.rows.every((r) => r.fit == PriorityFit.onTime), isTrue);
      expect((plan.priorities.rows.first.purchase as InMonth).month, DateTime(2026, 10));
      expect(plan.incomeSituation, IncomeSituation.possible);
      expect(plan.priorities.increaseNeeded, 0);
    });

    test('nova data sugerida = fim do mês possível', () {
      final plan = _plan(
        settings: _settings.copyWith(budgetIncome: 100),
        products: [Product(name: 'A', price: 1000, targetDate: DateTime(2026, 11, 1))],
      );
      final row = plan.priorities.rows.single;
      expect(row.fit, PriorityFit.late);
      expect(row.monthsNeeded, 10);
      expect(row.suggestedDate, DateTime(2027, 7, 31));
    });
  });

  group('lançamentos', () {
    test('despesa sem grupo entra em variáveis', () {
      final t = FlowTotals.of([
        _expense(DateTime(2026, 10, 1), 100, group: ExpenseGroup.fixed),
        _expense(DateTime(2026, 10, 2), 40),
        _expense(DateTime(2026, 10, 3), 10, group: ExpenseGroup.other),
      ]);
      expect(t.fixed, 100);
      expect(t.variable, 40);
      expect(t.other, 10);
    });

    test('meses e anos anteriores ao plano aparecem no histórico, não na média do plano', () {
      final plan = _plan(
        settings: _settings.copyWith(planBase: PlanBase.actual),
        transactions: [_expense(DateTime(2019, 3, 15), 500)],
      );
      expect(plan.cashFlow.firstMonth, DateTime(2019, 3));
      expect(plan.availableYears.first, 2019);
      expect(plan.cashFlow.totalsOf(DateTime(2019, 3)).expenses, 500);
      expect(plan.income.realizedAverage, isNull);
      expect(plan.planCashFlow.first.accumulated, 0);
    });

    test('meta apertada usa o limite configurado', () {
      final totals = FlowTotals.of([
        FinanceTransaction(
          date: DateTime(2026, 10, 1),
          description: 'Salário',
          kind: TransactionKind.income,
          category: 'Salário',
          amount: 80,
        ),
      ]);
      expect(MonthSituation.evaluate(totals, 100, 0.7), MonthSituation.tight);
      expect(MonthSituation.evaluate(totals, 100, 0.9), MonthSituation.below);
      expect(MonthSituation.evaluate(totals, 80, 0.7), MonthSituation.reached);
    });

    test('20 mil lançamentos: cálculo completo rápido', () {
      final items = [
        for (var i = 0; i < 20000; i++) _expense(DateTime(2020 + i % 8, 1 + i % 12, 1 + i % 28), 10.0 + i % 50),
      ];
      final watch = Stopwatch()..start();
      final plan = _plan(transactions: items);
      plan.planCashFlow;
      plan.income;
      for (final y in plan.availableYears) {
        for (var m = 1; m <= 12; m++) {
          plan.cashFlow.totalsOf(DateTime(y, m));
        }
      }
      watch.stop();
      final total = plan.cashFlow.years.fold(
        0.0,
        (s, y) => s + FlowTotals.of(plan.cashFlow.inYear(y)).expenses,
      );
      expect(total, closeTo(items.fold(0.0, (s, t) => s + t.amount), 1e-6));
      expect(watch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('sem teto de 24 meses', () {
    test('plano de 6 anos', () {
      final settings = _settings.copyWith(planEnd: DateTime(2032, 9, 30));
      expect(settings.planMonths, 72);
      final plan = _plan(settings: settings, products: [Product(name: 'A', price: 7200, targetDate: DateTime(2032, 9, 1))]);
      expect(plan.schedule.rows, hasLength(72));
      expect(plan.productPlans.single.perMonth, 100);
    });
  });

  group('formatação e JSON', () {
    test('parseMoney aceita formatos brasileiros e americanos', () {
      expect(Fmt.parseMoney('1.234,56'), 1234.56);
      expect(Fmt.parseMoney('1234.56'), 1234.56);
      expect(Fmt.parseMoney('R\$ 2,568.19'), 2568.19);
      expect(Fmt.parseMoney('10'), 10);
      expect(Fmt.parseMoney(''), isNull);
    });

    test('lançamento e produto ida e volta', () {
      final t = FinanceTransaction(
        id: 3,
        date: DateTime(2019, 3, 15),
        description: 'IPVA',
        kind: TransactionKind.income,
        group: ExpenseGroup.fixed,
        category: 'Outras receitas',
        amount: 10.5,
        status: PaymentStatus.pending,
      );
      final json = {...t.toJson(), 'id': 3};
      expect(json['expense_group'], isNull, reason: 'receita não tem grupo');
      final back = FinanceTransaction.fromJson(json);
      expect(back.date, DateTime(2019, 3, 15));
      expect(back.status, PaymentStatus.pending);

      final p = Product(name: 'X', price: 10, targetDate: DateTime(2027, 1, 10), priority: Priority.high);
      final pBack = Product.fromJson({...p.toJson(), 'id': 1});
      expect(pBack.targetDate, DateTime(2027, 1, 10));
      expect(pBack.priority, Priority.high);
    });
  });
}
