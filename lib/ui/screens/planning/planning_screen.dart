import 'package:flutter/material.dart';

import 'cash_flow_tab.dart';
import 'income_tab.dart';
import 'per_product_tab.dart';
import 'priorities_tab.dart';
import 'schedule_tab.dart';
import 'simulation_tab.dart';

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  static const _tabs = [
    ('Fluxo de caixa', CashFlowTab()),
    ('Renda', IncomeTab()),
    ('Por produto', PerProductTab()),
    ('Cronograma', ScheduleTab()),
    ('Prioridades', PrioritiesTab()),
    ('Simulação', SimulationTab()),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Planejamento'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final (label, _) in _tabs) Tab(text: label)],
          ),
        ),
        body: TabBarView(children: [for (final (_, tab) in _tabs) tab]),
      ),
    );
  }
}
