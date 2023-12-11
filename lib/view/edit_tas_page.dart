import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tas_branded/controller/database_helper.dart';

class EditTasPage extends StatefulWidget {
  final int tasId;
  final Function onTasUpdated;

  const EditTasPage({Key? key, required this.tasId, required this.onTasUpdated})
      : super(key: key);

  @override
  _EditTasPageState createState() => _EditTasPageState();
}

class _EditTasPageState extends State<EditTasPage> {
  late DatabaseHelper _databaseHelper;
  TextEditingController _namaController = TextEditingController();
  TextEditingController _hargaController = TextEditingController();
  TextEditingController _stokController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _fetchDataForEdit();
  }

  Future<void> _fetchDataForEdit() async {
    // Fetch the existing data for editing based on widget.tasId
    Map<String, dynamic>? tasData =
        await _databaseHelper.getTasById(widget.tasId);

    if (tasData != null) {
      // Populate the form fields with the existing data
      _namaController.text = tasData['nama'];
      _hargaController.text = tasData['harga'].toString();
      _stokController.text = tasData['stok'].toString();
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
        title: Text('Edit Data Tas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                  labelText: 'Nama Tas', border: OutlineInputBorder()),
            ),
            SizedBox(height: 8.0), // Add gap
            TextField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Harga', border: OutlineInputBorder()),
            ),
            SizedBox(height: 8.0), // Add gap
            TextField(
              controller: _stokController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Stok', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _selectImage();
              },
              child: Text('Pilih Gambar'),
            ),
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 100),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _updateTasData();
              },
              child: Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTasData() async {
    // Validate data
    if (_namaController.text.trim().isEmpty ||
        _hargaController.text.trim().isEmpty ||
        _stokController.text.trim().isEmpty) {
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

    // Get the updated values
    String nama = _namaController.text.trim();
    int harga = int.tryParse(_hargaController.text) ?? 0;
    int stok = int.tryParse(_stokController.text) ?? 0;

    // Update the data in the database
    await _databaseHelper.editTasWithImage(widget.tasId,
        {'nama': nama, 'harga': harga, 'stok': stok}, _selectedImage);

    // Notify the parent widget about the update
    widget.onTasUpdated();

    // Navigate back to the previous page
    Navigator.pop(context);
  }
}
