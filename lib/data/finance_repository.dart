import 'dart:typed_data';

import '../core/network/api_client.dart';
import '../domain/models/plan_settings.dart';
import '../domain/models/product.dart';
import '../domain/models/transaction.dart';
import 'import_report.dart';

/// Acesso remoto aos dados da planilha: Lançamentos, Produtos e Config.
class FinanceRepository {
  FinanceRepository(this._api);

  final ApiClient _api;

  // Lançamentos
  Future<List<FinanceTransaction>> transactions() async =>
      _list(await _api.get('/transactions/'), FinanceTransaction.fromJson);

  Future<FinanceTransaction> createTransaction(FinanceTransaction t) async =>
      FinanceTransaction.fromJson(await _api.post('/transactions/', body: t.toJson()));

  Future<FinanceTransaction> updateTransaction(FinanceTransaction t) async =>
      FinanceTransaction.fromJson(await _api.put('/transactions/${t.id}', body: t.toJson()));

  Future<void> deleteTransaction(int id) => _api.delete('/transactions/$id');

  // Produtos
  Future<List<Product>> products() async =>
      _list(await _api.get('/products/'), Product.fromJson);

  Future<Product> createProduct(Product p) async =>
      Product.fromJson(await _api.post('/products/', body: p.toJson()));

  Future<Product> updateProduct(Product p) async =>
      Product.fromJson(await _api.put('/products/${p.id}', body: p.toJson()));

  Future<void> deleteProduct(int id) => _api.delete('/products/$id');

  // Config
  Future<PlanSettings> settings() async => PlanSettings.fromJson(await _api.get('/settings/'));

  Future<PlanSettings> saveSettings(PlanSettings s) async =>
      PlanSettings.fromJson(await _api.put('/settings/', body: s.toJson()));

  // Planilha
  Future<ImportReport> importSpreadsheet(Uint8List bytes, String filename, {required bool dryRun}) async =>
      ImportReport.fromJson(await _api.upload(
        '/spreadsheet/import',
        bytes: bytes,
        filename: filename,
        query: {'dry_run': '$dryRun'},
      ));

  Future<Uint8List> exportSpreadsheet() => _api.download('/spreadsheet/export');

  static List<T> _list<T>(dynamic json, T Function(Map<String, dynamic>) parse) =>
      [for (final item in json as List<dynamic>) parse(item as Map<String, dynamic>)];
}
