import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tas_branded/controller/database_helper.dart';
import 'package:tas_branded/view/edit_tas_page.dart';

class DataListPage extends StatefulWidget {
  @override
  _DataListPageState createState() => _DataListPageState();
}

class _DataListPageState extends State<DataListPage> {
  late DatabaseHelper _databaseHelper;
  List<Map<String, dynamic>> _originalTasList = [];
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

  // Fetch data from 'tas' table including 'stok' field
  final List<Map<String, dynamic>> tasList = await _databaseHelper.getDataTas();
  print('Tas List: $tasList');

  setState(() {
    _originalTasList = List.from(tasList);
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
                            _tasList = List.from(_originalTasList);
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

                List<String> parts = kategoriKey.split('-');
                int kategoriId = int.parse(parts[0]);
                String kategoriNama = parts[1];

                return ExpansionTile(
                  title: Text('Kategori $kategoriNama'),
                  children: dataKategori.map((tas) {
                    return ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: tas['image_path'] != null
                                ? FileImage(File(tas['image_path']))
                                : const AssetImage('assets/images/no_image.png') as ImageProvider,
                          ),
                        ),
                      ),
                      title: Text(tas['nama']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Harga: ${tas['harga']}'),
                          Text('Stok: ${tas['stok']}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _navigateToEditTas(this.context, tas['id']);
                              // TODO: Implement edit functionality
                            },
                            
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteData(tas['id']);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.image),
                            onPressed: () {
                              _openImage(tas['image_path']);
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

  void _navigateToEditTas(BuildContext context, int tasId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTasPage(
          tasId: tasId,
          onTasUpdated: () {
          // Callback function to refresh data list
          _readData();
        },
          ),
        
      ),
    );
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
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _databaseHelper.deleteTas(id);
                _readData();
                Navigator.of(context).pop();
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
  void _openImage(String imagePath) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
        ),
      );
    },
  );
}
}
