import '../../core/utils/month.dart';
import 'enums.dart';

/// Linha da aba Lançamentos.
class FinanceTransaction {
  FinanceTransaction({
    this.id,
    required DateTime date,
    required this.description,
    required this.kind,
    this.group,
    required this.category,
    required this.amount,
    this.status = PaymentStatus.paid,
  }) : date = Month.day(date);

  final int? id;
  final DateTime date;
  final String description;
  final TransactionKind kind;
  final ExpenseGroup? group;
  final String category;
  final double amount;
  final PaymentStatus status;

  bool get isIncome => kind == TransactionKind.income;
  bool get isExpense => kind == TransactionKind.expense;
  bool get isPending => status == PaymentStatus.pending;

  /// Coluna "Mês (auto)".
  DateTime get month => Month.start(date);

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) => FinanceTransaction(
        id: json['id'] as int?,
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String,
        kind: TransactionKind.fromCode(json['kind'] as String),
        group: ExpenseGroup.fromCode(json['expense_group'] as String?),
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        status: PaymentStatus.fromCode(json['status'] as String),
      );

  Map<String, dynamic> toJson() => {
        'date': isoDate(date),
        'description': description,
        'kind': kind.code,
        'expense_group': isIncome ? null : group?.code,
        'category': category,
        'amount': amount,
        'status': status.code,
      };
}
