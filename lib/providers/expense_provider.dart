import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';

class ExpenseProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  Future<void> loadExpenses() async {
    _expenses = _hiveService.getAllExpenses().cast<Expense>();
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _hiveService.addExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(int key) async {
    await _hiveService.deleteExpense(key);
    await loadExpenses();
  }

  Future<void> clearAll() async {
    await _hiveService.clearAll();
    await loadExpenses();
  }

  double get todayExpensesTotal {
    final now = DateTime.now();
    return _expenses
        .where(
          (e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  List<Expense> get todayExpensesList {
    final now = DateTime.now();
    return _expenses
        .where(
          (e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .toList();
  }

  double get monthlyExpensesTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> get monthlyCategoryTotals {
    final now = DateTime.now();
    final monthlyExpenses = _expenses.where(
      (e) => e.date.year == now.year && e.date.month == now.month,
    );
    final map = <String, double>{};
    for (var e in monthlyExpenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }
}
