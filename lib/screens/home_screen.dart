import 'package:entrix/api/api_service.dart';
import 'package:entrix/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:entrix/models/expense_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> expenses = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  // 📥 Carregar gastos
  Future<void> loadExpenses() async {
    try {
      setState(() => isLoading = true);

      final data = await ApiService.getExpenses();

      setState(() {
        expenses = data.map((e) => Expense.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Erro ao carregar despesas: $e');
    }
  }

  // ➕ Adicionar gasto
  Future<void> addExpense(
      String title,
      double value,
      bool isIncome,
      DateTime date,
      ) async {
    try {
      final newExpense = Expense(
        id: null,
        title: title,
        value: value,
        isIncome: isIncome,
        date: date,
      );

      await ApiService.addExpense(newExpense);
      await loadExpenses();
    } catch (e) {
      debugPrint('Erro ao adicionar gasto: $e');
    }
  }

  // 🗑️ Remover gasto
  Future<void> removeExpense(Expense expense) async {
    try {
      if (expense.id == null) return;

      await ApiService.deleteExpense(expense.id!);

      setState(() {
        expenses.removeWhere((e) => e.id == expense.id);
      });
    } catch (e) {
      debugPrint('Erro ao remover: $e');
    }
  }

  // 📅 Formatar data
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // 🔍 Filtrar por mês
  List<Expense> get filteredExpenses {
    return expenses.where((e) {
      return e.date != null &&
          e.date.month == selectedDate.month &&
          e.date.year == selectedDate.year;
    }).toList();
  }

  // 💰 Entradas
  double get totalIncome {
    return filteredExpenses
        .where((e) => e.isIncome)
        .fold(0.0, (sum, e) => sum + e.value);
  }

  // 💸 Gastos
  double get totalExpense {
    return filteredExpenses
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, e) => sum + e.value);
  }

  // 💵 Saldo
  double get balance => totalIncome - totalExpense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3D),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2A49),
        foregroundColor: Colors.white,
        title: const Text('Controle de gastos'),
        actions: [
          // 📅 filtro mês
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2030),
              );

              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                });
              }
            },
          ),
        ],
      ),

      // ➕ ADD EXPENSE
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1DB954),
        child: const Icon(Icons.add, color: Colors.white,),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              final titleController = TextEditingController();
              final valueController = TextEditingController();
              bool isIncome = false;

              return StatefulBuilder(
                builder: (context, setStateDialog) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF1B2A49),
                    title: const Text(
                      'Adicionar transação',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextField(
                          controller: valueController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Valor',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                        SwitchListTile(
                          title: const Text(
                            'É entrada?',
                            style: TextStyle(color: Colors.white),
                          ),
                          value: isIncome,
                          onChanged: (value) {
                            setStateDialog(() {
                              isIncome = value;
                            });
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DB954),
                        ),
                        onPressed: () async {
                          if (titleController.text.isEmpty ||
                              valueController.text.isEmpty) {
                            return;
                          }
                          final value =
                              double.tryParse(valueController.text) ?? 0;
                          if (value <= 0) return;
                          await addExpense(
                            titleController.text,
                            value,
                            isIncome,
                            selectedDate,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Adicionar',
                          style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),

      // 📋 BODY
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 💰 SALDO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saldo Atual',
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(
                    'R\$ ${balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📋 LISTA
            Expanded(
              child: ListView.builder(
                itemCount: filteredExpenses.length,
                itemBuilder: (context, index) {
                  final e = filteredExpenses[index];

                  return Dismissible(
                    key: ValueKey(e.id ?? index),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete,
                          color: Colors.white),
                    ),
                    onDismissed: (_) {
                      removeExpense(e);
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        e.isIncome ? Colors.green : Colors.red,
                        child: Icon(
                          e.isIncome
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        e.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        formatDate(e.date),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        '${e.isIncome ? '+' : '-'} R\$ ${e.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          color:
                          e.isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              },
              child: const Text(
                'Voltar para login',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
