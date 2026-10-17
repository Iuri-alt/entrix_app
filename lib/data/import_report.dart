class ImportIssue {
  const ImportIssue(this.sheet, this.row, this.message);
  final String sheet;
  final int row;
  final String message;

  factory ImportIssue.fromJson(Map<String, dynamic> json) =>
      ImportIssue(json['sheet'] as String, json['row'] as int, json['message'] as String);
}

class ImportReport {
  const ImportReport({
    required this.dryRun,
    required this.transactionsNew,
    required this.transactionsDuplicated,
    required this.productsNew,
    required this.productsDuplicated,
    required this.settingsUpdated,
    required this.errors,
    required this.warnings,
  });

  final bool dryRun;
  final int transactionsNew;
  final int transactionsDuplicated;
  final int productsNew;
  final int productsDuplicated;
  final bool settingsUpdated;
  final List<ImportIssue> errors;
  final List<ImportIssue> warnings;

  bool get hasChanges => transactionsNew + productsNew > 0 || settingsUpdated;

  factory ImportReport.fromJson(Map<String, dynamic> json) {
    List<ImportIssue> issues(String key) => [
          for (final e in json[key] as List<dynamic>) ImportIssue.fromJson(e as Map<String, dynamic>),
        ];
    return ImportReport(
      dryRun: json['dry_run'] as bool,
      transactionsNew: json['transactions_new'] as int,
      transactionsDuplicated: json['transactions_duplicated'] as int,
      productsNew: json['products_new'] as int,
      productsDuplicated: json['products_duplicated'] as int,
      settingsUpdated: json['settings_updated'] as bool,
      errors: issues('errors'),
      warnings: issues('warnings'),
    );
  }
}
