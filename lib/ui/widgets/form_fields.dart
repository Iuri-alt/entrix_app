import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format/formatters.dart';

/// Campo de valor em reais (aceita "1.234,56" ou "1234.56").
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.allowZero = false,
    this.required = true,
    this.helper,
  });

  final TextEditingController controller;
  final String label;
  final bool allowZero;
  final bool required;
  final String? helper;

  static String initial(double? value) =>
      value == null ? '' : value.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      decoration: InputDecoration(labelText: label, prefixText: r'R$ ', helperText: helper),
      validator: (text) {
        if ((text ?? '').trim().isEmpty) return required ? 'Informe o valor' : null;
        final value = Fmt.parseMoney(text!);
        if (value == null) return 'Valor inválido';
        if (value < 0 || (!allowZero && value == 0)) {
          return allowZero ? 'Não pode ser negativo' : 'Deve ser maior que zero';
        }
        return null;
      },
    );
  }
}

/// Campo de data que abre o calendário (aceita qualquer ano).
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowClear = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool allowClear;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendar,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_rounded),
          suffixIcon: allowClear && value != null
              ? IconButton(
                  tooltip: 'Remover data',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(value == null ? 'Sem data' : Fmt.date(value!)),
      ),
    );
  }
}

/// Lista suspensa que preserva um valor atual fora da lista (ex.: dado importado).
class ChoiceField extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = {...options, if (value != null && value!.isNotEmpty) value!}.toList();
    return DropdownButtonFormField<String>(
      initialValue: value != null && value!.isNotEmpty ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [for (final o in items) DropdownMenuItem(value: o, child: Text(o))],
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Escolha uma opção' : null,
    );
  }
}

/// Abre um formulário como folha inferior no celular e como diálogo no desktop.
Future<T?> showFormSheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  if (MediaQuery.sizeOf(context).width >= 700) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: builder(context),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: builder(context),
    ),
  );
}

/// Estrutura comum dos formulários (título, campos com rolagem e botões).
class FormScaffold extends StatelessWidget {
  const FormScaffold({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.busy,
    required this.onSubmit,
    this.submitLabel = 'Salvar',
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final bool busy;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final child in children) ...[child, const SizedBox(height: 14)],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onSubmit,
                    child: busy
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(submitLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
