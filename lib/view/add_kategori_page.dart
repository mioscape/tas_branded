import 'package:flutter/material.dart';
import 'package:tas_branded/controller/database_helper.dart'; // Import your database helper

class AddKategoriPage extends StatefulWidget {
  final String username;

  const AddKategoriPage({super.key, required this.username});
  @override
  _AddKategoriPageState createState() => _AddKategoriPageState();
}

class _AddKategoriPageState extends State<AddKategoriPage> {
  final TextEditingController _namaController = TextEditingController();

  // Function to add a new category
  Future<void> _addKategori() async {
    final String username = widget.username;
    String nama = _namaController.text.trim();

    // Validate data
    if (nama.isEmpty) {
      // Show an error message or handle the validation error as needed
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please enter a category name.'),
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

    // Add category to the database
    await DatabaseHelper().addKategori(nama, username);

    // Navigate back to the previous screen (homepage)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tambah Kategori berhasil!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Kategori'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                  labelText: 'Nama Kategori', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _addKategori,
              child: Text('Tambah Kategori'),
            ),
          ],
        ),
      ),
    );
  }
}
