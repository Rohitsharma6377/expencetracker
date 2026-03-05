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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated: ${file.path}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.teal,
          ),
        );
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monthly Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
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
              _exportPdf(
                monthlyExpenses,
                provider.monthlyExpensesTotal,
                context,
              );
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
          final totalPrevMonth = provider.expenses
              .where(
                (e) => e.date.year == prevYear && e.date.month == prevMonth,
              )
              .fold(0.0, (sum, e) => sum + e.amount);

          final diff = totalThisMonth - totalPrevMonth;
          final percent = totalPrevMonth == 0
              ? 0.0
              : (diff.abs() / totalPrevMonth) * 100;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.yMMMM().format(_selectedMonth),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Summary of your spending',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _showMonthPicker,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Select Month'),
                        style: TextButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildInsightCard(context, totalThisMonth, diff, percent),
                const SizedBox(height: 16),
                Expanded(
                  child: monthlyExpenses.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 32),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    double total,
    double diff,
    double percent,
  ) {
    final theme = Theme.of(context);
    final isIncrease = diff > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Monthly Spending',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  isIncrease ? Icons.trending_up : Icons.trending_down,
                  color: isIncrease ? Colors.orange : Colors.greenAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isIncrease
                      ? 'Up by ${percent.toStringAsFixed(1)}%'
                      : 'Down by ${percent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  ' from last month',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: 0.5,
          child: Image.network(
            'https://cdn-icons-png.flaticon.com/512/7486/7486744.png',
            width: 100,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.inbox, size: 64, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "No transactions found",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const Text(
          "Try picking a different month",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
