import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../domain/calc/finance_plan.dart';
import '../../../state/finance_store.dart';
import '../../widgets/feedback.dart';
import '../../widgets/kpi_tile.dart';
import '../../widgets/period_slicer.dart';
import '../../widgets/section_card.dart';
import '../../widgets/signal_badge.dart';
import 'cash_visuals.dart';
import 'dashboard_data.dart';
import 'dashboard_period.dart';
import 'plan_visuals.dart';
import 'summary_alerts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardPeriod _period;
  DashboardData? _data;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _period = DashboardPeriod(today.year, today.month);
  }

  /// Reaproveita as agregações enquanto o plano e o filtro não mudam.
  DashboardData _dataFor(FinancePlan plan) {
    final cached = _data;
    if (cached != null && identical(cached.plan, plan) && cached.period == _period) return cached;
    return _data = DashboardData(plan, _period);
  }

  void _setPeriod(int year, int? month) => setState(() => _period = DashboardPeriod(year, month));

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final plan = store.plan;
        final data = _dataFor(plan);
        return RefreshIndicator(
          onRefresh: () async {
            await store.load();
            if (store.status == LoadStatus.error && context.mounted) {
              showMessage(context, store.error ?? 'Falha ao atualizar', error: true);
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: const Text('Painel'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 12, 8),
                    child: PeriodSlicer(
                      year: _period.year,
                      month: _period.month,
                      years: plan.availableYears,
                      onChanged: _setPeriod,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.list(
                  children: [
                    _KpiRow(data: data),
                    const SizedBox(height: 12),
                    ResponsiveGrid(
                      minItemWidth: 420,
                      maxColumns: 2,
                      children: [
                        IncomeExpenseChart(
                          data: data,
                          onSelectMonth: (m) => _setPeriod(_period.year, m),
                        ),
                        AccumulatedBalanceChart(data: data),
                        CategoryRanking(data: data),
                        ExpenseGroupDonut(data: data),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Planejamento de compras',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _PlanKpiRow(plan: plan),
                    const SizedBox(height: 12),
                    ResponsiveGrid(
                      minItemWidth: 420,
                      maxColumns: 2,
                      children: [
                        _AlertsCard(plan: plan, data: data),
                        GoalProgressVisual(plan: plan),
                        SavingsScheduleChart(
                          plan: plan,
                          highlight: _period.isWholeYear
                              ? null
                              : DateTime(_period.year, _period.month!),
                        ),
                        PriorityMoneyVisual(plan: plan),
                        ProductPriceVisual(plan: plan),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = data.totals;
    return ResponsiveGrid(
      minItemWidth: 170,
      maxColumns: 4,
      children: [
        KpiTile(
          label: 'Receitas',
          value: Fmt.money(t.income),
          caption: data.period.label,
          icon: Icons.south_west_rounded,
          accent: ChartColors.income,
        ),
        KpiTile(
          label: 'Despesas',
          value: Fmt.money(t.expenses),
          caption: '${t.count} lançamento(s)',
          icon: Icons.north_east_rounded,
          accent: ChartColors.expense,
        ),
        KpiTile(
          label: 'Saldo',
          value: Fmt.money(t.balance),
          caption: data.situation.label,
          icon: Icons.account_balance_wallet_outlined,
          accent: AppColors.signal(data.situation.signal),
        ),
        KpiTile(
          label: 'Despesas pendentes',
          value: Fmt.money(t.pending),
          caption: 'Ainda não pagas',
          icon: Icons.pending_actions_rounded,
          accent: t.pending > 0 ? AppColors.warning : AppColors.textMuted,
        ),
      ],
    );
  }
}

class _PlanKpiRow extends StatelessWidget {
  const _PlanKpiRow({required this.plan});

  final FinancePlan plan;

  @override
  Widget build(BuildContext context) {
    final situation = plan.incomeSituation;
    return ResponsiveGrid(
      minItemWidth: 170,
      maxColumns: 4,
      children: [
        KpiTile(
          label: 'Total dos produtos',
          value: Fmt.money(plan.totalProducts),
          caption: '${plan.products.length} produto(s)',
          icon: Icons.shopping_bag_outlined,
        ),
        KpiTile(
          label: 'Falta guardar',
          value: Fmt.money(plan.totalMissing),
          caption: 'Já guardado: ${Fmt.money(plan.totalSaved)}',
          icon: Icons.savings_outlined,
        ),
        KpiTile(
          label: 'Mínimo mensal (prioridade)',
          value: Fmt.money(plan.minimumMonthly),
          caption: 'Para cumprir todos os prazos',
          icon: Icons.flag_outlined,
          accent: AppColors.info,
        ),
        KpiTile(
          label: 'Economia disponível/mês',
          value: Fmt.money(plan.available),
          caption: situation.label,
          icon: Icons.trending_up_rounded,
          accent: AppColors.signal(situation.signal),
        ),
      ],
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.plan, required this.data});

  final FinancePlan plan;
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final product = plan.productAlerts;
    return SectionCard(
      title: 'Alertas automáticos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final a in summaryAlerts(plan, data)) AlertLine(signal: a.signal, message: a.message),
          if (product.isNotEmpty) ...[
            const Divider(height: 20),
            const Text('Por produto', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            for (final a in product)
              AlertLine(signal: productAlertSignal(a), message: productAlertText(a)),
          ],
        ],
      ),
    );
  }
}
