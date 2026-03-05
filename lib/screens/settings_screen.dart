import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/expense_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _exportData(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    final expenses = provider.expenses
        .map(
          (e) => {
            'date': e.date.toIso8601String(),
            'amount': e.amount,
            'category': e.category,
            'description': e.description,
          },
        )
        .toList();

    final jsonString = jsonEncode(expenses);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/expense_backup.json');
      await file.writeAsString(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved to: ${file.path}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting data: $e')));
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();

        if (context.mounted) {
          await context.read<ExpenseProvider>().importFromJson(content);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data Imported Successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing data: $e')));
      }
    }
  }

  void _clearAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This action cannot be undone. All your expense history will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ExpenseProvider>().clearAll();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 20),
            _buildSectionHeader(context, 'General'),
            _buildSettingsCard(
              context,
              children: [
                _buildListTile(
                  context,
                  icon: Icons.currency_rupee,
                  title: 'Currency',
                  subtitle: 'Default: ₹ INR',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('More currencies soon!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Data Management'),
            _buildSettingsCard(
              context,
              children: [
                _buildListTile(
                  context,
                  icon: Icons.upload_file,
                  title: 'Backup Data (JSON)',
                  subtitle: 'Save all expenses to a file',
                  onTap: () => _exportData(context),
                ),
                const Divider(height: 1),
                _buildListTile(
                  context,
                  icon: Icons.download,
                  title: 'Import Data',
                  subtitle: 'Restore expenses from JSON',
                  onTap: () => _importData(context),
                ),
                const Divider(height: 1),
                _buildListTile(
                  context,
                  icon: Icons.delete_forever,
                  iconColor: Colors.red,
                  title: 'Clear All Data',
                  titleColor: Colors.red,
                  subtitle: 'Delete all history',
                  onTap: () => _clearAllData(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'About'),
            _buildSettingsCard(
              context,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.security,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Privacy First',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This app is designed to be private. No data ever leaves your device unless you manually export it.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Text(
                  'Version 1.1.0 • Made with ❤️',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    Color? iconColor,
    required String title,
    Color? titleColor,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Theme.of(context).colorScheme.primary)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}
