import 'dart:convert';
import 'package:entrix/api/auth_service.dart';
import 'package:entrix/models/expense_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://entrix-api.onrender.com";

  // 🔐 LOGIN
  static Future<Map<String, dynamic>?> login(String email,
      String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // 🧾 REGISTER
  static Future<bool> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    throw Exception(response.body);
  }

  // 📊 GET EXPENSES
  static Future<List> getExpenses() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/expenses/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");


    return [];
  }

  // ➕ ADD EXPENSE
  static Future<void> addExpense(Expense expense) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/expenses/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': expense.title,
        'value': expense.value,
        'isIncome': expense.isIncome
      }),
    );

    print("ADD STATUS: ${response.statusCode}");
    print("ADD BODY: ${response.body}");
  }


  // 🗑️ DELETE
  static Future<void> deleteExpense(String id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/expenses/$id'),
      headers: {
        'Authorization': 'Bearer $token', //
      },
    );

    print("DELETE STATUS: ${response.statusCode}");
    print("DELETE BODY: ${response.body}");
  }
}
