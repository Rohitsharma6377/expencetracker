import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';

class HiveService {
  static const String boxName = "expenses";

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ExpenseAdapter());
    await Hive.openBox<Expense>(boxName);
  }

  Box<Expense> getExpenseBox() {
    return Hive.box<Expense>(boxName);
  }

  Future<void> addExpense(Expense expense) async {
    final box = getExpenseBox();
    await box.add(expense);
  }

  List<Expense> getAllExpenses() {
    return getExpenseBox().values.toList();
  }

  Future<void> deleteExpense(int key) async {
    final box = getExpenseBox();
    await box.delete(key);
  }

  Future<void> clearAll() async {
    final box = getExpenseBox();
    await box.clear();
  }
}
