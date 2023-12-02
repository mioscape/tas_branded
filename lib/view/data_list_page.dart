import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tas_branded/controller/database_helper.dart';

class DataListPage extends StatefulWidget {
  @override
  _DataListPageState createState() => _DataListPageState();
}

class _DataListPageState extends State<DataListPage> {
  late DatabaseHelper _databaseHelper;
  List<Map<String, dynamic>> _tasList = [];
  Map<String, List<Map<String, dynamic>>> kategoriData = {};


  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _readData();
  }

  Future<void> _readData() async {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  await _databaseHelper.initializeDatabase();
  final Database database = await _databaseHelper.database;

  // Now you can use 'database' for your queries.


  final List<Map<String, dynamic>> tasList = await database.query('tas');

  setState(() {
    kategoriData = _groupDataByKategori(tasList);
  });
}



Map<String, List<Map<String, dynamic>>> _groupDataByKategori(List<Map<String, dynamic>> tasList) {
  Map<String, List<Map<String, dynamic>>> groupedData = {};

  for (var tas in tasList) {
    var kategoriId = tas['kategori_id'] as int?;
    var kategoriNama = tas['kategori_nama'] as String?;

    if (kategoriId != null && kategoriNama != null) {
      var kategoriKey = '$kategoriId-$kategoriNama';

      if (!groupedData.containsKey(kategoriKey)) {
        groupedData[kategoriKey] = [];
      }

      groupedData[kategoriKey]!.add(tas);
    }
  }

  return groupedData;
}




  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Data List'),
    ),
    body: ListView.builder(
      itemCount: kategoriData.keys.length,
      itemBuilder: (context, index) {
        String kategoriKey = kategoriData.keys.elementAt(index);
        List<Map<String, dynamic>> dataKategori = kategoriData[kategoriKey]!;

        // Split kategoriKey into kategoriId and kategoriNama
        List<String> parts = kategoriKey.split('-');
        int kategoriId = int.parse(parts[0]);
        String kategoriNama = parts[1];

        return ExpansionTile(
          title: Text('$kategoriId - $kategoriNama'),
          children: dataKategori.map((tas) {
            return ListTile(
              title: Text(tas['nama']),
              // Add other widgets as needed
            );
          }).toList(),
        );
      },
    ),
  );
}



  Future<void> _deleteData(int id) async {
    // Kode penghapusan data...
  }
}
