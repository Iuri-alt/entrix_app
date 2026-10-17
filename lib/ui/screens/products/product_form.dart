import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format/formatters.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/product.dart';
import '../../widgets/feedback.dart';
import '../../widgets/form_fields.dart';

Future<void> openProductForm(BuildContext context, {Product? initial}) =>
    showFormSheet<void>(context, (_) => ProductForm(initial: initial));

class ProductForm extends StatefulWidget {
  const ProductForm({super.key, this.initial});

  final Product? initial;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _saved;
  String? _category;
  late Priority _priority;
  DateTime? _target;
  bool _busy = false;

  bool get _editing => widget.initial?.id != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: MoneyField.initial(p?.price));
    _saved = TextEditingController(text: MoneyField.initial(p?.saved ?? 0));
    _category = (p?.category.isEmpty ?? true) ? null : p!.category;
    _priority = p?.priority ?? Priority.medium;
    _target = p?.targetDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _saved.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final product = Product(
      id: widget.initial?.id,
      name: _name.text.trim(),
      category: _category ?? '',
      price: Fmt.parseMoney(_price.text)!,
      priority: _priority,
      targetDate: _target,
      saved: Fmt.parseMoney(_saved.text) ?? 0,
    );
    setState(() => _busy = true);
    final ok = await runWithFeedback(
      context,
      () => context.store.saveProduct(product),
      success: _editing ? 'Produto atualizado' : 'Produto adicionado',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.store.settings.productCategories;
    return FormScaffold(
      title: _editing ? 'Editar produto' : 'Novo produto',
      formKey: _form,
      busy: _busy,
      onSubmit: _submit,
      children: [
        TextFormField(
          controller: _name,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Produto'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome' : null,
        ),
        DropdownButtonFormField<String>(
          initialValue: _category,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Categoria'),
          items: [
            for (final c in {...categories, ?_category})
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) => setState(() => _category = v),
        ),
        MoneyField(controller: _price, label: 'Preço'),
        const Text('Prioridade'),
        SegmentedButton<Priority>(
          segments: [for (final p in Priority.values) ButtonSegment(value: p, label: Text(p.label))],
          selected: {_priority},
          onSelectionChanged: (s) => setState(() => _priority = s.first),
        ),
        DateField(
          label: 'Data desejada',
          value: _target,
          allowClear: true,
          onChanged: (d) => setState(() => _target = d),
        ),
        MoneyField(
          controller: _saved,
          label: 'Já tenho guardado',
          allowZero: true,
          required: false,
          helper: 'Dinheiro reservado para este produto',
        ),
      ],
    );
  }
}

/// Soma um valor ao "Já tenho guardado" do produto.
Future<void> openSaveMoney(BuildContext context, Product product) =>
    showFormSheet<void>(context, (_) => _SaveMoneyForm(product: product));

class _SaveMoneyForm extends StatefulWidget {
  const _SaveMoneyForm({required this.product});

  final Product product;

  @override
  State<_SaveMoneyForm> createState() => _SaveMoneyFormState();
}

class _SaveMoneyFormState extends State<_SaveMoneyForm> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(text: MoneyField.initial(widget.product.remaining));
  bool _busy = false;
  bool _withdraw = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final value = Fmt.parseMoney(_amount.text)!;
    final saved = widget.product.saved + (_withdraw ? -value : value);
    if (saved < 0) {
      showMessage(context, 'O valor guardado não pode ficar negativo.', error: true);
      return;
    }
    setState(() => _busy = true);
    final ok = await runWithFeedback(
      context,
      () => context.store.saveProduct(widget.product.copyWith(saved: saved)),
      success: 'Guardado agora: ${Fmt.money(saved)}',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return FormScaffold(
      title: p.name,
      formKey: _form,
      busy: _busy,
      onSubmit: _submit,
      submitLabel: _withdraw ? 'Retirar' : 'Guardar',
      children: [
        Text('Guardado: ${Fmt.money(p.saved)} · falta ${Fmt.money(p.remaining)}'),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Guardar'), icon: Icon(Icons.add_rounded)),
            ButtonSegment(value: true, label: Text('Retirar'), icon: Icon(Icons.remove_rounded)),
          ],
          selected: {_withdraw},
          onSelectionChanged: (s) => setState(() => _withdraw = s.first),
        ),
        MoneyField(controller: _amount, label: 'Valor'),
      ],
    );
  }
}
