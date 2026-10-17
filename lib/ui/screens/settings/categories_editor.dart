import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../domain/models/plan_settings.dart';
import '../../widgets/feedback.dart';
import '../../widgets/section_card.dart';

enum _List { product, income, expense }

/// Listas suspensas da aba Config (categorias editáveis).
class CategoriesEditor extends StatelessWidget {
  const CategoriesEditor({super.key, required this.settings});

  final PlanSettings settings;

  List<String> _items(_List list) => switch (list) {
        _List.product => settings.productCategories,
        _List.income => settings.incomeCategories,
        _List.expense => settings.expenseCategories,
      };

  PlanSettings _with(_List list, List<String> items) => switch (list) {
        _List.product => settings.copyWith(productCategories: items),
        _List.income => settings.copyWith(incomeCategories: items),
        _List.expense => settings.copyWith(expenseCategories: items),
      };

  Future<void> _save(BuildContext context, _List list, List<String> items) =>
      runWithFeedback(context, () => context.store.saveSettings(_with(list, items)));

  Future<void> _add(BuildContext context, _List list) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nome'),
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    controller.dispose();
    final value = name?.trim() ?? '';
    if (value.isEmpty || !context.mounted) return;
    final items = _items(list);
    if (items.any((c) => c.toLowerCase() == value.toLowerCase())) {
      showMessage(context, 'Essa categoria já existe.', error: true);
      return;
    }
    await _save(context, list, [...items, value]);
  }

  Future<void> _remove(BuildContext context, _List list, String name) async {
    final items = _items(list);
    if (list != _List.product && items.length == 1) {
      showMessage(context, 'Mantenha pelo menos uma categoria.', error: true);
      return;
    }
    final confirmed = await confirmDestructive(
      context,
      title: 'Remover "$name"?',
      message: 'Os registros que já usam esta categoria não são alterados.',
      confirmLabel: 'Remover',
    );
    if (confirmed && context.mounted) {
      await _save(context, list, items.where((c) => c != name).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget group(String title, _List list) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in _items(list))
                    InputChip(
                      label: Text(c),
                      onDeleted: () => _remove(context, list, c),
                      deleteButtonTooltipMessage: 'Remover',
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Adicionar'),
                    onPressed: () => _add(context, list),
                  ),
                ],
              ),
            ],
          ),
        );

    return SectionCard(
      title: 'Categorias',
      subtitle: 'Opções das listas de produtos e lançamentos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          group('Despesas', _List.expense),
          group('Receitas', _List.income),
          group('Produtos', _List.product),
        ],
      ),
    );
  }
}
