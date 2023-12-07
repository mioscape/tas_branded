import 'package:flutter/material.dart';
import 'package:tas_branded/controller/database_helper.dart';
import 'package:tas_branded/view/add_tas_page.dart';
import 'package:tas_branded/view/data_list_page.dart';
import 'package:tas_branded/view/edit_tas_page.dart';
import 'package:tas_branded/view/home_page.dart';
import 'package:tas_branded/view/add_kategori_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper databaseHelper = DatabaseHelper();
  await databaseHelper.initializeDatabase();

  runApp(MyApp(databaseHelper: databaseHelper));
}

class MyApp extends StatelessWidget {
  final DatabaseHelper databaseHelper;

  MyApp({required this.databaseHelper});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Tas Branded',
      home: HomePage(),
      routes: {
        '/home': (context) => HomePage(),
        '/add_kategori': (context) => AddKategoriPage(),
        '/add_tas': (context) => AddTasPage(databaseHelper: databaseHelper),
        '/data_list': (context) => DataListPage(),
        '/home_user': (context) => HomePage(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(129, 104, 58, 183),
        ),
      ),
    );
  }
}
