import 'package:flutter/material.dart';
import 'package:tas_branded/controller/database_helper.dart';

class EditTasPage extends StatefulWidget {
  final int tasId;
  final Function onTasUpdated;

  const EditTasPage({Key? key, required this.tasId, required this.onTasUpdated}) : super(key: key);

  @override
  _EditTasPageState createState() => _EditTasPageState();
}

class _EditTasPageState extends State<EditTasPage> {
  late DatabaseHelper _databaseHelper;
  TextEditingController _namaController = TextEditingController();
  TextEditingController _hargaController = TextEditingController();
  TextEditingController _stokController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _fetchDataForEdit();
  }

  Future<void> _fetchDataForEdit() async {
    // Fetch the existing data for editing based on widget.tasId
    // Assume that you have a method in DatabaseHelper to fetch a tas by its ID
    // Adjust the method name as needed
    Map<String, dynamic>? tasData = await _databaseHelper.getTasById(widget.tasId);

    if (tasData != null) {
      // Populate the form fields with the existing data
      _namaController.text = tasData['nama'];
      _hargaController.text = tasData['harga'].toString();
      // Add similar lines for other form fields
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
              decoration: InputDecoration(labelText: 'Nama Tas'),
            ),
            TextField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Harga'),
            ),
            // Add similar fields for other form inputs

            SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                // Call the method to update the data in the database
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
    // Implement the logic to update the data in the database
    // Use _namaController.text, _hargaController.text, etc., to get the updated values

    // For simplicity, this is just a placeholder
    print('Updating data for Tas ID: ${widget.tasId}');
    print('Nama: ${_namaController.text}');
    print('Harga: ${_hargaController.text}');
    // Add similar lines for other form fields

    // Update the data in the database using the DatabaseHelper method
    await _databaseHelper.updateTas(widget.tasId, {
      'nama': _namaController.text,
      'harga': int.parse(_hargaController.text),
      // Add similar lines for other form fields
    });

    widget.onTasUpdated();
    // You may also want to pop the current page to go back to the data list page
    Navigator.pop(context);
  }

}
