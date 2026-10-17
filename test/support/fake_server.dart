import 'dart:convert';

import 'package:entrix/core/network/api_client.dart';
import 'package:entrix/core/storage/token_storage.dart';
import 'package:entrix/data/auth_repository.dart';
import 'package:entrix/data/finance_repository.dart';
import 'package:entrix/state/finance_store.dart';
import 'package:entrix/state/session_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Servidor em memória que imita a API Entrix (FastAPI) para testes.
class FakeServer {
  FakeServer({Map<String, dynamic>? settings}) : settings = settings ?? defaultSettings();

  static const validToken = 'token-valido';
  static const email = 'ana@example.com';
  static const password = 'segredo123';

  Map<String, dynamic> settings;
  final Map<int, Map<String, dynamic>> transactions = {};
  final Map<int, Map<String, dynamic>> products = {};
  int _nextId = 1;
  bool expireTokens = false;
  final List<String> requests = [];

  static Map<String, dynamic> defaultSettings() => {
        'today_override': null,
        'plan_start': '2026-10-01',
        'plan_end': '2027-12-31',
        'days_soon': 30,
        'tight_limit': 0.7,
        'budget_income': 0,
        'budget_fixed': 0,
        'budget_variable': 0,
        'budget_other': 0,
        'plan_base': 'forecast',
        'scenarios': [300, 500, 700, 1000],
        'product_categories': ['Música', 'Computador', 'Outros'],
        'income_categories': ['Salário', 'Renda extra', 'Outras receitas'],
        'expense_categories': ['Alimentação', 'Lazer', 'Outros'],
      };

  int addTransaction(Map<String, dynamic> body) {
    final id = _nextId++;
    transactions[id] = {...body, 'id': id};
    return id;
  }

  int addProduct(Map<String, dynamic> body) {
    final id = _nextId++;
    products[id] = {...body, 'id': id};
    return id;
  }

  late final http.Client client = MockClient((request) async {
    requests.add('${request.method} ${request.url.path}');
    final path = request.url.path;
    Map<String, dynamic> body() => jsonDecode(request.body) as Map<String, dynamic>;
    http.Response json(Object? data, [int status = 200]) => http.Response(
          jsonEncode(data),
          status,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );

    if (path == '/auth/login') {
      final b = body();
      return b['email'] == email && b['password'] == password
          ? json({'access_token': validToken, 'token_type': 'bearer'})
          : json({'detail': 'Email ou senha inválidos'}, 401);
    }
    if (path == '/auth/register') return json({'id': 1, 'email': body()['email']}, 201);

    if (expireTokens || request.headers['Authorization'] != 'Bearer $validToken') {
      return json({'detail': 'Sessão inválida ou expirada. Faça login novamente.'}, 401);
    }

    if (path == '/settings/') {
      if (request.method == 'PUT') settings = body();
      return json(settings);
    }

    for (final (prefix, store) in [('/transactions/', transactions), ('/products/', products)]) {
      if (!path.startsWith(prefix)) continue;
      final rest = path.substring(prefix.length);
      if (rest.isEmpty) {
        if (request.method == 'GET') return json(store.values.toList());
        final id = _nextId++;
        store[id] = {...body(), 'id': id};
        return json(store[id], 201);
      }
      final id = int.parse(rest);
      if (!store.containsKey(id)) return json({'detail': 'Não encontrado'}, 404);
      if (request.method == 'DELETE') {
        store.remove(id);
        return http.Response('', 204);
      }
      store[id] = {...body(), 'id': id};
      return json(store[id]);
    }
    return json({'detail': 'Not Found'}, 404);
  });

  /// Monta os controladores reais apontando para este servidor.
  ({SessionController session, FinanceStore store}) wire() {
    final tokens = TokenStorage();
    final api = ApiClient(baseUrl: 'http://fake', tokens: tokens, httpClient: client);
    final session = SessionController(AuthRepository(api, tokens));
    api.onUnauthorized = session.expire;
    return (session: session, store: FinanceStore(FinanceRepository(api)));
  }
}
