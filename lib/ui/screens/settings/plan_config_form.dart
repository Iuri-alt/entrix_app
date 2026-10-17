import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/format/formatters.dart';
import '../../../domain/models/plan_settings.dart';
import '../../widgets/feedback.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/section_card.dart';

/// Aba Config: janela do plano e parâmetros dos status.
class PlanConfigForm extends StatefulWidget {
  const PlanConfigForm({super.key, required this.settings});

  final PlanSettings settings;

  @override
  State<PlanConfigForm> createState() => _PlanConfigFormState();
}

class _PlanConfigFormState extends State<PlanConfigForm> {
  final _form = GlobalKey<FormState>();
  late DateTime _start = widget.settings.planStart;
  late DateTime _end = widget.settings.planEnd;
  late DateTime? _today = widget.settings.todayOverride;
  late final _daysSoon = TextEditingController(text: '${widget.settings.daysSoon}');
  late final _tight = TextEditingController(
    text: (widget.settings.tightLimit * 100).round().toString(),
  );
  bool _busy = false;

  @override
  void dispose() {
    _daysSoon.dispose();
    _tight.dispose();
    super.dispose();
  }

  int get _months {
    final m = (_end.year - _start.year) * 12 + _end.month - _start.month + 1;
    return m < 1 ? 1 : m;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_end.isBefore(_start)) {
      showMessage(context, 'O prazo final deve ser depois do primeiro mês.', error: true);
      return;
    }
    setState(() => _busy = true);
    await runWithFeedback(
      context,
      () => context.store.saveSettings(widget.settings.copyWith(
        planStart: _start,
        planEnd: _end,
        todayOverride: _today,
        clearTodayOverride: _today == null,
        daysSoon: int.parse(_daysSoon.text),
        tightLimit: int.parse(_tight.text) / 100,
      )),
      success: 'Configurações salvas',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    String? intRange(String? v, int min, int max) {
      final n = int.tryParse(v ?? '');
      return n == null || n < min || n > max ? 'Entre $min e $max' : null;
    }

    return SectionCard(
      title: 'Plano',
      subtitle: '$_months meses · ${Fmt.monthYear(_start)} a ${Fmt.monthYear(_end)} · sem limite de prazo',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DateField(
              label: 'Primeiro mês de economia',
              value: _start,
              onChanged: (d) => setState(() => _start = DateTime((d ?? _start).year, (d ?? _start).month)),
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Prazo final do plano',
              value: _end,
              onChanged: (d) => setState(() => _end = d ?? _end),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _daysSoon,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Dias para "Próximo"',
                      helperText: 'Produto vence em até X dias',
                    ),
                    validator: (v) => intRange(v, 0, 365),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _tight,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Limite "Meta apertada"',
                      suffixText: '%',
                      helperText: 'Disponível ≥ X% do mínimo',
                    ),
                    validator: (v) => intRange(v, 1, 100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Simular outra data de hoje (opcional)',
              value: _today,
              allowClear: true,
              onChanged: (d) => setState(() => _today = d),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('Salvar configurações'),
            ),
          ],
        ),
      ),
    );
  }
}
