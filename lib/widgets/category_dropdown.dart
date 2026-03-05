import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String?> onChanged;

  const CategoryDropdown({
    Key? key,
    required this.selectedCategory,
    required this.onChanged,
  }) : super(key: key);

  final List<String> categories = const [
    'Food',
    'Transport',
    'Groceries',
    'Entertainment',
    'Bills',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: categories.map((String category) {
        return DropdownMenuItem(value: category, child: Text(category));
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }
}
