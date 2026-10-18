import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/finance_repository.dart';
import '../data/import_report.dart';
import '../domain/calc/finance_plan.dart';
import '../domain/models/plan_settings.dart';
import '../domain/models/product.dart';
import '../domain/models/transaction.dart';

enum LoadStatus { idle, loading, ready, error }

/// Fonte única dos dados do usuário. Toda alteração passa pelo servidor e,
/// depois de confirmada, atualiza a lista local e invalida os cálculos.
class FinanceStore extends ChangeNotifier {
  FinanceStore(this._repository);

  final FinanceRepository _repository;

  LoadStatus _status = LoadStatus.idle;
  bool _ready = false;
  String? _error;
  PlanSettings? _settings;
  List<Product> _products = const [];
  List<FinanceTransaction> _transactions = const [];
  FinancePlan? _plan;

  LoadStatus get status => _status;
  String? get error => _error;
  bool get isReady => _ready;
  PlanSettings get settings => _settings!;
  List<Product> get products => _products;

  /// Mais recentes primeiro.
  List<FinanceTransaction> get transactions => _transactions;

  /// Recalculado só quando algum dado muda.
  FinancePlan get plan => _plan ??= FinancePlan(
        settings: settings,
        products: _products,
        transactions: _transactions,
      );

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.settings(),
        _repository.products(),
        _repository.transactions(),
      ]);
      _settings = results[0] as PlanSettings;
      _products = results[1] as List<Product>;
      _transactions = _sorted(results[2] as List<FinanceTransaction>);
      _status = LoadStatus.ready;
      _ready = true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = LoadStatus.error;
    } catch (e) {
      // Dados num formato inesperado: mostra o erro em vez de carregar para sempre.
      _error = 'Não foi possível ler os dados recebidos ($e).';
      _status = LoadStatus.error;
    }
    _changed();
  }

  /// Esquece os dados do usuário ao sair. A configuração fica em memória até o
  /// próximo carregamento para que telas ainda em animação de saída não quebrem.
  void clear() {
    _status = LoadStatus.idle;
    _ready = false;
    _products = const [];
    _transactions = const [];
    _changed();
  }

  // ---------- Lançamentos ----------
  Future<void> saveTransaction(FinanceTransaction t) async {
    final saved = t.id == null
        ? await _repository.createTransaction(t)
        : await _repository.updateTransaction(t);
    _transactions = _sorted([..._transactions.where((e) => e.id != saved.id), saved]);
    _changed();
  }

  Future<void> deleteTransaction(FinanceTransaction t) async {
    await _repository.deleteTransaction(t.id!);
    _transactions = _transactions.where((e) => e.id != t.id).toList(growable: false);
    _changed();
  }

  // ---------- Produtos ----------
  Future<void> saveProduct(Product p) async {
    if (p.id == null) {
      _products = [..._products, await _repository.createProduct(p)];
    } else {
      final saved = await _repository.updateProduct(p);
      _products = [for (final e in _products) e.id == saved.id ? saved : e];
    }
    _changed();
  }

  Future<void> deleteProduct(Product p) async {
    await _repository.deleteProduct(p.id!);
    _products = _products.where((e) => e.id != p.id).toList(growable: false);
    _changed();
  }

  // ---------- Config ----------
  Future<void> saveSettings(PlanSettings s) async {
    _settings = await _repository.saveSettings(s);
    _changed();
  }

  // ---------- Planilha ----------
  Future<ImportReport> importSpreadsheet(Uint8List bytes, String filename, {required bool dryRun}) async {
    final report = await _repository.importSpreadsheet(bytes, filename, dryRun: dryRun);
    if (!dryRun && report.hasChanges) await load();
    return report;
  }

  Future<Uint8List> exportSpreadsheet() => _repository.exportSpreadsheet();

  void _changed() {
    _plan = null;
    notifyListeners();
  }

  static List<FinanceTransaction> _sorted(List<FinanceTransaction> items) {
    final copy = [...items];
    copy.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : (b.id ?? 0).compareTo(a.id ?? 0);
    });
    return List.unmodifiable(copy);
  }
}
