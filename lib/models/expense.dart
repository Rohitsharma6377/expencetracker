import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String category;

  @HiveField(4)
  String description;

  Expense({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    required this.description,
  });
}
