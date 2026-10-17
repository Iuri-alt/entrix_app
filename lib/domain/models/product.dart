import '../../core/utils/month.dart';
import 'enums.dart';

/// Linha da aba Produtos.
class Product {
  Product({
    this.id,
    required this.name,
    this.category = '',
    required this.price,
    this.priority = Priority.medium,
    DateTime? targetDate,
    this.saved = 0,
  }) : targetDate = targetDate == null ? null : Month.day(targetDate);

  final int? id;
  final String name;
  final String category;
  final double price;
  final Priority priority;
  final DateTime? targetDate;
  final double saved;

  /// `Falta guardar = MAX(0, preço − guardado)`.
  double get remaining => (price - saved) < 0 ? 0 : price - saved;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int?,
        name: json['name'] as String,
        category: (json['category'] as String?) ?? '',
        price: (json['price'] as num).toDouble(),
        priority: Priority.fromCode(json['priority'] as String),
        targetDate: json['target_date'] == null
            ? null
            : DateTime.parse(json['target_date'] as String),
        saved: (json['saved'] as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'price': price,
        'priority': priority.code,
        'target_date': targetDate == null ? null : isoDate(targetDate!),
        'saved': saved,
      };

  Product copyWith({double? saved}) => Product(
        id: id,
        name: name,
        category: category,
        price: price,
        priority: priority,
        targetDate: targetDate,
        saved: saved ?? this.saved,
      );
}
