import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/theme.dart';
import '../../widgets/feedback.dart';
import '../../widgets/section_card.dart';
import 'categories_editor.dart';
import 'plan_config_form.dart';
import 'spreadsheet_actions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Sair da conta?',
      message: 'Seus dados continuam salvos no servidor.',
      confirmLabel: 'Sair',
    );
    if (confirmed && context.mounted) await context.session.logout();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final settings = store.settings;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              PlanConfigForm(key: ObjectKey(settings), settings: settings),
              const SizedBox(height: 12),
              CategoriesEditor(settings: settings),
              const SizedBox(height: 12),
              const SpreadsheetActions(),
              const SizedBox(height: 12),
              const _HowToUse(),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Conta',
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sair'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HowToUse extends StatelessWidget {
  const _HowToUse();

  static const _steps = [
    'Ajustes: confira o primeiro mês de economia e o prazo final do plano.',
    'Produtos: cadastre o que quer comprar (preço, prioridade, data e quanto já guardou).',
    'Lançamentos: registre cada receita e despesa, de qualquer mês ou ano.',
    'Planejamento › Renda: informe o orçamento previsto e escolha a base (Previsto ou Realizado).',
    'Sempre que guardar dinheiro para um produto, use "Guardar dinheiro". O resto se recalcula sozinho.',
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Como usar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, step) in _steps.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.surfaceRaised,
                    child: Text('${i + 1}', style: const TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(step)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
