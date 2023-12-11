import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  late Database _database;

  factory DatabaseHelper() {
    if (_instance == null) {
      _instance = DatabaseHelper._();
    }
    return _instance!;
  }

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database.isOpen) {
      return _database;
    } else {
      return await initializeDatabase();
    }
  }

  Future<Database> initializeDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'tas_branded_dev_v1.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tas (
            id INTEGER PRIMARY KEY,
            nama TEXT,
            harga INTEGER,
            kategori_id INTEGER,
  			    added_by TEXT,
            image_path TEXT,
            FOREIGN KEY (kategori_id) REFERENCES kategori_tas(id),
            FOREIGN KEY (added_by) REFERENCES users(username)
          )
        ''');
        await db.execute('''
          CREATE TABLE kategori_tas (
            id INTEGER PRIMARY KEY,
            nama TEXT,
            added_by TEXT,
            FOREIGN KEY (added_by) REFERENCES users(username)
          )
        ''');
        await db.execute('''
          CREATE TABLE stok_tas (
            id INTEGER PRIMARY KEY,
            tas_id INTEGER,
            stok INTEGER,
            FOREIGN KEY (tas_id) REFERENCES tas(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE users (
            username TEXT PRIMARY KEY,
            password TEXT,
            user_type TEXT
          )
        ''');
      },
      version: 1,
    );

    return _database;
  }

  // Existing methods...

  // Function to add a new category to the database
  Future<void> addKategori(String nama, String username) async {
    final Database database = await _database.database;
    await database.insert(
      'kategori_tas',
      {'nama': nama, 'added_by': username},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addTas(
      String nama, int harga, int kategoriId, String username) async {
    final Database database = await _database.database;
    final user = await DatabaseHelper().getUserData(username);

    int? userId;
    if (user != null) {
      userId = user['id'];
    }

    await database.insert(
      'tas',
      {
        'nama': nama,
        'harga': harga,
        'kategori_id': kategoriId,
        'added_by': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update the "getDataByUserType" function
  Future<List<Map<String, dynamic>>> getDataByUserType(
      String userType, String username) async {
    final Database db = await database;
    final String query;

    if (userType == 'seller') {
      query = '''
        SELECT * FROM tas
        WHERE added_by = (SELECT id FROM users WHERE username = ?)
      ''';
    } else {
      query = 'SELECT * FROM tas';
    }

    final List<Map<String, dynamic>> data =
        await db.rawQuery(query, [username]);

    return data;
  }

  // Function to fetch user data by username
  Future<Map<String, dynamic>?> getUserData(String username) async {
    final Database db = await database;
    final List<Map<String, dynamic>> userData = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (userData.isNotEmpty) {
      return userData.first;
    } else {
      return null;
    }
  }

  Future<int> addTasWithImage(String nama, int harga, int kategoriId,
      File? image, int stok, String username) async {
    final Database database = await _database.database;

    String imagePath = '';

    if (image != null) {
      // Copy the image to the app's documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String uniqueFileName =
          DateTime.now().millisecondsSinceEpoch.toString();
      final String newFilePath = '${appDocDir.path}/assets/$uniqueFileName.png';

      try {
        await image.copy(newFilePath);
        imagePath = newFilePath;
      } on FileSystemException catch (e) {
        print('Error copying image: $e');
      }
    }

    int tasId = await database.transaction<int>((txn) async {
      int id = await txn.insert(
        'tas',
        {
          'nama': nama,
          'harga': harga,
          'kategori_id': kategoriId,
          'image_path': imagePath,
          'added_by': username, // Added field with extracted user ID
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.insert(
        'stok_tas',
        {'tas_id': id, 'stok': stok},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return id;
    });

    return tasId;
  }

  Future<List<Map<String, dynamic>>> getDataTas(String username) async {
    final Database db = await database;

    // Fetch data from 'tas' table including 'stok' field
    final List<Map<String, dynamic>> tasList = await db.rawQuery('''
    SELECT tas.*, COALESCE(stok_tas.stok, 0) AS stok
    FROM tas
    LEFT JOIN stok_tas ON tas.id = stok_tas.tas_id
    WHERE added_by = ?
    ''', [username]);

    List<Map<String, dynamic>> newTasList = List.from(tasList);

    // Iterate through the tasList and fetch kategori_nama for each item
    for (var i = 0; i < tasList.length; i++) {
      final int kategoriId = tasList[i]['kategori_id'] as int;

      // Fetch kategori_nama based on kategori_id
      final List<Map<String, dynamic>> kategoriData = await db.query(
        'kategori_tas',
        where: 'id = ?',
        whereArgs: [kategoriId],
      );

      print('Tas ID: ${tasList[i]['id']}');
      print('Kategori ID: $kategoriId');

      if (kategoriData.isNotEmpty) {
        final String kategoriNama = kategoriData[0]['nama'] as String;
        print('Kategori Nama: $kategoriNama');

        // Create a mutable copy of tas and add 'kategori_nama'
        Map<String, dynamic> mutableTas = Map.from(tasList[i]);
        mutableTas['kategori_nama'] = kategoriNama;

        // Update the original tas in the new list
        newTasList[i] = mutableTas;
      } else {
        print('No category data found for ID: $kategoriId');
      }
    }

    return newTasList;
  }

  Future<List<Map<String, dynamic>>> getDataCategories(String username) async {
    // Update the query to include "added_by"
    return await _database.query(
      'kategori_tas',
      where: 'added_by = ?',
      whereArgs: [username],
    );
  }

  Future<void> deleteTas(int id) async {
    final Database db = await _database;
    await db.delete('tas', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getTasById(int tasId) async {
    final Database db = await database;

    final List<Map<String, dynamic>> tasList = await db.rawQuery('''
      SELECT tas.*, COALESCE(stok_tas.stok, 0) AS stok
      FROM tas
      LEFT JOIN stok_tas ON tas.id = stok_tas.tas_id
      WHERE tas.id = ?
    ''', [tasId]);

    if (tasList.isNotEmpty) {
      // Fetch kategori_nama for the tas
      final int kategoriId = tasList[0]['kategori_id'] as int;

      final List<Map<String, dynamic>> kategoriData = await db.query(
        'kategori_tas',
        where: 'id = ?',
        whereArgs: [kategoriId],
      );

      print('Tas ID: ${tasList[0]['id']}');
      print('Kategori ID: $kategoriId');

      if (kategoriData.isNotEmpty) {
        final String kategoriNama = kategoriData[0]['nama'] as String;
        print('Kategori Nama: $kategoriNama');

        // Create a mutable copy of tas and add 'kategori_nama'
        Map<String, dynamic> mutableTas = Map.from(tasList[0]);
        mutableTas['kategori_nama'] = kategoriNama;

        return mutableTas;
      } else {
        print('No category data found for ID: $kategoriId');
      }
    } else {
      print('No tas data found for ID: $tasId');
    }

    return null;
  }

  Future<void> updateTas(int tasId, Map<String, dynamic> updatedData) async {
    await _database.update(
      'tas',
      updatedData,
      where: 'id = ?',
      whereArgs: [tasId],
    );
  }

  Future<void> editTasWithImage(
      int id, Map<String, dynamic> updatedData, File? newImage) async {
    final Database database = await _database.database;

    String imagePath = '';

    if (newImage != null) {
      // Copy the new image to the app's documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String uniqueFileName =
          DateTime.now().millisecondsSinceEpoch.toString();
      final String newFilePath = '${appDocDir.path}/assets/$uniqueFileName.png';

      try {
        await newImage.copy(newFilePath);
        imagePath = newFilePath;
      } on FileSystemException catch (e) {
        print('Error copying image: $e');
      }
    }

    // Update the tas data in the database
    await database.update(
      'tas',
      {
        ...updatedData,
        'image_path': imagePath,
      },
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> registerUser(
      String username, String password, String userType) async {
    final Database database = await _database.database;

    try {
      await database.insert(
        'users',
        {'username': username, 'password': password, 'user_type': userType},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true; // Registration successful
    } catch (e) {
      print('Error registering user: $e');
      return false; // Registration failed
    }
  }

  // Function to validate login credentials
  Future<Map<String, dynamic>> validateLogin(
      String username, String password) async {
    final Database database = await _database.database;

    final List<Map<String, dynamic>> user = await database.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (user.isNotEmpty) {
      // Return both validation result and user type
      return {
        'isValid': true,
        'userType': user[0]
            ['user_type'], // Replace 'userType' with the actual column name
        'userName': user[0]['username'],
      };
    } else {
      // Return validation result and null for user type
      return {
        'isValid': false,
        'userType': null,
      };
    }
  }
}
