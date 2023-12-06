import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tas_branded/controller/database_helper.dart';
import 'data_list_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DatabaseHelper _databaseHelper; // Declare _databaseHelper here
  List<Map<String, dynamic>> _tasList = [];

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper(); // Initialize _databaseHelper here
    _readData(); // Call _readData() after initializing _databaseHelper
  }

  Future<void> _readData() async {
    final Database database = await _databaseHelper.database;
    final List<Map<String, dynamic>> tasList = await database.query('tas');

    setState(() {
      _tasList = tasList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Toko Tas Branded'),
      ),
      body: Column(
        children: [
          SizedBox(height: 16), // Spacer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                 Navigator.pushNamed(context, '/add_tas'); // Use
                },
                child: Text('Tambah Data'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/add_kategori'); // Use the route you defined
                },
                child: Text('Tambah Data Kategori'),
              ),
              ElevatedButton(
                onPressed: () {
                   Navigator.pushNamed(context, '/data_list'); // Use the route you defined
                  // _navigateToDataList(context);
                },
                child: Text('Lihat Data'),
              ),
            ],
          ),
          SizedBox(height: 16), // Spacer
        ],
      ),
    );
  }

  void _navigateToDataList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DataListPage()),
    );
  }
}
