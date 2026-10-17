import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../domain/calc/finance_plan.dart';

/// Reconstrói a aba quando os dados mudam e aplica o espaçamento padrão.
class PlanTabBody extends StatelessWidget {
  const PlanTabBody({super.key, required this.builder});

  final List<Widget> Function(BuildContext context, FinancePlan plan) builder;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final children = builder(context, store.plan);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => children[i],
        );
      },
    );
  }
}

/// Texto explicativo ("Como ler") no rodapé das abas.
class HowToRead extends StatelessWidget {
  const HowToRead(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      );
}
