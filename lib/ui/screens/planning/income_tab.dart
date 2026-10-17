import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format/formatters.dart';
import '../../../domain/calc/finance_plan.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/plan_settings.dart';
import '../../widgets/feedback.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/plan_table.dart';
import '../../widgets/section_card.dart';
import '../../widgets/signal_badge.dart';
import 'tab_body.dart';

class IncomeTab extends StatelessWidget {
  const IncomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PlanTabBody(builder: (context, plan) => [
          // A chave recria o formulário quando a configuração salva muda.
          _BudgetForm(key: ObjectKey(plan.settings), settings: plan.settings),
          _Comparison(plan: plan),
          HowToRead(
            'Meta possível: disponível ≥ mínimo. Meta apertada: entre '
            '${Fmt.percent(plan.settings.tightLimit)} do mínimo (Ajustes) e o mínimo. '
            'Meta impossível: abaixo disso. Base "Realizado": usa a média do saldo '
            '(receitas − despesas) dos meses do plano já lançados; sem lançamentos, usa o previsto.',
          ),
        ]);
  }
}

class _BudgetForm extends StatefulWidget {
  const _BudgetForm({super.key, required this.settings});

  final PlanSettings settings;

  @override
  State<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<_BudgetForm> {
  final _form = GlobalKey<FormState>();
  late final _income = TextEditingController(text: MoneyField.initial(widget.settings.budgetIncome));
  late final _fixed = TextEditingController(text: MoneyField.initial(widget.settings.budgetFixed));
  late final _variable = TextEditingController(text: MoneyField.initial(widget.settings.budgetVariable));
  late final _other = TextEditingController(text: MoneyField.initial(widget.settings.budgetOther));
  late PlanBase _base = widget.settings.planBase;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_income, _fixed, _variable, _other]) {
      c.dispose();
    }
    super.dispose();
  }

  double _value(TextEditingController c) => Fmt.parseMoney(c.text) ?? 0;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await runWithFeedback(
      context,
      () => context.store.saveSettings(widget.settings.copyWith(
        budgetIncome: _value(_income),
        budgetFixed: _value(_fixed),
        budgetVariable: _value(_variable),
        budgetOther: _value(_other),
        planBase: _base,
      )),
      success: 'Orçamento salvo',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final forecast = _value(_income) - _value(_fixed) - _value(_variable) - _value(_other);
    Widget field(TextEditingController c, String label) => SizedBox(
          width: 220,
          child: MoneyField(controller: c, label: label, allowZero: true, required: false),
        );

    return SectionCard(
      title: 'Orçamento previsto do mês',
      subtitle: 'O realizado vem dos lançamentos',
      child: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                field(_income, 'Renda mensal'),
                field(_fixed, 'Gastos fixos'),
                field(_variable, 'Gastos variáveis'),
                field(_other, 'Outros compromissos'),
              ],
            ),
            const SizedBox(height: 14),
            Text('Disponível para economia (previsto): ${Fmt.money(forecast)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            const Text('Base usada no plano'),
            const SizedBox(height: 6),
            SegmentedButton<PlanBase>(
              segments: [for (final b in PlanBase.values) ButtonSegment(value: b, label: Text(b.label))],
              selected: {_base},
              onSelectionChanged: (s) => setState(() => _base = s.first),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('Salvar orçamento'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.plan});

  final FinancePlan plan;

  @override
  Widget build(BuildContext context) {
    final income = plan.income;
    final minimum = plan.minimumMonthly;
    final situation = plan.incomeSituation;
    final productCount = plan.products.length;

    final String adjustment;
    if (plan.totalMissing <= 0) {
      adjustment = 'Nenhum ajuste necessário.';
    } else if (plan.priorities.increaseNeeded > 0) {
      adjustment = 'Aumente a economia em ${Fmt.money(plan.priorities.increaseNeeded)}/mês '
          'OU adie as datas indicadas em Prioridades.';
    } else {
      adjustment = 'Nenhum ajuste necessário: por prioridade tudo cabe no prazo.';
    }

    return SectionCard(
      title: 'Comparação com a meta',
      child: PlanTable(
        columns: const [PlanColumn('Item'), PlanColumn('Resultado')],
        rows: [
          ['Média realizada (meses já lançados)',
            income.realizedAverage == null ? 'Sem dados ainda' : Fmt.money(income.realizedAverage!)],
          ['Dinheiro disponível usado no plano',
            '${Fmt.money(plan.available)} (${income.usesRealized ? 'realizado' : 'previsto'})'],
          ['Economia mensal mínima p/ cumprir todos os prazos', Fmt.money(minimum)],
          ['Diferença (disponível − mínimo)', Fmt.money(plan.available - minimum)],
          ['Situação', SignalBadge(signal: situation.signal, label: situation.label, dense: true)],
          ['Falta economizar por mês', Fmt.money(income.shortfall(minimum))],
          ['Mínimo equivale a quanto da renda prevista', Fmt.percent(income.minimumShareOfIncome(minimum))],
          ['Meta se guardar p/ todos ao mesmo tempo (informativo)', Fmt.money(plan.monthlyGoal)],
          ['Produtos que cabem no prazo (por prioridade)', '${plan.priorities.onTimeCount} de $productCount'],
          ['Ajuste sugerido', SizedBox(width: 260, child: Text(adjustment, style: const TextStyle(fontSize: 13)))],
        ],
      ),
    );
  }
}

