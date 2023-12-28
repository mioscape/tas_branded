// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';

import 'package:bag_branded/models/bag_model.dart';
import 'package:bag_branded/models/stock_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:bag_branded/services/database_helper.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

class EditBagPage extends StatefulWidget {
  final int bagId;
  final Function onBagUpdated;

  const EditBagPage(
      {super.key, required this.bagId, required this.onBagUpdated});

  @override
  _EditBagPageState createState() => _EditBagPageState();
}

class _EditBagPageState extends State<EditBagPage> {
  late DatabaseHelper _databaseHelper;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final _currencyFormatter = CurrencyTextInputFormatter(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _fetchDataForEdit();
  }

  Future<void> _fetchDataForEdit() async {
    Map<String, dynamic>? bagData =
        await _databaseHelper.getBagById(widget.bagId);

    if (bagData != null) {
      _nameController.text = bagData['name'];
      _priceController.text =
          _currencyFormatter.format(bagData['price'].toString());
      _stockController.text = bagData['stock'].toString();
      String? imagePath = bagData['image_path'];
      if (imagePath != null && imagePath.isNotEmpty) {
        setState(() {
          _selectedImage = File(imagePath);
        });
      }
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
                labelText: 'Bag name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [_currencyFormatter],
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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

  Future<void> _updateBagData() async {
    Map<String, dynamic>? bagData =
        await _databaseHelper.getBagById(widget.bagId);
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _stockController.text.trim().isEmpty) {
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
      price: _currencyFormatter.getUnformattedValue().toInt(),
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

    await _databaseHelper.editBagWithImage(bag, stock);

    widget.onBagUpdated();

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit Bag success!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
