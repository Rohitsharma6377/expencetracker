import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../widgets/expense_card.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({Key? key}) : super(key: key);

  @override
  _MonthlyReportScreenState createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  DateTime _selectedMonth = DateTime.now();

  void _showMonthPicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedMonth = DateTime(pickedDate.year, pickedDate.month);
      });
    });
  }

  Future<void> _exportPdf(
    List<Expense> expenses,
    double total,
    BuildContext context,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Monthly Expense Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Month: ${DateFormat.yMMMM().format(_selectedMonth)}',
              style: pw.TextStyle(fontSize: 18),
            ),
            pw.Text(
              'Total Spent: ₹${total.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 18),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              data:
                  const <List<String>>[
                    <String>['Date', 'Category', 'Description', 'Amount'],
                  ]..addAll(
                    expenses
                        .map(
                          (e) => [
                            DateFormat.yMd().format(e.date),
                            e.category,
                            e.description,
                            '₹${e.amount.toStringAsFixed(2)}',
                          ],
                        )
                        .toList(),
                  ),
            ),
          ],
        ),
      ),
    );

    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File(
        "${output.path}/expense_report_${DateFormat('MMMyyyy').format(_selectedMonth)}.pdf",
      );
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF Exported: ${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              final provider = Provider.of<ExpenseProvider>(
                context,
                listen: false,
              );
              final monthlyExpenses = provider.expenses
                  .where(
                    (e) =>
                        e.date.year == _selectedMonth.year &&
                        e.date.month == _selectedMonth.month,
                  )
                  .toList();
              final total = provider.monthlyExpensesTotal;
              _exportPdf(monthlyExpenses, total, context);
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final monthlyExpenses = provider.expenses
              .where(
                (e) =>
                    e.date.year == _selectedMonth.year &&
                    e.date.month == _selectedMonth.month,
              )
              .toList();

          final totalThisMonth = monthlyExpenses.fold(
            0.0,
            (sum, e) => sum + e.amount,
          );

          // previous month
          int prevMonth = _selectedMonth.month - 1;
          int prevYear = _selectedMonth.year;
          if (prevMonth == 0) {
            prevMonth = 12;
            prevYear--;
          }
          final prevMonthExpenses = provider.expenses
              .where(
                (e) => e.date.year == prevYear && e.date.month == prevMonth,
              )
              .toList();
          final totalPrevMonth = prevMonthExpenses.fold(
            0.0,
            (sum, e) => sum + e.amount,
          );

          String compareText;
          if (totalPrevMonth == 0) {
            compareText = "vs Last Month: N/A";
          } else {
            final diff = totalThisMonth - totalPrevMonth;
            final percent = (diff.abs() / totalPrevMonth) * 100;
            if (diff > 0) {
              compareText = "vs Last Month: +${percent.toStringAsFixed(1)}%";
            } else {
              compareText = "vs Last Month: -${percent.toStringAsFixed(1)}%";
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMM().format(_selectedMonth),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showMonthPicker,
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Change'),
                    ),
                  ],
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Expenses',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            '₹${totalThisMonth.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        compareText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: totalThisMonth > totalPrevMonth
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: monthlyExpenses.isEmpty
                    ? const Center(
                        child: Text(
                          "No expenses for this month.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: monthlyExpenses.length,
                        itemBuilder: (context, index) {
                          return ExpenseCard(
                            expense: monthlyExpenses[index],
                            onDelete: () => provider.deleteExpense(
                              monthlyExpenses[index].key,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
