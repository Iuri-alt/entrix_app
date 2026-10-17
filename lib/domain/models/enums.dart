enum TransactionKind {
  income('income', 'Receita'),
  expense('expense', 'Despesa');

  const TransactionKind(this.code, this.label);
  final String code;
  final String label;

  static TransactionKind fromCode(String code) =>
      values.firstWhere((e) => e.code == code, orElse: () => expense);
}

enum ExpenseGroup {
  fixed('fixed', 'Fixa'),
  variable('variable', 'Variável'),
  other('other', 'Outro compromisso');

  const ExpenseGroup(this.code, this.label);
  final String code;
  final String label;

  static ExpenseGroup? fromCode(String? code) {
    for (final group in values) {
      if (group.code == code) return group;
    }
    return null;
  }
}

enum PaymentStatus {
  paid('paid', 'Pago'),
  pending('pending', 'Pendente');

  const PaymentStatus(this.code, this.label);
  final String code;
  final String label;

  static PaymentStatus fromCode(String code) =>
      values.firstWhere((e) => e.code == code, orElse: () => paid);
}

/// A ordem dos valores é a ordem da fila (Config!F4:F6): Alta → Média → Baixa.
enum Priority {
  high('high', 'Alta'),
  medium('medium', 'Média'),
  low('low', 'Baixa');

  const Priority(this.code, this.label);
  final String code;
  final String label;

  /// `MATCH(prioridade, Config!F4:F6, 0)`.
  int get rank => index + 1;

  static Priority fromCode(String code) =>
      values.firstWhere((e) => e.code == code, orElse: () => low);
}

enum PlanBase {
  forecast('forecast', 'Previsto'),
  actual('actual', 'Realizado');

  const PlanBase(this.code, this.label);
  final String code;
  final String label;

  static PlanBase fromCode(String code) =>
      values.firstWhere((e) => e.code == code, orElse: () => forecast);
}

/// Semáforo usado em toda a planilha (🟢🟡🔴🔵⚪✅).
enum Signal { good, warning, critical, info, neutral }
