import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String?> onChanged;

  const CategoryDropdown({
    Key? key,
    required this.selectedCategory,
    required this.onChanged,
  }) : super(key: key);

  final Map<String, IconData> categoryIcons = const {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Groceries': Icons.shopping_cart,
    'Entertainment': Icons.movie,
    'Bills': Icons.receipt,
    'Other': Icons.category,
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      isDense: true,
      value: selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        prefixIcon: Icon(
          categoryIcons[selectedCategory] ?? Icons.category,
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
      items: categoryIcons.keys.map((String category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(categoryIcons[category], size: 20),
              const SizedBox(width: 10),
              Text(category),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }
}
