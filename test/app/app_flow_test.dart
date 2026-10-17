import 'package:entrix/app/app.dart';
import 'package:entrix/core/format/formatters.dart';
import 'package:entrix/ui/widgets/brand.dart';
import 'package:entrix/ui/widgets/kpi_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_server.dart';

Future<FakeServer> _pumpApp(WidgetTester tester, {FakeServer? server, bool loggedIn = true}) async {
  SharedPreferences.setMockInitialValues(loggedIn ? {'token': FakeServer.validToken} : {});
  server ??= FakeServer();
  final wired = server.wire();
  await tester.pumpWidget(EntrixApp(session: wired.session, store: wired.store));
  await tester.pumpAndSettle();
  return server;
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void _desktop(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('sem sessão mostra login; credenciais erradas mostram erro', (tester) async {
    _phone(tester);
    await _pumpApp(tester, loggedIn: false);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byType(BrandMark), findsOneWidget, reason: 'logo no login');

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), FakeServer.email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'errada123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Email ou senha inválidos'), findsOneWidget);
  });

  testWidgets('login válido abre o painel', (tester) async {
    _phone(tester);
    await _pumpApp(tester, loggedIn: false);
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), FakeServer.email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), FakeServer.password);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Painel'), findsWidgets);
    expect(find.text('Receitas × despesas por mês'), findsOneWidget);
  });

  testWidgets('lança despesa de um ano anterior e ela persiste ao reabrir o app', (tester) async {
    _phone(tester);
    final server = await _pumpApp(tester);

    await tester.tap(find.text('Lançamentos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Lançamento'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o valor'), findsOneWidget);
    expect(find.text('Informe a descrição'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Valor'), '1.234,56');
    await tester.enterText(find.widgetWithText(TextFormField, 'Descrição'), 'IPVA antigo');
    await tester.tap(find.text('Categoria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outros').last);
    await tester.pumpAndSettle();

    // Data: digita 15/03/2019 no seletor de data.
    await tester.tap(find.text('Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '15/03/2019');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(server.transactions.values.single['date'], '2019-03-15');
    expect(server.transactions.values.single['amount'], 1234.56);

    // Reabre o app: os dados vêm do servidor.
    await tester.pumpWidget(const SizedBox());
    await _pumpApp(tester, server: server);
    await tester.tap(find.text('Lançamentos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ver todo o histórico'));
    await tester.pumpAndSettle();
    expect(find.text('IPVA antigo'), findsOneWidget);
    expect(find.text('15/03/2019'), findsOneWidget);
  });

  testWidgets('excluir lançamento pede confirmação', (tester) async {
    _phone(tester);
    final server = FakeServer();
    final now = DateTime.now();
    server.addTransaction({
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-01',
      'description': 'Mercado',
      'kind': 'expense',
      'expense_group': 'variable',
      'category': 'Alimentação',
      'amount': 50,
      'status': 'paid',
    });
    await _pumpApp(tester, server: server);
    await tester.tap(find.text('Lançamentos').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mais ações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir lançamento?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(server.transactions, hasLength(1));

    await tester.tap(find.byTooltip('Mais ações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(server.transactions, isEmpty);
    expect(find.text('Mercado'), findsNothing);
  });

  testWidgets('cadastra produto e guarda dinheiro', (tester) async {
    _phone(tester);
    final server = await _pumpApp(tester);
    await tester.tap(find.text('Produtos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Produto'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Produto'), 'Teclado');
    await tester.enterText(find.widgetWithText(TextFormField, 'Preço'), '1000');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(server.products.values.single['name'], 'Teclado');
    expect(find.text('Teclado'), findsOneWidget);

    await tester.tap(find.text('Guardar dinheiro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Valor'), '250');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(server.products.values.single['saved'], 250);
    expect(find.text('${Fmt.money(250)} de ${Fmt.money(1000)}'), findsOneWidget);
  });

  testWidgets('sessão expirada volta para o login', (tester) async {
    _phone(tester);
    final server = await _pumpApp(tester);
    server.expireTokens = true;
    await tester.tap(find.text('Produtos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Produto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Produto'), 'X');
    await tester.enterText(find.widgetWithText(TextFormField, 'Preço'), '10');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('desktop: navegação lateral e todas as abas de planejamento', (tester) async {
    _desktop(tester);
    final server = FakeServer();
    server.addProduct({
      'name': 'Korg', 'category': 'Música', 'price': 6000, 'priority': 'medium',
      'target_date': '2027-01-10', 'saved': 110,
    });
    server.addProduct({
      'name': 'Sem data', 'category': 'Outros', 'price': 100, 'priority': 'low',
      'target_date': null, 'saved': 0,
    });
    await _pumpApp(tester, server: server);
    expect(find.byType(NavigationRail), findsOneWidget);

    await tester.tap(find.text('Planejamento'));
    await tester.pumpAndSettle();
    for (final tab in ['Renda', 'Por produto', 'Cronograma', 'Prioridades', 'Simulação', 'Fluxo de caixa']) {
      await tester.tap(find.widgetWithText(Tab, tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Importar planilha'), findsOneWidget);
  });

  testWidgets('filtro do painel troca mês e ano', (tester) async {
    _phone(tester);
    final server = FakeServer();
    server.addTransaction({
      'date': '2025-02-10', 'description': 'Salário', 'kind': 'income', 'expense_group': null,
      'category': 'Salário', 'amount': 3000, 'status': 'paid',
    });
    await _pumpApp(tester, server: server);
    await tester.tap(find.byTooltip('Escolher ano'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2025').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'fev'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'fev'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.widgetWithText(KpiTile, 'Receitas'), matching: find.text(Fmt.money(3000))),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.widgetWithText(KpiTile, 'Despesas'), matching: find.text(Fmt.money(0))),
      findsOneWidget,
    );
    expect(find.text('Fevereiro de 2025'), findsWidgets);
  });
}
