import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/quick_add_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final todayList = provider.todayExpensesList;
          final todayTotal = provider.todayExpensesTotal;
          final monthlyTotal = provider.monthlyExpensesTotal;
          final categoryTotals = provider.monthlyCategoryTotals;

          final now = DateTime.now();
          final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
          final daysLeft = daysInMonth - now.day;
          final avgDaily = now.day > 0 ? monthlyTotal / now.day : 0.0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withRed(50),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          'Spent Today',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${todayTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Month: ₹${monthlyTotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: _currentIndexScroll(context) > 150
                      ? const Text(
                          'Dashboard',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const QuickAddWidget(),
                      const SizedBox(height: 24),

                      _buildSectionTitle(context, 'Monthly Summary'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildSummaryCard(
                            context,
                            'Daily Avg',
                            '₹${avgDaily.toStringAsFixed(0)}',
                            Icons.trending_up,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryCard(
                            context,
                            'Days Left',
                            '$daysLeft',
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (categoryTotals.isNotEmpty) ...[
                        _buildSectionTitle(context, 'Spending Breakdown'),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 220,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 50,
                                      sections: _getPieChartSections(
                                        categoryTotals,
                                        theme,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildLegend(categoryTotals, theme),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      _buildSectionTitle(context, 'Today\'s Transactions'),
                      const SizedBox(height: 12),
                      if (todayList.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: todayList.length,
                          itemBuilder: (context, index) {
                            final e = todayList[index];
                            return ExpenseCard(
                              expense: e,
                              onDelete: () => provider.deleteExpense(e.key),
                            );
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _currentIndexScroll(BuildContext context) {
    try {
      return ScrollController().offset;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: theme.colorScheme.outline, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Text('💰', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          const Text(
            "No expenses today!",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            "Add your first expense to start tracking.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Map<String, double> data, ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: data.keys.map((cat) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _getColor(cat),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              cat,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Groceries':
        return Colors.green;
      case 'Entertainment':
        return Colors.purple;
      case 'Bills':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }

  List<PieChartSectionData> _getPieChartSections(
    Map<String, double> data,
    ThemeData theme,
  ) {
    return data.entries.map((e) {
      return PieChartSectionData(
        color: _getColor(e.key),
        value: e.value,
        title: '',
        radius: 50,
      );
    }).toList();
  }
}
