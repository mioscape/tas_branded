// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:bag_branded/models/category_model.dart';
import 'package:bag_branded/services/database_helper.dart';

class AddCategoryPage extends StatefulWidget {
  final String username;

  const AddCategoryPage({super.key, required this.username});
  @override
  _AddCategoryPageState createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _addCategory() async {
    final String username = widget.username;
    String name = _nameController.text.trim();

    if (name.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please enter a category name.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    Category category = Category(id: 0, name: name, addedBy: username);
    await DatabaseHelper().addCategory(category);
    _nameController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add Category ${category.name} success!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Category name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}
