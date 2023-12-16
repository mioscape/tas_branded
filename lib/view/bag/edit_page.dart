import 'dart:io';

import 'package:bag_branded/models/bag_model.dart';
import 'package:bag_branded/models/stock_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:bag_branded/services/database_helper.dart';

class EditBagPage extends StatefulWidget {
  final int bagId;
  final Function onBagUpdated;

  const EditBagPage({Key? key, required this.bagId, required this.onBagUpdated})
      : super(key: key);

  @override
  _EditBagPageState createState() => _EditBagPageState();
}

class _EditBagPageState extends State<EditBagPage> {
  late DatabaseHelper _databaseHelper;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _fetchDataForEdit();
  }

  Future<void> _fetchDataForEdit() async {
    // Fetch the existing data for editing based on widget.bagId
    Map<String, dynamic>? bagData =
        await _databaseHelper.getBagById(widget.bagId);

    if (bagData != null) {
      // Populate the form fields with the existing data
      _nameController.text = bagData['name'];
      _priceController.text = bagData['price'].toString();
      _stockController.text = bagData['stock'].toString();
    }
  }

  Future<void> _selectImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      File file = File(result.files.single.path!);

      setState(() {
        _selectedImage = file;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bag Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Bag name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8.0), // Add gap
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Price', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8.0), // Add gap
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Stock', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _selectImage();
              },
              child: const Text('Choose Image'),
            ),
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 100),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _updateBagData();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBagData() async {
    Map<String, dynamic>? bagData =
        await _databaseHelper.getBagById(widget.bagId);
    // Validate data
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _stockController.text.trim().isEmpty) {
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

    Bag bag = Bag(
      id: widget.bagId,
      name: _nameController.text.trim(),
      price: int.tryParse(_priceController.text) ?? 0,
      imagePath: _selectedImage?.path ?? bagData?['image_path'],
      categoryId: 0,
      addedBy: '',
    );

    Stock stock = Stock(
      id: 0,
      bagId: widget.bagId,
      stock: int.tryParse(_stockController.text) ?? 0,
      categoryId: 0,
    );

    // Update the data in the database
    await _databaseHelper.editBagWithImage(bag, stock);

    // Notify the parent widget about the update
    widget.onBagUpdated();

    // Navigate back to the previous page
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit Bag success!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
