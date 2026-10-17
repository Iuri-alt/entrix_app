import 'package:entrix/domain/models/enums.dart';
import 'package:entrix/domain/models/plan_settings.dart';
import 'package:entrix/domain/models/product.dart';
import 'package:entrix/domain/models/transaction.dart';

/// Dados de entrada de Controle_Financeiro_2026-2027.xlsx (abas Config, Produtos,
/// Lançamentos e Renda), com `Hoje` = 17/10/2026, data em que os valores foram calculados.
final spreadsheetToday = DateTime(2026, 10, 17);

final spreadsheetSettings = PlanSettings(
  planStart: DateTime(2026, 10),
  planEnd: DateTime(2027, 12, 31),
  daysSoon: 30,
  tightLimit: 0.7,
  // Renda!B5 está como texto na planilha e o disponível previsto (B9) é 0.
  budgetIncome: 0,
  planBase: PlanBase.forecast,
  scenarios: const [300, 500, 700, 1000],
  expenseCategories: const [
    'Moradia', 'Alimentação', 'Transporte', 'Saúde', 'Educação', 'Lazer',
    'Assinaturas', 'Vestuário', 'Cartão/Dívidas', 'Presentes e doações',
    'Impostos e taxas', 'Pets', 'Viagens', 'Cuidados pessoais', 'Outros',
  ],
  incomeCategories: const ['Salário', 'Renda extra', 'Outras receitas'],
);

final spreadsheetProducts = [
  Product(name: 'Korg Kronos 2', category: 'Música', price: 6000, priority: Priority.medium, targetDate: DateTime(2027, 1, 10), saved: 110),
  Product(name: 'Ryzen 7 5200x', category: 'Computador', price: 1020, priority: Priority.high, targetDate: DateTime(2026, 11, 10)),
  Product(name: 'Seminario Jian', category: 'Lazer', price: 260, priority: Priority.medium, targetDate: DateTime(2026, 11, 10)),
  Product(name: 'Estante Bateria', category: 'Música', price: 450, priority: Priority.medium, targetDate: DateTime(2026, 11, 10)),
  Product(name: 'Memoria RAM', category: 'Computador', price: 2000, priority: Priority.high, targetDate: DateTime(2027, 1, 10)),
  Product(name: 'Roupa', category: 'Vestuário', price: 1000, priority: Priority.high, targetDate: DateTime(2026, 12, 10)),
];

FinanceTransaction _t(int day, String description, TransactionKind kind, ExpenseGroup? group,
        String category, double amount, PaymentStatus status) =>
    FinanceTransaction(
      date: DateTime(2026, 10, day),
      description: description,
      kind: kind,
      group: kind == TransactionKind.income ? null : group,
      category: category,
      amount: amount,
      status: status,
    );

const _exp = TransactionKind.expense;
const _inc = TransactionKind.income;
const _fixed = ExpenseGroup.fixed;
const _var = ExpenseGroup.variable;
const _other = ExpenseGroup.other;
const _paid = PaymentStatus.paid;
const _pending = PaymentStatus.pending;

final spreadsheetTransactions = [
  _t(8, 'Kung Fu', _exp, _fixed, 'Lazer', 160, _paid),
  _t(8, 'Faculdade', _exp, _fixed, 'Educação', 208.17, _paid),
  _t(8, 'Fatura Nubank', _exp, _var, 'Cartão/Dívidas', 766.25, _paid),
  _t(8, 'Pagamento', _exp, _other, 'Cartão/Dívidas', 500, _paid),
  _t(8, 'Aluguel garagem', _exp, _fixed, 'Outras receitas', 200, _pending),
  _t(24, 'Aula de Bateria', _exp, _fixed, 'Lazer', 220, _pending),
  _t(7, 'Salario', _inc, _var, 'Salário', 2568.19, _paid),
  _t(6, 'Tim', _exp, _fixed, 'Assinaturas', 126, _paid),
  _t(6, 'Mercado Pago', _exp, _var, 'Cartão/Dívidas', 92.94, _paid),
  _t(8, 'Prova Substitutiva', _exp, _other, 'Educação', 62, _paid),
  _t(8, 'Brinquedo', _exp, _other, 'Presentes e doações', 169.99, _paid),
  _t(8, 'Estacionamento', _exp, _other, 'Outros', 33, _paid),
  _t(8, 'Pastel', _exp, _other, 'Alimentação', 21, _paid),
  _t(8, 'Uber', _exp, _var, 'Transporte', 77.99, _paid),
  _t(8, 'Oxxo', _exp, _fixed, 'Alimentação', 7.99, _paid),
  _t(8, 'Investimento', _inc, _fixed, 'Renda extra', 100, _paid),
];
