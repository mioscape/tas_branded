import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bag_branded/services/database_helper.dart';
import 'package:bag_branded/view/auth/login_page.dart';
import 'package:bag_branded/view/shared/profile_page.dart';

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
    // Get the current theme mode
    final ThemeMode currentThemeMode =
        Provider.of<ThemeProvider>(context).isDarkMode
            ? ThemeMode.dark
            : ThemeMode.light;

    // Set system navigation bar color based on the current theme mode
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: currentThemeMode == ThemeMode.dark
          ? Colors.blueGrey // Set the dark mode color
          : Colors.white, // Set the light mode color
    ));

    return MaterialApp(
      title: 'Bag Branded App',
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: currentThemeMode,
    );
  }
}
