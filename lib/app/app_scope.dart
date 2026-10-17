import 'package:flutter/widgets.dart';

import '../state/finance_store.dart';
import '../state/session_controller.dart';

/// Disponibiliza os controladores para a árvore de widgets.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.session,
    required this.store,
    required super.child,
  });

  final SessionController session;
  final FinanceStore store;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado na árvore');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      session != oldWidget.session || store != oldWidget.store;
}

extension AppScopeContext on BuildContext {
  FinanceStore get store => AppScope.of(this).store;
  SessionController get session => AppScope.of(this).session;
}
