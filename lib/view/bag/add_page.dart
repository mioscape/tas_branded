import 'package:flutter/material.dart';
import 'package:bag_branded/models/stock_model.dart';
import 'package:bag_branded/models/bag_model.dart';
import 'package:bag_branded/services/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AddBagPage extends StatefulWidget {
  final String username;
  final DatabaseHelper databaseHelper;

  const AddBagPage(
      {Key? key, required this.databaseHelper, required this.username})
      : super(key: key);

  @override
  _AddBagPageState createState() => _AddBagPageState();
}

class _AddBagPageState extends State<AddBagPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  File? _selectedImage;
  // ignore: unused_field
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories when the widget is initialized
  }

  Future<void> _fetchCategories() async {
    final String username = widget.username;
    // Query the database for categories
    List<Map<String, dynamic>> categories =
        await widget.databaseHelper.getDataCategories(username);

    // Update the state with the fetched categories
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _selectImage() async {
    setState(() {
      _isLoading = true;
    });

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
      // Handle file picking error
      print('Error selecting image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                  const SizedBox(height: 8.0), // Add gap
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8.0), // Add gap
                  TextField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8.0), // Add gap
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
                        child: Text(''), // Placeholder
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
                    Image.file(_selectedImage!, height: 100),
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

  Future<void> _addBag(BuildContext context) async {
    final String username = widget.username;
    print(username);
    // Validate data
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _stockController.text.trim().isEmpty ||
        _selectedCategoryId == null ||
        _selectedImage == null) {
      // Show an error message or handle the validation error as needed
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

    // Add data bag to the database
    Bag bag = Bag(
      id: 0,
      name: _nameController.text.trim(),
      price: int.tryParse(_priceController.text) ?? 0,
      categoryId: _selectedCategoryId!,
      addedBy: username,
      imagePath: _selectedImage!.path,
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

    // Navigate back to the previous page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Bag success!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
