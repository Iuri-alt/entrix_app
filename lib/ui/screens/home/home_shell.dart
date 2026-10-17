import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../state/finance_store.dart';
import '../../widgets/brand.dart';
import '../../widgets/feedback.dart';
import '../dashboard/dashboard_screen.dart';
import '../planning/planning_screen.dart';
import '../products/products_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.builder);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

final _destinations = [
  _Destination('Painel', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded,
      (_) => const DashboardScreen()),
  _Destination('Lançamentos', Icons.receipt_long_outlined, Icons.receipt_long_rounded,
      (_) => const TransactionsScreen()),
  _Destination('Produtos', Icons.shopping_bag_outlined, Icons.shopping_bag_rounded,
      (_) => const ProductsScreen()),
  _Destination('Planejamento', Icons.insights_outlined, Icons.insights_rounded,
      (_) => const PlanningScreen()),
  _Destination('Ajustes', Icons.tune_outlined, Icons.tune_rounded,
      (_) => const SettingsScreen()),
];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// Abas só são construídas na primeira visita e depois mantêm o estado.
  final _visited = <int>{0};

  void _select(int index) => setState(() {
        _index = index;
        _visited.add(index);
      });

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final body = ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.isReady) {
          if (store.status == LoadStatus.error) {
            return ErrorState(message: store.error ?? '', onRetry: store.load);
          }
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando seus dados…'),
                SizedBox(height: 4),
                Text('O primeiro acesso do dia pode levar até 1 minuto.',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }
        return IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _destinations.length; i++)
              _visited.contains(i)
                  ? _destinations[i].builder(context)
                  : const SizedBox.shrink(),
          ],
        );
      },
    );

    if (wide) {
      final extended = MediaQuery.sizeOf(context).width >= 1200;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: extended,
              selectedIndex: _index,
              onDestinationSelected: _select,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: extended
                    ? const BrandLockup(markSize: 40, textSize: 20, vertical: false)
                    : const BrandMark(size: 40),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
