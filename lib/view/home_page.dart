import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tas_branded/controller/database_helper.dart';
import 'package:tas_branded/view/add_kategori_page.dart';
import 'package:tas_branded/view/add_tas_page.dart';
import 'package:tas_branded/view/data_list_page.dart';
import 'package:tas_branded/view/login_page.dart';
import 'package:tas_branded/view/profile_page.dart';
import 'package:tas_branded/view/register_page.dart';

class HomePage extends StatefulWidget {
  final String? userName;
  final String? userType;

  HomePage({this.userName, this.userType});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DatabaseHelper _databaseHelper;
  List<Map<String, dynamic>> _tasList = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _readData();
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
      // appBar: AppBar(
      //   title: Text('Toko Tas Branded'),
      // ),
      body: Center(
        child: _getBody(),
      ),
      bottomNavigationBar: NavigationBar(
        // type: BottomNavigationBarType.fixed,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          ...(widget.userType == 'seller'
              ? [
                  NavigationDestination(
                    icon: Icon(Icons.account_circle),
                    label: 'Profile',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.add),
                    label: 'Tambah Tas',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.add),
                    label: 'Tambah Kategori',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.list),
                    label: 'Lihat Data',
                  ),
                ]
              : [
                  NavigationDestination(
                    icon: Icon(Icons.shopping_cart),
                    label: 'Shop',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_circle),
                    label: 'Profile',
                  ),
                ]),
        ],
      ),
    );
  }

  Widget _getBody() {
    if (widget.userType == 'seller') {
      switch (_currentIndex) {
        case 0:
          return _buildProfil();
        case 1:
          return _buildTambahDataTas();
        case 2:
          return _buildTambahDataKategori();
        case 3:
          return _buildLihatData();
        default:
          return Container();
      }
    } else {
      switch (_currentIndex) {
        case 0:
          return _buildProfil();
        case 1:
          return _buildProfil();
        default:
          return Container();
      }
    }
  }

  Widget _buildTambahDataTas() {
    return AddTasPage(
        databaseHelper: _databaseHelper, username: widget.userName!);
  }

  Widget _buildTambahDataKategori() {
    return AddKategoriPage(username: widget.userName!);
  }

  Widget _buildLihatData() {
    return DataListPage(username: widget.userName!);
  }

  Widget _buildProfil() {
    return ProfilePage(username: widget.userName!, userType: widget.userType!);
  }
}
