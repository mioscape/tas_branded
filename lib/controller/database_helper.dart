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
            image_path TEXT,
            FOREIGN KEY (kategori_id) REFERENCES kategori_tas(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE kategori_tas (
            id INTEGER PRIMARY KEY,
            nama TEXT
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
      },
      version: 1,
    );

    return _database;
  }

  // Existing methods...

  // Function to add a new category to the database
  Future<void> addKategori(String nama) async {
    final Database database = await _database.database;
    await database.insert(
      'kategori_tas',
      {'nama': nama},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addTas(String nama, int harga, int kategoriId) async {
    final Database database = await _database.database;
    await database.insert(
      'tas',
      {'nama': nama, 'harga': harga, 'kategori_id': kategoriId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> addTasWithImage(String nama, int harga, int kategoriId, File? image, int stok) async {
  final Database database = await _database.database;

  String imagePath = '';

  if (image != null) {
    // Copy the image to the app's documents directory
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
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


  Future<List<Map<String, dynamic>>> getDataTas() async {
  final Database db = await database;

  // Fetch data from 'tas' table including 'stok' field
  final List<Map<String, dynamic>> tasList = await db.rawQuery('''
    SELECT tas.*, COALESCE(stok_tas.stok, 0) AS stok
    FROM tas
    LEFT JOIN stok_tas ON tas.id = stok_tas.tas_id
  ''');

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

  Future<List<Map<String, dynamic>>> getDataCategories() async {
    return await _database.query('kategori_tas');
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
}