import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';

class ExpenseProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  Future<void> loadExpenses() async {
    _expenses = _hiveService.getAllExpenses().cast<Expense>();
    if (_expenses.isEmpty) {
      await _addSampleData();
      _expenses = _hiveService.getAllExpenses().cast<Expense>();
    }
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    _updateWidget();
  }

  Future<void> _updateWidget() async {
    try {
      await HomeWidget.saveWidgetData<double>(
        'today_total',
        todayExpensesTotal,
      );
      await HomeWidget.updateWidget(
        name: 'AppWidgetProvider',
        androidName: 'AppWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  Future<void> _addSampleData() async {
    final samples = [
      Expense(
        id: 1,
        date: DateTime.now(),
        amount: 500,
        category: 'Food',
        description: 'Lunch at Cafe',
      ),
      Expense(
        id: 2,
        date: DateTime.now(),
        amount: 1200,
        category: 'Transport',
        description: 'Monthly Bus Pass',
      ),
      Expense(
        id: 3,
        date: DateTime.now().subtract(const Duration(days: 1)),
        amount: 2500,
        category: 'Groceries',
        description: 'Weekly grocery shopping',
      ),
    ];
    for (var e in samples) {
      await _hiveService.addExpense(e);
    }
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

  Future<void> importFromJson(String jsonContent) async {
    try {
      final List<dynamic> list = jsonDecode(jsonContent);
      for (var item in list) {
        final expense = Expense(
          id: DateTime.now().millisecondsSinceEpoch + list.indexOf(item),
          date: DateTime.parse(item['date']),
          amount: (item['amount'] as num).toDouble(),
          category: item['category'],
          description: item['description'],
        );
        await _hiveService.addExpense(expense);
      }
      await loadExpenses();
      _updateWidget();
    } catch (e) {
      rethrow;
    }
  }
}
