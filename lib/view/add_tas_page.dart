import 'package:flutter/material.dart';
import 'package:tas_branded/controller/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AddTasPage extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const AddTasPage({Key? key, required this.databaseHelper}) : super(key: key);

  @override
  _AddTasPageState createState() => _AddTasPageState();
}

class _AddTasPageState extends State<AddTasPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = []; // Store the fetched categories
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories when the widget is initialized
  }

  Future<void> _fetchCategories() async {
    // Query the database for categories
    List<Map<String, dynamic>> categories = await widget.databaseHelper.getDataCategories();

    // Update the state with the fetched categories
    setState(() {
      _categories = categories;
    });
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
        title: Text('Tambah Data Tas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _namaController,
              decoration: InputDecoration(labelText: 'Nama Tas'),
            ),
            TextField(
              controller: _hargaController,
              decoration: InputDecoration(labelText: 'Harga'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _stokController,
              decoration: InputDecoration(labelText: 'Stok'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'Kategori'),
              value: _selectedCategoryId,
              onChanged: (int? newValue) {
                setState(() {
                  print(newValue);
                  _selectedCategoryId = newValue;
                });
              },
              items: [
                DropdownMenuItem<int>(
                  value: null,
                  child: Text(''), // Placeholder
                ),
                ..._categories.map<DropdownMenuItem<int>>((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['nama']),
                  );
                }),
              ],
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _selectImage();
              },
              child: Text('Pilih Gambar'),
            ),
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 100),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _addTas(context);
              },
              child: Text('Tambah Tas'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTas(BuildContext context) async {
    // Validate data
    if (_namaController.text.trim().isEmpty ||
        _hargaController.text.trim().isEmpty ||
        _stokController.text.trim().isEmpty ||
        _selectedCategoryId == null) {
      // Show an error message or handle the validation error as needed
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please fill in all fields.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Add data tas to the database
    await widget.databaseHelper.addTasWithImage(
      _namaController.text.trim(),
      int.tryParse(_hargaController.text) ?? 0,
      _selectedCategoryId!,
      _selectedImage,
      int.tryParse(_stokController.text) ?? 0,
    );

    // Navigate back to the previous page
    Navigator.of(context).pop();
  }
}
