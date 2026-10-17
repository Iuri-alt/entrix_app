import '../../../domain/models/enums.dart';
import '../../../domain/models/transaction.dart';

class TransactionFilter {
  const TransactionFilter({
    required this.year,
    this.month,
    this.allTime = false,
    this.kind,
    this.pendingOnly = false,
    this.category,
    this.query = '',
  });

  final int year;
  final int? month;
  final bool allTime;
  final TransactionKind? kind;
  final bool pendingOnly;
  final String? category;
  final String query;

  bool get hasExtraFilters => kind != null || pendingOnly || category != null || query.isNotEmpty;

  bool matches(FinanceTransaction t) {
    if (!allTime) {
      if (t.date.year != year) return false;
      if (month != null && t.date.month != month) return false;
    }
    if (kind != null && t.kind != kind) return false;
    if (pendingOnly && !t.isPending) return false;
    if (category != null && t.category != category) return false;
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      if (!t.description.toLowerCase().contains(q) && !t.category.toLowerCase().contains(q)) {
        return false;
      }
    }
    return true;
  }

  TransactionFilter copyWith({
    int? year,
    int? month,
    bool clearMonth = false,
    bool? allTime,
    TransactionKind? kind,
    bool clearKind = false,
    bool? pendingOnly,
    String? category,
    bool clearCategory = false,
    String? query,
  }) =>
      TransactionFilter(
        year: year ?? this.year,
        month: clearMonth ? null : month ?? this.month,
        allTime: allTime ?? this.allTime,
        kind: clearKind ? null : kind ?? this.kind,
        pendingOnly: pendingOnly ?? this.pendingOnly,
        category: clearCategory ? null : category ?? this.category,
        query: query ?? this.query,
      );

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.year == year &&
      other.month == month &&
      other.allTime == allTime &&
      other.kind == kind &&
      other.pendingOnly == pendingOnly &&
      other.category == category &&
      other.query == query;

  @override
  int get hashCode => Object.hash(year, month, allTime, kind, pendingOnly, category, query);
}
