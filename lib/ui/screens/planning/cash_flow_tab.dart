import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/utils/month.dart';
import '../../../domain/calc/cash_flow.dart';
import '../../../domain/calc/finance_plan.dart';
import '../../widgets/plan_table.dart';
import '../../widgets/section_card.dart';
import '../../widgets/signal_badge.dart';
import 'tab_body.dart';

class CashFlowTab extends StatefulWidget {
  const CashFlowTab({super.key});

  @override
  State<CashFlowTab> createState() => _CashFlowTabState();
}

class _CashFlowTabState extends State<CashFlowTab> {
  bool _fullHistory = false;

  List<CashFlowMonth> _rows(FinancePlan plan) {
    if (!_fullHistory) return plan.planCashFlow;
    final first = plan.cashFlow.firstMonth;
    final last = plan.cashFlow.lastMonth;
    final from = first != null && first.isBefore(plan.planStart) ? first : plan.planStart;
    final to = last != null && last.isAfter(plan.planLastMonth) ? last : plan.planLastMonth;
    return plan.cashFlow.table(
      from: from,
      to: to,
      target: plan.minimumMonthly,
      tightLimit: plan.settings.tightLimit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlanTabBody(builder: (context, plan) {
      final rows = _rows(plan);
      final totals = rows.fold(
        (income: 0.0, fixed: 0.0, variable: 0.0, other: 0.0, expenses: 0.0, balance: 0.0, pending: 0.0),
        (acc, r) => (
          income: acc.income + r.totals.income,
          fixed: acc.fixed + r.totals.fixed,
          variable: acc.variable + r.totals.variable,
          other: acc.other + r.totals.other,
          expenses: acc.expenses + r.totals.expenses,
          balance: acc.balance + r.totals.balance,
          pending: acc.pending + r.totals.pending,
        ),
      );
      final current = rows.indexWhere((r) => Month.sameMonth(r.month, plan.currentPlanMonth));
      final categories = CashFlow.byCategory(plan.transactions, plan.settings.expenseCategories);
      final categoryTotal = categories.fold(0.0, (s, c) => s + c.amount);
      final currentMonth = {
        for (final c in CashFlow.byCategory(
          plan.cashFlow.transactionsOf(plan.currentPlanMonth),
          plan.settings.expenseCategories,
        ))
          c.category: c.amount,
      };

      return [
        SectionCard(
          title: 'Fluxo de caixa mensal',
          subtitle: 'Soma automática dos lançamentos por mês',
          trailing: SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: false, label: Text('Plano')),
              ButtonSegment(value: true, label: Text('Histórico')),
            ],
            selected: {_fullHistory},
            onSelectionChanged: (s) => setState(() => _fullHistory = s.first),
          ),
          child: PlanTable(
            highlightRow: current >= 0 ? current : null,
            columns: const [
              PlanColumn('Mês'),
              PlanColumn('Receitas', numeric: true),
              PlanColumn('Fixas', numeric: true),
              PlanColumn('Variáveis', numeric: true),
              PlanColumn('Outros', numeric: true),
              PlanColumn('Total despesas', numeric: true),
              PlanColumn('Saldo do mês', numeric: true),
              PlanColumn('Saldo acumulado', numeric: true),
              PlanColumn('Meta (mínimo)', numeric: true),
              PlanColumn('Situação'),
              PlanColumn('Pendentes', numeric: true),
            ],
            rows: [
              for (final r in rows)
                [
                  Fmt.monthYear(r.month),
                  Fmt.money(r.totals.income),
                  Fmt.money(r.totals.fixed),
                  Fmt.money(r.totals.variable),
                  Fmt.money(r.totals.other),
                  Fmt.money(r.totals.expenses),
                  Fmt.money(r.totals.balance),
                  Fmt.money(r.accumulated),
                  Fmt.money(plan.minimumMonthly),
                  SignalBadge(signal: r.situation.signal, label: r.situation.label, dense: true),
                  Fmt.money(r.totals.pending),
                ],
            ],
            footer: [
              'TOTAL',
              Fmt.money(totals.income),
              Fmt.money(totals.fixed),
              Fmt.money(totals.variable),
              Fmt.money(totals.other),
              Fmt.money(totals.expenses),
              Fmt.money(totals.balance),
              '',
              '',
              '',
              Fmt.money(totals.pending),
            ],
          ),
        ),
        SectionCard(
          title: 'Despesas por categoria',
          subtitle: 'Todo o histórico · mês atual do plano: ${Fmt.monthYear(plan.currentPlanMonth)}',
          child: PlanTable(
            columns: const [
              PlanColumn('Categoria'),
              PlanColumn('Total lançado', numeric: true),
              PlanColumn('% do total', numeric: true),
              PlanColumn('No mês atual', numeric: true),
            ],
            rows: [
              for (final c in categories)
                [
                  c.category,
                  Fmt.money(c.amount),
                  Fmt.percent(c.share),
                  Fmt.money(currentMonth[c.category] ?? 0),
                ],
            ],
            footer: [
              'TOTAL',
              Fmt.money(categoryTotal),
              Fmt.percent(categoryTotal == 0 ? 0 : 1),
              Fmt.money(currentMonth.values.fold(0.0, (a, b) => a + b)),
            ],
          ),
        ),
        const HowToRead(
          'Meta de economia = mínimo mensal para cumprir todos os prazos por prioridade. '
          'Saldo do mês maior ou igual à meta = dá para guardar o necessário. '
          'Despesa sem grupo entra em "variáveis". Categorias fora da lista também aparecem, '
          'para que o total por categoria bata com o total de despesas.',
        ),
      ];
    });
  }
}
