// ignore_for_file: avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:bag_branded/models/stock_model.dart';
import 'package:bag_branded/models/bag_model.dart';
import 'package:bag_branded/services/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

class AddBagPage extends StatefulWidget {
  final String username;
  final DatabaseHelper databaseHelper;

  const AddBagPage(
      {super.key, required this.databaseHelper, required this.username});

  @override
  _AddBagPageState createState() => _AddBagPageState();
}

class _AddBagPageState extends State<AddBagPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _currencyFormatter = CurrencyTextInputFormatter(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final String username = widget.username;

    List<Map<String, dynamic>> categories =
        await widget.databaseHelper.getDataCategories(username);

    setState(() {
      _categories = categories;
    });
  }

  Future<void> _selectImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        File file = File(result.files.single.path!);

        setState(() {
          _selectedImage = file;
        });
      }
    } catch (e) {
      print('Error selecting image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _categories.isEmpty
            ? const Center(
                child: Text('No categories available, add a category first.'),
              )
            : Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Bag name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [_currencyFormatter],
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description', // Add description field
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8.0),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategoryId,
                    onChanged: (int? newValue) {
                      setState(() {
                        _selectedCategoryId = newValue;
                      });
                    },
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text(''),
                      ),
                      ..._categories.map<DropdownMenuItem<int>>((category) {
                        return DropdownMenuItem<int>(
                          value: category['id'],
                          child: Text(category['name']),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      _selectImage();
                    },
                    child: const Text('Choose Image'),
                  ),
                  if (_selectedImage != null)
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        Image.file(_selectedImage!, height: 100),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            _openImage(_selectedImage!.path);
                          },
                          child: const Text('Preview Image'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      _addBag(context);
                    },
                    child: const Text('Add Bag'),
                  ),
                ],
              ),
      ),
    );
  }

  void _openImage(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.0),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addBag(BuildContext context) async {
    final String username = widget.username;
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _stockController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _selectedCategoryId == null ||
        _selectedImage == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please fill in all fields.'),
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

    Bag bag = Bag(
      id: 0,
      name: _nameController.text.trim(),
      price: _currencyFormatter.getUnformattedValue().toInt(),
      categoryId: _selectedCategoryId!,
      addedBy: username,
      imagePath: _selectedImage!.path,
      description: _descriptionController.text.trim(),
    );

    Stock stock = Stock(
      id: 0,
      stock: int.tryParse(_stockController.text) ?? 0,
      bagId: 0,
      categoryId: 0,
    );

    await widget.databaseHelper.addBagWithImage(bag, stock);

    setState(() {
      _selectedImage = null;
      _selectedCategoryId = null;
    });

    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _descriptionController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Bag success!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
