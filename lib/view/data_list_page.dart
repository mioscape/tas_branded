import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tas_branded/controller/database_helper.dart';

class DataListPage extends StatefulWidget {
  @override
  _DataListPageState createState() => _DataListPageState();
}

class _DataListPageState extends State<DataListPage> {
  late DatabaseHelper _databaseHelper;
  List<Map<String, dynamic>> _originalTasList = []; // Tambahkan variabel untuk menyimpan data asli
  List<Map<String, dynamic>> _tasList = [];
  Map<String, List<Map<String, dynamic>>> kategoriData = {};
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _readData();
  }

  Future<void> _readData() async {
  await _databaseHelper.initializeDatabase();

  // Fetch data from 'tas' table
  final List<Map<String, dynamic>> tasList = await _databaseHelper.getDataTas();
  print('Tas List: $tasList');

  setState(() {
    _originalTasList = List.from(tasList); // Simpan data asli
    _tasList = tasList;
    kategoriData = _groupDataByKategori(_tasList);
  });

  print('Kategori Data: $kategoriData');
}

  Map<String, List<Map<String, dynamic>>> _groupDataByKategori(List<Map<String, dynamic>> tasList) {
  Map<String, List<Map<String, dynamic>>> groupedData = {};

  for (var tas in tasList) {
    var kategoriId = tas['kategori_id'] as int?;
    var kategoriNama = tas['kategori_nama'] as String?;
    
    print('Kategori ID: $kategoriId, Kategori Nama: $kategoriNama');

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _tasList = _searchData(value);
                  kategoriData = _groupDataByKategori(_tasList);
                });
              },
              decoration: InputDecoration(
                labelText: 'Cari Nama Tas',
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _tasList = List.from(_originalTasList); // Reset ke data asli
                            kategoriData = _groupDataByKategori(_tasList);
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: kategoriData.keys.length,
              itemBuilder: (context, index) {
          String kategoriKey = kategoriData.keys.elementAt(index);
          List<Map<String, dynamic>> dataKategori = kategoriData[kategoriKey]!;

          // Split kategoriKey into kategoriId and kategoriNama
          List<String> parts = kategoriKey.split('-');
          int kategoriId = int.parse(parts[0]);
          String kategoriNama = parts[1];

          return ExpansionTile(
            title: Text('Kategori $kategoriNama'),
            children: dataKategori.map((tas) {
              return ListTile(
                title: Text(tas['nama']),
                subtitle: Text('Harga: ${tas['harga']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Implement edit functionality
                        // You can navigate to an edit page or show a dialog for editing
                        // For example, Navigator.pushNamed(context, '/edit_tas', arguments: tas['id']);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _deleteData(tas['id']);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _searchData(String query) {
    return _originalTasList
        .where((tas) =>
            tas['nama'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> _deleteData(int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus Data'),
          content: Text('Apakah Anda yakin ingin menghapus data ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _databaseHelper.deleteTas(id);
                _readData(); // Perbarui tampilan setelah menghapus
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
