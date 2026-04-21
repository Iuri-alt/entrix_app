class Expense {
  final String? id;
  final String title;
  final double value;
  final bool isIncome;
  final DateTime date;

  Expense({
    this.id,
    required this.title,
    required this.value,
    required this.isIncome,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString(), // ✔ CORRIGIDO
      title: json['title'] ?? '',
      value: (json['value'] ?? 0).toDouble(), // ✔ SAFE
      isIncome: json['isIncome'] ?? false,     // ✔ SAFE
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': value,
      'isIncome': isIncome,
      'date': date.toIso8601String(),
    };
  }
}
