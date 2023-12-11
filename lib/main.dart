import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tas_branded/controller/database_helper.dart';
import 'package:tas_branded/view/add_tas_page.dart';
import 'package:tas_branded/view/data_list_page.dart';
import 'package:tas_branded/view/edit_tas_page.dart';
import 'package:tas_branded/view/home_page.dart';
import 'package:tas_branded/view/add_kategori_page.dart';
import 'package:tas_branded/view/login_page.dart';
import 'package:tas_branded/view/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper databaseHelper = DatabaseHelper();
  await databaseHelper.initializeDatabase();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(databaseHelper: databaseHelper),
    ),
  );
}

class MyApp extends StatelessWidget {
  final DatabaseHelper databaseHelper;

  const MyApp({super.key, required this.databaseHelper});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Tas Branded',
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
      // routes: {
      //   '/home': (context) => HomePage(),
      //   '/add_kategori': (context) => AddKategoriPage(),
      //   '/add_tas': (context) => AddTasPage(
      //         databaseHelper: databaseHelper,
      //         username: '',
      //       ),
      //   '/data_list': (context) => DataListPage(
      //         username: '',
      //       ),
      //   '/home_user': (context) => HomePage(),
      // },
      theme: ThemeData.light(), // Default light theme
      darkTheme: ThemeData.dark(), // Default dark theme
      themeMode: Provider.of<ThemeProvider>(context).isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light, // Use the ThemeProvider to decide the theme mode
    );
  }
}
