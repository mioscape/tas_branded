import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bag_branded/services/database_helper.dart';
import 'package:bag_branded/view/login_page.dart';
import 'package:bag_branded/view/profile_page.dart';

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
      title: 'Toko Bag Branded',
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(), // Default light theme
      darkTheme: ThemeData.dark(), // Default dark theme
      themeMode: Provider.of<ThemeProvider>(context).isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light, // Use the ThemeProvider to decide the theme mode
    );
  }
}
