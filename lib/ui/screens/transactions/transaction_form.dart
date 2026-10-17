import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format/formatters.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/transaction.dart';
import '../../widgets/feedback.dart';
import '../../widgets/form_fields.dart';

/// Abre o formulário. [initial] com id edita; sem id cria (também usado para duplicar).
Future<void> openTransactionForm(BuildContext context, {FinanceTransaction? initial}) =>
    showFormSheet<void>(context, (_) => TransactionForm(initial: initial));

class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key, this.initial});

  final FinanceTransaction? initial;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late TransactionKind _kind;
  late DateTime _date;
  ExpenseGroup? _group;
  String? _category;
  late PaymentStatus _status;
  bool _busy = false;

  bool get _editing => widget.initial?.id != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _description = TextEditingController(text: t?.description ?? '');
    _amount = TextEditingController(text: MoneyField.initial(t?.amount));
    _kind = t?.kind ?? TransactionKind.expense;
    _date = t?.date ?? DateTime.now();
    _group = t?.group;
    _category = t?.category;
    _status = t?.status ?? PaymentStatus.paid;
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _setKind(TransactionKind kind) => setState(() {
        if (kind == _kind) return;
        _kind = kind;
        final options = context.store.settings.categoriesFor(kind);
        if (!options.contains(_category)) _category = null;
      });

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final transaction = FinanceTransaction(
      id: widget.initial?.id,
      date: _date,
      description: _description.text.trim(),
      kind: _kind,
      group: _kind == TransactionKind.expense ? _group : null,
      category: _category!,
      amount: Fmt.parseMoney(_amount.text)!,
      status: _status,
    );
    setState(() => _busy = true);
    final ok = await runWithFeedback(
      context,
      () => context.store.saveTransaction(transaction),
      success: _editing ? 'Lançamento atualizado' : 'Lançamento adicionado',
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
    final settings = context.store.settings;
    final isExpense = _kind == TransactionKind.expense;

    return FormScaffold(
      title: _editing ? 'Editar lançamento' : 'Novo lançamento',
      formKey: _form,
      busy: _busy,
      onSubmit: _submit,
      children: [
        SegmentedButton<TransactionKind>(
          segments: const [
            ButtonSegment(
              value: TransactionKind.expense,
              label: Text('Despesa'),
              icon: Icon(Icons.north_east_rounded),
            ),
            ButtonSegment(
              value: TransactionKind.income,
              label: Text('Receita'),
              icon: Icon(Icons.south_west_rounded),
            ),
          ],
          selected: {_kind},
          onSelectionChanged: (s) => _setKind(s.first),
        ),
        MoneyField(controller: _amount, label: 'Valor'),
        TextFormField(
          controller: _description,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Descrição'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Informe a descrição' : null,
        ),
        DateField(
          label: 'Data',
          value: _date,
          onChanged: (d) => setState(() => _date = d ?? _date),
        ),
        ChoiceField(
          label: 'Categoria',
          value: _category,
          options: settings.categoriesFor(_kind),
          onChanged: (v) => setState(() => _category = v),
        ),
        if (isExpense) ...[
          const Text('Grupo da despesa'),
          SegmentedButton<ExpenseGroup?>(
            showSelectedIcon: false,
            segments: [
              for (final g in ExpenseGroup.values)
                ButtonSegment(value: g, label: Text(g == ExpenseGroup.other ? 'Outro' : g.label)),
              const ButtonSegment(value: null, label: Text('Nenhum')),
            ],
            selected: {_group},
            onSelectionChanged: (s) => setState(() => _group = s.first),
          ),
          const Text(
            'Sem grupo, a despesa conta como variável no fluxo de caixa.',
            style: TextStyle(fontSize: 12),
          ),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(isExpense ? 'Já foi paga' : 'Já foi recebida'),
          subtitle: Text(_status == PaymentStatus.paid ? 'Pago' : 'Pendente'),
          value: _status == PaymentStatus.paid,
          onChanged: (paid) =>
              setState(() => _status = paid ? PaymentStatus.paid : PaymentStatus.pending),
        ),
      ],
    );
  }
}
