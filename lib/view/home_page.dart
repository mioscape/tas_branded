import 'package:flutter/material.dart';
import 'package:bag_branded/services/database_helper.dart';
import 'package:bag_branded/view/add_data_page.dart';
import 'package:bag_branded/view/data_list_page.dart';
import 'package:bag_branded/view/profile_page.dart';
import 'package:bag_branded/view/shop_page.dart';

class HomePage extends StatefulWidget {
  final String? userName;
  final String? userType;
  final String? password;

  const HomePage({super.key, this.userName, this.userType, this.password});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DatabaseHelper _databaseHelper;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _readData();
  }

  Future<void> _readData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Toko Bag Branded'),
      // ),
      body: Center(
        child: _getBody(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          ...(widget.userType == 'seller'
              ? [
                  const NavigationDestination(
                    icon: Icon(Icons.account_circle),
                    label: 'Profile',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.add),
                    label: 'Add Data',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.list),
                    label: 'List Data',
                  ),
                ]
              : [
                  const NavigationDestination(
                    icon: Icon(Icons.shopping_cart),
                    label: 'Shop',
                  ),
                  const NavigationDestination(
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
          return _buildAddData();
        case 2:
          return _buildLihatData();
        default:
          return Container();
      }
    } else {
      switch (_currentIndex) {
        case 0:
          return _buildShop();
        case 1:
          return _buildProfil();
        default:
          return Container();
      }
    }
  }

  Widget _buildAddData() {
    return TabbedPage(
        username: widget.userName!, databaseHelper: _databaseHelper);
  }

  Widget _buildLihatData() {
    return DataListPage(username: widget.userName!, password: widget.password!);
  }

  Widget _buildProfil() {
    return ProfilePage(username: widget.userName!, userType: widget.userType!);
  }

  Widget _buildShop() {
    return ShopPage();
  }
}
