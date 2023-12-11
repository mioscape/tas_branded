import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tas_branded/controller/database_helper.dart';
import 'package:tas_branded/view/edit_tas_page.dart';
import 'package:intl/intl.dart';
import 'package:search_page/search_page.dart';

class DataListPage extends StatefulWidget {
  final String username;
  @override
  _DataListPageState createState() => _DataListPageState();

  DataListPage({required this.username});
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
    final List<Map<String, dynamic>> tasList =
        await _databaseHelper.getDataTas(widget.username);
    print('Tas List: $tasList');

    setState(() {
      _originalTasList = List.from(tasList);
      _tasList = tasList;
      kategoriData = _groupDataByKategori(_tasList);
    });

    print('Kategori Data: $kategoriData');
  }

  Map<String, List<Map<String, dynamic>>> _groupDataByKategori(
      List<Map<String, dynamic>> tasList) {
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
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            SizedBox(height: 10), // Adjust the height as needed
            SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                return buildSearchBar(controller);
              },
              suggestionsBuilder:
                  (BuildContext context, SearchController controller) {
                return buildSuggestions(controller);
              },
            ),
            SizedBox(height: 10), // Adjust the height as needed
            Expanded(
              child: ListView.builder(
                itemCount: kategoriData.keys.length,
                itemBuilder: (context, index) {
                  String kategoriKey = kategoriData.keys.elementAt(index);
                  List<Map<String, dynamic>> dataKategori =
                      kategoriData[kategoriKey]!;

                  List<String> parts = kategoriKey.split('-');
                  int kategoriId = int.parse(parts[0]);
                  String kategoriNama = parts[1];

                  return ExpansionTile(
                    title: Text('Kategori $kategoriNama'),
                    children: dataKategori.map((tas) {
                      return buildListTile(context, tas);
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBar(SearchController controller) {
    return SearchBar(
      controller: controller,
      hintText: 'Search Tas',
      padding: const MaterialStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 16.0)),
      onTap: () {
        controller.openView();
      },
      onChanged: (_) {
        controller.openView();
      },
      leading: const Icon(Icons.search),
      trailing: <Widget>[
        Tooltip(
          message: 'Change brightness mode',
          child: IconButton(
            onPressed: () {}, icon: Icon(null),
            // Your brightness mode icon here
          ),
        )
      ],
    );
  }

  Iterable<Widget> buildSuggestions(SearchController controller) {
    final List<Map<String, dynamic>> filteredTasList = _originalTasList
        .where((tas) => tas['nama']
            .toString()
            .toLowerCase()
            .contains(controller.text.toLowerCase()))
        .toList();

    return filteredTasList.map((tas) {
      return buildListTile(context, tas);
    });
  }

  Widget buildListTile(BuildContext context, Map<String, dynamic> tas) {
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
                : const AssetImage('assets/images/no_image.png')
                    as ImageProvider,
          ),
        ),
      ),
      title: Text(tas['nama']),
      subtitle:
          Text('Harga: ${formatCurrency(tas['harga'])}\nStok: ${tas['stok']}'),
      trailing: PopupMenuButton<String>(
        itemBuilder: (BuildContext context) {
          return {'Edit', 'Delete', 'Open Image'}.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
        onSelected: (String choice) {
          switch (choice) {
            case 'Edit':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTasPage(
                    tasId: tas['id'],
                    onTasUpdated: () {
                      // Callback function to refresh data list
                      _readData();
                    },
                  ),
                ),
              );
              break;
            case 'Delete':
              _deleteData(tas['id']);
              break;
            case 'Open Image':
              _openImage(tas['image_path']);
              break;
          }
        },
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

  String formatCurrency(int price) {
    final NumberFormat formatCurrency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(price);
  }
}
