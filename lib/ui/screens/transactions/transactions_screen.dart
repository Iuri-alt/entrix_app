import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../domain/calc/cash_flow.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/transaction.dart';
import '../../widgets/feedback.dart';
import '../../widgets/period_slicer.dart';
import '../../widgets/signal_badge.dart';
import 'transaction_filter.dart';
import 'transaction_form.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late TransactionFilter _filter;
  final _search = TextEditingController();

  List<FinanceTransaction>? _source;
  TransactionFilter? _appliedFilter;
  List<FinanceTransaction> _visible = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = TransactionFilter(year: now.year, month: now.month);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<FinanceTransaction> _filtered(List<FinanceTransaction> all) {
    if (!identical(all, _source) || _filter != _appliedFilter) {
      _source = all;
      _appliedFilter = _filter;
      _visible = all.where(_filter.matches).toList(growable: false);
    }
    return _visible;
  }

  void _update(TransactionFilter filter) => setState(() => _filter = filter);

  Future<void> _delete(FinanceTransaction t) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Excluir lançamento?',
      message: '"${t.description}" de ${Fmt.money(t.amount)} em ${Fmt.date(t.date)} será removido.',
    );
    if (!confirmed || !mounted) return;
    await runWithFeedback(context, () => context.store.deleteTransaction(t),
        success: 'Lançamento excluído');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTransactionForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Lançamento'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final items = _filtered(store.transactions);
          final totals = FlowTotals.of(items);
          final rows = _groupByDay(items);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: const Text('Lançamentos'),
                actions: [
                  IconButton(
                    tooltip: _filter.allTime ? 'Filtrar por período' : 'Ver todo o histórico',
                    isSelected: _filter.allTime,
                    icon: const Icon(Icons.history_rounded),
                    onPressed: () => _update(_filter.copyWith(allTime: !_filter.allTime)),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 12, 8),
                    child: _filter.allTime
                        ? const SizedBox(
                            height: 44,
                            child: Center(child: Text('Todo o histórico')),
                          )
                        : PeriodSlicer(
                            year: _filter.year,
                            month: _filter.month,
                            years: store.plan.availableYears,
                            onChanged: (y, m) => _update(
                              _filter.copyWith(year: y, month: m, clearMonth: m == null),
                            ),
                          ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _filters(store.settings.expenseCategories +
                  store.settings.incomeCategories)),
              SliverToBoxAdapter(child: _Totals(totals: totals)),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nenhum lançamento encontrado',
                    message: _filter.hasExtraFilters
                        ? 'Ajuste a busca ou os filtros.'
                        : 'Toque em "Lançamento" para registrar uma receita ou despesa — '
                            'de qualquer data, inclusive meses e anos anteriores.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 96),
                  sliver: SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) => switch (rows[i]) {
                      _DayHeader(:final day, :final total) => _DayHeaderTile(day: day, total: total),
                      _Entry(:final transaction) => _TransactionTile(
                          transaction: transaction,
                          onEdit: () => openTransactionForm(context, initial: transaction),
                          onDuplicate: () => openTransactionForm(
                            context,
                            initial: FinanceTransaction(
                              date: DateTime.now(),
                              description: transaction.description,
                              kind: transaction.kind,
                              group: transaction.group,
                              category: transaction.category,
                              amount: transaction.amount,
                              status: transaction.status,
                            ),
                          ),
                          onDelete: () => _delete(transaction),
                        ),
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _filters(List<String> categories) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              controller: _search,
              onChanged: (q) => _update(_filter.copyWith(query: q.trim())),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _search.clear();
                          _update(_filter.copyWith(query: ''));
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          for (final kind in TransactionKind.values) ...[
            FilterChip(
              label: Text(kind == TransactionKind.income ? 'Receitas' : 'Despesas'),
              selected: _filter.kind == kind,
              onSelected: (on) => _update(on
                  ? _filter.copyWith(kind: kind)
                  : _filter.copyWith(clearKind: true)),
            ),
            const SizedBox(width: 8),
          ],
          FilterChip(
            label: const Text('Pendentes'),
            selected: _filter.pendingOnly,
            onSelected: (on) => _update(_filter.copyWith(pendingOnly: on)),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String?>(
            tooltip: 'Filtrar por categoria',
            onSelected: (c) => _update(
                c == null ? _filter.copyWith(clearCategory: true) : _filter.copyWith(category: c)),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todas as categorias')),
              for (final c in {...categories}) PopupMenuItem(value: c, child: Text(c)),
            ],
            child: Chip(
              avatar: const Icon(Icons.category_outlined, size: 16),
              label: Text(_filter.category ?? 'Categoria'),
              backgroundColor: _filter.category == null ? null : AppColors.brand.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  static List<_Row> _groupByDay(List<FinanceTransaction> items) {
    final rows = <_Row>[];
    DateTime? current;
    var headerIndex = -1;
    var dayTotal = 0.0;
    for (final t in items) {
      if (current == null || t.date != current) {
        if (headerIndex >= 0) rows[headerIndex] = _DayHeader(current!, dayTotal);
        current = t.date;
        dayTotal = 0;
        headerIndex = rows.length;
        rows.add(_DayHeader(t.date, 0));
      }
      dayTotal += t.isIncome ? t.amount : -t.amount;
      rows.add(_Entry(t));
    }
    if (headerIndex >= 0) rows[headerIndex] = _DayHeader(current!, dayTotal);
    return rows;
  }
}

sealed class _Row {
  const _Row();
}

class _DayHeader extends _Row {
  const _DayHeader(this.day, this.total);
  final DateTime day;
  final double total;
}

class _Entry extends _Row {
  const _Entry(this.transaction);
  final FinanceTransaction transaction;
}

class _Totals extends StatelessWidget {
  const _Totals({required this.totals});

  final FlowTotals totals;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, double value, Color accent) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(Fmt.money(value), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              cell('Receitas', totals.income, ChartColors.income),
              cell('Despesas', totals.expenses, ChartColors.expense),
              cell('Saldo', totals.balance, AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHeaderTile extends StatelessWidget {
  const _DayHeaderTile({required this.day, required this.total});

  final DateTime day;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          Text(Fmt.date(day),
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(Fmt.money(total), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

enum _Action { edit, duplicate, delete }

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final FinanceTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final accent = t.isIncome ? ChartColors.income : ChartColors.expense;
    final details = [t.category, if (t.group != null) t.group!.label].join(' · ');

    return ListTile(
      onTap: onEdit,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.16),
        child: Icon(t.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: accent, size: 20),
      ),
      title: Text(t.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(details,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          if (t.isPending) ...[
            const SizedBox(width: 6),
            const SignalBadge(signal: Signal.warning, label: 'Pendente', dense: true),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${t.isIncome ? '+' : '−'} ${Fmt.money(t.amount)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
          ),
          PopupMenuButton<_Action>(
            tooltip: 'Mais ações',
            onSelected: (a) => switch (a) {
              _Action.edit => onEdit(),
              _Action.duplicate => onDuplicate(),
              _Action.delete => onDelete(),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Action.edit, child: Text('Editar')),
              PopupMenuItem(value: _Action.duplicate, child: Text('Duplicar')),
              PopupMenuItem(value: _Action.delete, child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}
