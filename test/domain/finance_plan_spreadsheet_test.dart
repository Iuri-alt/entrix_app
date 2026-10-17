import 'package:entrix/domain/calc/cash_flow.dart';
import 'package:entrix/domain/calc/finance_plan.dart';
import 'package:entrix/domain/calc/income_plan.dart';
import 'package:entrix/domain/calc/priority_plan.dart';
import 'package:entrix/domain/calc/product_plan.dart';
import 'package:entrix/domain/calc/simulation.dart';
import 'package:entrix/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spreadsheet_fixture.dart';

/// Cada `expect` compara com o valor que o Excel calculou na planilha original.
void main() {
  late FinancePlan plan;
  const eps = 1e-6;

  setUp(() {
    plan = FinancePlan(
      settings: spreadsheetSettings,
      products: spreadsheetProducts,
      transactions: spreadsheetTransactions,
      now: spreadsheetToday,
    );
  });

  group('Config', () {
    test('MesesPlano = 15', () => expect(plan.planMonths, 15));
  });

  group('Produtos', () {
    test('Falta guardar e Status', () {
      final rows = plan.productPlans;
      expect(rows.map((p) => p.remaining), [5890, 1020, 260, 450, 2000, 1000]);
      expect(rows.map((p) => p.status), [
        ProductStatus.saving,
        ProductStatus.soon,
        ProductStatus.soon,
        ProductStatus.soon,
        ProductStatus.saving,
        ProductStatus.saving,
      ]);
    });
  });

  group('Por Produto', () {
    test('meses, guardar por mês/semana/dia', () {
      final korg = plan.productPlans[0];
      expect(korg.monthsLeft, 4);
      expect(korg.perMonth, closeTo(1472.5, eps));
      expect(korg.perWeek, closeTo(453.0769230769231, eps));
      expect(korg.perDay, closeTo(69.29411764705883, eps));
      expect(korg.priceShare, closeTo(1500, eps));
      expect(korg.savedShare, closeTo(27.5, eps));

      final ryzen = plan.productPlans[1];
      expect(ryzen.monthsLeft, 2);
      expect(ryzen.perMonth, closeTo(510, eps));
      expect(ryzen.perWeek, closeTo(255, eps));
      expect(ryzen.perDay, closeTo(42.5, eps));

      expect(plan.productPlans.map((p) => p.monthsLeft), [4, 2, 2, 2, 4, 3]);
    });

    test('alertas: produtos que vencem em 24 dias', () {
      final alerts = plan.productAlerts;
      expect(alerts.map((a) => a.product.name), ['Ryzen 7 5200x', 'Seminario Jian', 'Estante Bateria']);
      expect(alerts.every((a) => a.kind == ProductAlertKind.dueSoon && a.daysLeft == 24), isTrue);
    });
  });

  group('Resumo', () {
    test('totais', () {
      expect(plan.totalProducts, 10730);
      expect(plan.totalSaved, 110);
      expect(plan.totalMissing, 10620);
      expect(plan.monthlyGoal, closeTo(3170.8333333333335, eps));
      expect(plan.weeklyGoal, closeTo(1164.423076923077, eps));
      expect(plan.dailyGoal, closeTo(183.42538126361654, eps));
      expect(plan.progress, closeTo(0.010251630941286114, eps));
      expect(plan.minimumMonthly, closeTo(2655, eps));
    });

    test('dinheiro por prioridade', () {
      final byPriority = {for (final m in plan.moneyByPriority) m.priority: m};
      expect(byPriority[Priority.high]!.saved, 0);
      expect(byPriority[Priority.high]!.missing, 4020);
      expect(byPriority[Priority.medium]!.saved, 110);
      expect(byPriority[Priority.medium]!.missing, 6600);
      expect(byPriority[Priority.low]!.missing, 0);
    });

    test('mês atual', () {
      expect(plan.currentPlanMonth, DateTime(2026, 10));
      final october = plan.cashFlow.totalsOf(DateTime(2026, 10));
      expect(october.income, closeTo(2668.19, eps));
      expect(october.expenses, closeTo(2645.33, eps));
      expect(october.balance, closeTo(22.86, 1e-9));
      expect(october.pending, closeTo(420, eps));
    });
  });

  group('Fluxo de caixa', () {
    test('outubro/2026', () {
      final row = plan.planCashFlow.first;
      expect(row.month, DateTime(2026, 10));
      expect(row.totals.fixed, closeTo(922.16, eps));
      expect(row.totals.variable, closeTo(937.18, eps));
      expect(row.totals.other, closeTo(785.99, eps));
      expect(row.accumulated, closeTo(22.86, 1e-9));
      expect(row.situation, MonthSituation.below);
    });

    test('meses sem lançamento e saldo acumulado', () {
      expect(plan.planCashFlow, hasLength(15));
      final december2027 = plan.planCashFlow.last;
      expect(december2027.month, DateTime(2027, 12));
      expect(december2027.situation, MonthSituation.empty);
      expect(december2027.accumulated, closeTo(22.86, 1e-9));
    });

    test('despesas por categoria', () {
      final byCategory = {
        for (final c in CashFlow.byCategory(spreadsheetTransactions, spreadsheetSettings.expenseCategories))
          c.category: c.amount,
      };
      expect(byCategory['Alimentação'], closeTo(28.99, eps));
      expect(byCategory['Transporte'], closeTo(77.99, eps));
      expect(byCategory['Educação'], closeTo(270.17, eps));
      expect(byCategory['Lazer'], closeTo(380, eps));
      expect(byCategory['Assinaturas'], closeTo(126, eps));
      expect(byCategory['Cartão/Dívidas'], closeTo(1359.19, eps));
      expect(byCategory['Presentes e doações'], closeTo(169.99, eps));
      expect(byCategory['Outros'], closeTo(33, eps));
      // Divergência intencional: a planilha soma 2.445,33 porque ignora a despesa
      // "Aluguel garagem" lançada com a categoria de receita "Outras receitas".
      expect(byCategory['Outras receitas'], closeTo(200, eps));
      expect(byCategory.values.fold(0.0, (a, b) => a + b), closeTo(2645.33, eps));
    });
  });

  group('Renda', () {
    test('média realizada, disponível e situação', () {
      expect(plan.income.realizedAverage, closeTo(22.86, 1e-9));
      expect(plan.available, 0);
      expect(plan.income.shortfall(plan.minimumMonthly), closeTo(2655, eps));
      expect(plan.incomeSituation, IncomeSituation.impossible);
    });
  });

  group('Prioridades', () {
    test('fila, acumulado e economia necessária', () {
      final rows = plan.priorities.rows;
      expect(rows.map((r) => r.plan.product.name), [
        'Ryzen 7 5200x', 'Roupa', 'Memoria RAM', 'Seminario Jian', 'Estante Bateria', 'Korg Kronos 2',
      ]);
      expect(rows.map((r) => r.cumulative), [1020, 2020, 4020, 4280, 4730, 10620]);
      expect(rows.map((r) => r.deadline), [
        DateTime(2026, 11), DateTime(2026, 12), DateTime(2027, 1),
        DateTime(2026, 11), DateTime(2026, 11), DateTime(2027, 1),
      ]);
      expect(rows[0].requiredMonthly, closeTo(510, eps));
      expect(rows[1].requiredMonthly, closeTo(673.3333333333334, eps));
      expect(rows.every((r) => r.fit == PriorityFit.late), isTrue);
      expect(rows.every((r) => r.purchase is NoSavings), isTrue);
      expect(plan.priorities.onTimeCount, 0);
      expect(plan.priorities.lateCount, 6);
      expect(plan.priorities.increaseNeeded, closeTo(2655, eps));
    });
  });

  group('Cronograma', () {
    test('meta, já guardado, quanto guardar e acumulados', () {
      final rows = plan.schedule.rows;
      expect(rows, hasLength(15));
      expect(rows.take(5).map((r) => r.target).toList(),
          [for (final v in [3198.3333333333335, 3198.3333333333335, 2333.3333333333335, 2000, 0]) closeTo(v, eps)]);
      expect(rows.take(4).map((r) => r.toSave).toList(),
          [for (final v in [3170.8333333333335, 3170.8333333333335, 2305.8333333333335, 1972.5]) closeTo(v, eps)]);
      expect(rows.take(4).map((r) => r.accumulated).toList(),
          [for (final v in [3280.8333333333335, 6451.666666666667, 8757.5, 10730]) closeTo(v, eps)]);
      expect(rows.take(4).map((r) => r.targetAccumulated).toList(),
          [for (final v in [3198.3333333333335, 6396.666666666667, 8730, 10730]) closeTo(v, eps)]);
      expect(rows.fold(0.0, (s, r) => s + r.target), closeTo(10730, eps));
      expect(rows.fold(0.0, (s, r) => s + r.alreadySaved), closeTo(110, eps));
      expect(rows.fold(0.0, (s, r) => s + r.toSave), closeTo(10620, eps));
    });

    test('acompanhamento', () {
      expect(plan.schedule.currentNumber, 1);
      expect(plan.schedule.expectedUntilLastMonth, 0);
      expect(plan.schedule.onTrack, isTrue);
    });
  });

  group('Simulação', () {
    test('resumo dos cenários', () {
      final s = plan.scenarios;
      expect(s.map((e) => e.willSave), [4500, 7500, 10500, 15000, 0]);
      expect(s.map((e) => e.accumulated), [4610, 7610, 10610, 15110, 110]);
      expect(s.map((e) => e.affordableCount), [4, 5, 5, 6, 0]);
      expect(s.map((e) => e.missing), [6120, 3120, 120, 0, 10620]);
      expect(s.map((e) => e.outcome), [
        ScenarioOutcome.buysSome, ScenarioOutcome.buysSome, ScenarioOutcome.buysSome,
        ScenarioOutcome.buysAll, ScenarioOutcome.buysNothing,
      ]);
    });

    test('mês de compra por produto (cenário 1 = R\$ 300)', () {
      final months = plan.scenarios.first.purchases.map((p) => (p as InMonth).month).toList();
      expect(months.take(5), [
        DateTime(2027, 1), DateTime(2027, 4), DateTime(2027, 11), DateTime(2027, 12), DateTime(2028, 1),
      ]);
      // A planilha mostra "Mais de 24 meses"; sem o teto, o app mostra o mês real.
      expect(months.last, DateTime(2029, 9));
    });

    test('mês de compra no cenário 4 = R\$ 1.000', () {
      final months = plan.scenarios[3].purchases.map((p) => (p as InMonth).month).toList();
      expect(months, [
        DateTime(2026, 11), DateTime(2026, 12), DateTime(2027, 2),
        DateTime(2027, 2), DateTime(2027, 2), DateTime(2027, 8),
      ]);
    });

    test('coluna "Sua renda" sem economia', () {
      expect(plan.scenarios.last.purchases.every((p) => p is NoSavings), isTrue);
    });
  });
}
