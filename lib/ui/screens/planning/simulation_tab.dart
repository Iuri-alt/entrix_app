import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format/formatters.dart';
import '../../../domain/calc/finance_plan.dart';
import '../../../domain/calc/simulation.dart';
import '../../../domain/models/enums.dart';
import '../../widgets/feedback.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/plan_table.dart';
import '../../widgets/section_card.dart';
import '../../widgets/signal_badge.dart';
import 'purchase_label.dart';
import 'tab_body.dart';

class SimulationTab extends StatelessWidget {
  const SimulationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PlanTabBody(builder: (context, plan) {
      final scenarios = plan.scenarios;
      final names = [
        for (var i = 0; i < scenarios.length - 1; i++) 'Cenário ${i + 1}',
        'Sua renda',
      ];
      final columns = [
        const PlanColumn('Cenário'),
        for (final n in names) PlanColumn(n, numeric: true),
      ];

      return [
        SectionCard(
          title: 'Simulação de cenários',
          subtitle: 'Toque num valor de economia para editar. Usa a ordem de Prioridades.',
          child: PlanTable(
            columns: columns,
            rows: [
              [
                'Economia por mês',
                for (final (i, s) in scenarios.indexed)
                  i == scenarios.length - 1
                      ? Fmt.money(s.monthlySaving)
                      : _EditableScenario(index: i, plan: plan),
              ],
              ['Já tenho guardado', for (final s in scenarios) Fmt.money(s.alreadySaved)],
              ['Vou guardar até o fim do plano', for (final s in scenarios) Fmt.money(s.willSave)],
              ['Quanto acumularei até o prazo final', for (final s in scenarios) Fmt.money(s.accumulated)],
              [
                'Produtos que consigo comprar (de ${plan.products.length})',
                for (final s in scenarios) '${s.affordableCount}',
              ],
              ['Quanto vai faltar para comprar tudo', for (final s in scenarios) Fmt.money(s.missing)],
              ['Resultado', for (final s in scenarios) _outcome(s.outcome)],
            ],
          ),
        ),
        SectionCard(
          title: 'Em que mês cada produto poderá ser comprado',
          child: PlanTable(
            columns: [
              const PlanColumn('Produto'),
              for (final n in names) PlanColumn(n),
              const PlanColumn('Prioridade'),
            ],
            rows: [
              for (final (i, row) in plan.priorities.rows.indexed)
                [
                  row.plan.product.name,
                  for (final s in scenarios) purchaseBadge(s.purchases[i], plan.planLastMonth),
                  row.plan.product.priority.label,
                ],
            ],
          ),
        ),
        const HowToRead(
          'Cores: verde = dentro do prazo final do plano · amarelo = só depois do prazo final · '
          'vermelho = sem economia · azul = o saldo atual já cobre. Sem limite de meses: '
          'o app mostra o mês real mesmo depois de 24 meses.',
        ),
      ];
    });
  }

  static Widget _outcome(ScenarioOutcome o) => switch (o) {
        ScenarioOutcome.buysAll =>
          const SignalBadge(signal: Signal.good, label: 'Compra tudo', dense: true),
        ScenarioOutcome.buysSome =>
          const SignalBadge(signal: Signal.warning, label: 'Compra só parte', dense: true),
        ScenarioOutcome.buysNothing =>
          const SignalBadge(signal: Signal.critical, label: 'Não compra nada', dense: true),
      };
}

class _EditableScenario extends StatelessWidget {
  const _EditableScenario({required this.index, required this.plan});

  final int index;
  final FinancePlan plan;

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(
      text: MoneyField.initial(plan.settings.scenarios[index]),
    );
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cenário ${index + 1}'),
        content: Form(
          key: formKey,
          child: MoneyField(controller: controller, label: 'Economia por mês', allowZero: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, Fmt.parseMoney(controller.text));
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !context.mounted) return;
    final scenarios = [...plan.settings.scenarios]..[index] = value;
    await runWithFeedback(
      context,
      () => context.store.saveSettings(plan.settings.copyWith(scenarios: scenarios)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _edit(context),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Fmt.money(plan.settings.scenarios[index]),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.edit_outlined, size: 14),
          ],
        ),
      ),
    );
  }
}
