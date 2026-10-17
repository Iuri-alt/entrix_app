import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/import_report.dart';
import '../../widgets/feedback.dart';
import '../../widgets/section_card.dart';

const _xlsxMime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

class SpreadsheetActions extends StatefulWidget {
  const SpreadsheetActions({super.key});

  @override
  State<SpreadsheetActions> createState() => _SpreadsheetActionsState();
}

class _SpreadsheetActionsState extends State<SpreadsheetActions> {
  bool _busy = false;

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() => _guard(() async {
        final files = await FilePicker.pickFiles(
          dialogTitle: 'Escolha a planilha',
          type: FileType.custom,
          allowedExtensions: const ['xlsx'],
        );
        if (files.isEmpty || !mounted) return;
        final file = files.first;
        final bytes = await file.readAsBytes();
        if (!mounted) return;

        final store = context.store;
        final preview = await store.importSpreadsheet(bytes, file.name, dryRun: true);
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => _ReportDialog(report: preview),
        );
        if (confirmed != true || !mounted) return;

        final result = await store.importSpreadsheet(bytes, file.name, dryRun: false);
        if (mounted) {
          showMessage(context,
              'Importado: ${result.transactionsNew} lançamento(s) e ${result.productsNew} produto(s).');
        }
      });

  Future<void> _export() => _guard(() async {
        final bytes = await context.store.exportSpreadsheet();
        final now = DateTime.now();
        final name = 'entrix_${now.year}-${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}.xlsx';
        final saved = await FilePicker.saveFile(
          dialogTitle: 'Salvar planilha',
          fileName: name,
          bytes: bytes,
          mimeType: _xlsxMime,
          type: FileType.custom,
          allowedExtensions: const ['xlsx'],
        );
        if (saved != null && mounted) showMessage(context, 'Planilha exportada');
      });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Planilha (.xlsx)',
      subtitle: 'Importe sua planilha Controle Financeiro ou exporte seus dados. '
          'Importar de novo não duplica registros.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _import,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Importar planilha'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Exportar planilha'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}

class _ReportDialog extends StatelessWidget {
  const _ReportDialog({required this.report});

  final ImportReport report;

  @override
  Widget build(BuildContext context) {
    Widget issue(ImportIssue i, Color color) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text('• ${i.sheet}${i.row > 0 ? ', linha ${i.row}' : ''}: ${i.message}',
              style: TextStyle(color: color, fontSize: 13)),
        );

    return AlertDialog(
      title: const Text('Revisar importação'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lançamentos novos: ${report.transactionsNew} '
                  '(já existentes: ${report.transactionsDuplicated})'),
              Text('Produtos novos: ${report.productsNew} (já existentes: ${report.productsDuplicated})'),
              Text(report.settingsUpdated
                  ? 'Configurações, orçamento e cenários serão atualizados.'
                  : 'Sem aba Config: configurações mantidas.'),
              if (report.errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Linhas ignoradas (${report.errors.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                for (final e in report.errors) issue(e, AppColors.serious),
              ],
              if (report.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Avisos (${report.warnings.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                for (final w in report.warnings) issue(w, AppColors.textSecondary),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: report.hasChanges ? () => Navigator.pop(context, true) : null,
          child: Text(report.hasChanges ? 'Importar' : 'Nada novo'),
        ),
      ],
    );
  }
}
