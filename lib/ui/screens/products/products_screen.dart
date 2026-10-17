import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../domain/calc/product_plan.dart';
import '../../widgets/feedback.dart';
import '../../widgets/kpi_tile.dart';
import '../../widgets/section_card.dart';
import '../../widgets/signal_badge.dart';
import 'product_form.dart';

enum _Sort { table, priority, date, missing }

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  _Sort _sort = _Sort.table;

  List<ProductPlan> _sorted(List<ProductPlan> plans) {
    final list = [...plans];
    switch (_sort) {
      case _Sort.table:
        break;
      case _Sort.priority:
        list.sort((a, b) => a.product.priority.rank.compareTo(b.product.priority.rank));
      case _Sort.date:
        list.sort((a, b) => (a.product.targetDate ?? DateTime(9999))
            .compareTo(b.product.targetDate ?? DateTime(9999)));
      case _Sort.missing:
        list.sort((a, b) => b.remaining.compareTo(a.remaining));
    }
    return list;
  }

  Future<void> _delete(ProductPlan plan) async {
    final p = plan.product;
    final confirmed = await confirmDestructive(
      context,
      title: 'Excluir produto?',
      message: '"${p.name}" (${Fmt.money(p.price)}) sairá do planejamento.',
    );
    if (!confirmed || !mounted) return;
    await runWithFeedback(context, () => context.store.deleteProduct(p), success: 'Produto excluído');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          PopupMenuButton<_Sort>(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.table, child: Text('Ordem de cadastro')),
              PopupMenuItem(value: _Sort.priority, child: Text('Prioridade')),
              PopupMenuItem(value: _Sort.date, child: Text('Data desejada')),
              PopupMenuItem(value: _Sort.missing, child: Text('Maior valor faltando')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openProductForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Produto'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final plan = store.plan;
          if (plan.products.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Sua lista de desejos está vazia',
              message: 'Cadastre o que você quer comprar, com preço, prioridade e data. '
                  'O Entrix calcula quanto guardar por mês, semana e dia.',
            );
          }
          final items = _sorted(plan.productPlans);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              ResponsiveGrid(
                minItemWidth: 160,
                maxColumns: 4,
                children: [
                  KpiTile(label: 'Total dos produtos', value: Fmt.money(plan.totalProducts)),
                  KpiTile(label: 'Já guardado', value: Fmt.money(plan.totalSaved)),
                  KpiTile(label: 'Falta guardar', value: Fmt.money(plan.totalMissing)),
                  KpiTile(label: 'Progresso', value: Fmt.percent(plan.progress)),
                ],
              ),
              const SizedBox(height: 12),
              ResponsiveGrid(
                minItemWidth: 360,
                maxColumns: 3,
                children: [
                  for (final p in items)
                    _ProductCard(
                      plan: p,
                      onEdit: () => openProductForm(context, initial: p.product),
                      onSave: () => openSaveMoney(context, p.product),
                      onDelete: () => _delete(p),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.plan,
    required this.onEdit,
    required this.onSave,
    required this.onDelete,
  });

  final ProductPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = plan.product;
    final ratio = p.price <= 0 ? 0.0 : ((p.price - p.remaining) / p.price).clamp(0.0, 1.0);
    final text = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          [if (p.category.isNotEmpty) p.category, 'Prioridade ${p.priority.label}'].join(' · '),
                          style: text.bodySmall?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  SignalBadge(signal: plan.status.signal, label: plan.status.label),
                  PopupMenuButton<int>(
                    tooltip: 'Mais ações',
                    onSelected: (i) => [onEdit, onSave, onDelete][i](),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 0, child: Text('Editar')),
                      PopupMenuItem(value: 1, child: Text('Guardar / retirar dinheiro')),
                      PopupMenuItem(value: 2, child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceRaised,
                  color: plan.status == ProductStatus.done ? AppColors.good : ChartColors.series[2],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('${Fmt.money(p.price - p.remaining)} de ${Fmt.money(p.price)}',
                        overflow: TextOverflow.ellipsis, style: text.bodySmall),
                  ),
                  const SizedBox(width: 8),
                  Text(Fmt.percent(ratio), style: text.bodySmall?.copyWith(color: AppColors.textMuted)),
                ],
              ),
              const Divider(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _Fact('Falta', Fmt.money(p.remaining)),
                  _Fact('Data', p.targetDate == null ? 'Sem data' : Fmt.date(p.targetDate!)),
                  if (plan.perMonth != null) _Fact('Guardar/mês', Fmt.money(plan.perMonth!)),
                  if (plan.perWeek != null) _Fact('Por semana', Fmt.money(plan.perWeek!)),
                  if (plan.perDay != null) _Fact('Por dia', Fmt.money(plan.perDay!)),
                ],
              ),
              if (p.remaining > 0) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.savings_outlined, size: 18),
                    label: const Text('Guardar dinheiro'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      );
}
