import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      join(await getDatabasesPath(), 'tas_branded.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tas (
            id INTEGER PRIMARY KEY,
            nama TEXT,
            harga INTEGER,
            kategori_id INTEGER,
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

  Future<List<Map<String, dynamic>>> getCategories() async {
    return _database.query('kategori_tas');
  }

  // Other methods for CRUD operations go here
}
