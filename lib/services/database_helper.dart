import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bag_branded/models/category_model.dart';
import 'package:bag_branded/models/stock_model.dart';
import 'package:bag_branded/models/bag_model.dart';
import 'package:bag_branded/models/users_model.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  late Database _database;

  static const String bagTable = 'bag';
  static const String categoryBagTable = 'category_bag';
  static const String stockBagTable = 'stock_bag';
  static const String usersTable = 'users';

  // idColumn is used in all tables
  static const String idColumn = 'id';

  // bagTable columns
  static const String nameColumn = 'name';
  static const String priceColumn = 'price';
  static const String imagePathColumn = 'image_path';

  // Reference columns
  static const String addedByColumn = 'added_by';
  static const String categoryIdColumn = 'category_id';
  static const String bagIdColumn = 'bag_id';

  // categoryBagTable columns
  static const String categoryNameColumn = 'name';

  // stockBagTable columns
  static const String stockColumn = 'stock';

  // usersTable columns
  static const String usernameColumn = 'username';
  static const String passwordColumn = 'password';
  static const String userTypeColumn = 'user_type';

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._();
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
      join(await getDatabasesPath(), 'bag_branded_dev_v4.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bag (
            id INTEGER PRIMARY KEY,
            name TEXT,
            price INTEGER,
            category_id INTEGER,
  			    added_by TEXT,
            image_path TEXT,
            FOREIGN KEY (category_id) REFERENCES category_bag(id),
            FOREIGN KEY (added_by) REFERENCES users(username)
          )
        ''');
        await db.execute('''
          CREATE TABLE category_bag (
            id INTEGER PRIMARY KEY,
            name TEXT,
            added_by TEXT,
            FOREIGN KEY (added_by) REFERENCES users(username)
          )
        ''');
        await db.execute('''
          CREATE TABLE stock_bag (
            id INTEGER PRIMARY KEY,
            bag_id INTEGER,
            category_id INTEGER,
            stock INTEGER,
            FOREIGN KEY (bag_id) REFERENCES bag(id)
            FOREIGN KEY (category_id) REFERENCES category_bag(id)
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
      version: 4,
    );

    return _database;
  }

  Future<List<Map<String, dynamic>>> getAllBag() async {
    final Database db = await database;

    // Fetch data from 'bag' table including 'stock' field
    final List<Map<String, dynamic>> bagList = await db.rawQuery('''
    SELECT bag.*, COALESCE(stock_bag.stock, 0) AS stock
    FROM bag
    LEFT JOIN stock_bag ON bag.id = stock_bag.bag_id
    ''');

    List<Map<String, dynamic>> newBagList = List.from(bagList);

    // Iterate through the bagList and fetch category_name for each item
    for (var i = 0; i < bagList.length; i++) {
      final int categoryId = bagList[i]['category_id'] as int;

      // Fetch category_name based on category_id
      final List<Map<String, dynamic>> categoryData = await db.query(
        'category_bag',
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      print('Bag ID: ${bagList[i]['id']}');
      print('Category ID: $categoryId');

      if (categoryData.isNotEmpty) {
        final String categoryName = categoryData[0]['name'] as String;
        print('Category Name: $categoryName');

        // Create a mutable copy of bag and add 'category_name'
        Map<String, dynamic> mutableBag = Map.from(bagList[i]);
        mutableBag['category_name'] = categoryName;

        // Update the original bag in the new list
        newBagList[i] = mutableBag;
      } else {
        print('No category data found for ID: $categoryId');
      }
    }

    return newBagList;
  }

  Future<void> addCategory(Category category) async {
    final Database database = _database.database;
    await database.insert(
      DatabaseHelper.categoryBagTable,
      {
        DatabaseHelper.categoryNameColumn: category.name,
        DatabaseHelper.addedByColumn: category.addedBy,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> addBagWithImage(Bag bag, Stock stock) async {
    final Database database = await _database.database;

    int bagId = await database.transaction<int>((txn) async {
      int id = await txn.insert(
        DatabaseHelper.bagTable,
        {
          DatabaseHelper.nameColumn: bag.name,
          DatabaseHelper.priceColumn: bag.price,
          DatabaseHelper.categoryIdColumn: bag.categoryId,
          DatabaseHelper.imagePathColumn: bag.imagePath,
          DatabaseHelper.addedByColumn: bag.addedBy,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.insert(
        DatabaseHelper.stockBagTable,
        {
          DatabaseHelper.bagIdColumn: id,
          DatabaseHelper.stockColumn: stock.stock,
          DatabaseHelper.categoryIdColumn: bag.categoryId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return id;
    });

    return bagId;
  }

  Future<List<Map<String, dynamic>>> getDataBag(String username) async {
    final Database db = await database;

    // Fetch data from 'bag' table including 'stock' field
    final List<Map<String, dynamic>> bagList = await db.rawQuery('''
    SELECT bag.*, COALESCE(stock_bag.stock, 0) AS stock
    FROM bag
    LEFT JOIN stock_bag ON bag.id = stock_bag.bag_id
    WHERE added_by = ?
    ''', [username]);

    List<Map<String, dynamic>> newBagList = List.from(bagList);

    // Iterate through the bagList and fetch category_name for each item
    for (var i = 0; i < bagList.length; i++) {
      final int categoryId = bagList[i]['category_id'] as int;

      // Fetch category_name based on category_id
      final List<Map<String, dynamic>> categoryData = await db.query(
        'category_bag',
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      print('Bag ID: ${bagList[i]['id']}');
      print('Category ID: $categoryId');

      if (categoryData.isNotEmpty) {
        final String categoryName = categoryData[0]['name'] as String;
        print('Category Name: $categoryName');

        // Create a mutable copy of bag and add 'category_name'
        Map<String, dynamic> mutableBag = Map.from(bagList[i]);
        mutableBag['category_name'] = categoryName;

        // Update the original bag in the new list
        newBagList[i] = mutableBag;
      } else {
        print('No category data found for ID: $categoryId');
      }
    }

    return newBagList;
  }

  Future<List<Map<String, dynamic>>> getDataCategories(String username) async {
    return await _database.query(
      'category_bag',
      where: 'added_by = ?',
      whereArgs: [username],
    );
  }

  Future<void> deleteBag(int id) async {
    final Database db = await _database;
    await db.delete('bag', where: 'id = ?', whereArgs: [id]);
    await db.delete('stock_bag', where: 'bag_id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getBagById(int bagId) async {
    final Database db = await database;

    final List<Map<String, dynamic>> bagList = await db.rawQuery('''
      SELECT bag.*, COALESCE(stock_bag.stock, 0) AS stock
      FROM bag
      LEFT JOIN stock_bag ON bag.id = stock_bag.bag_id
      WHERE bag.id = ?
    ''', [bagId]);

    if (bagList.isNotEmpty) {
      // Fetch category_name for the bag
      final int categoryId = bagList[0]['category_id'] as int;

      final List<Map<String, dynamic>> categoryData = await db.query(
        'category_bag',
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      print('Bag ID: ${bagList[0]['id']}');
      print('Category ID: $categoryId');

      if (categoryData.isNotEmpty) {
        final String categoryName = categoryData[0]['name'] as String;
        print('Category Name: $categoryName');

        // Create a mutable copy of bag and add 'category_name'
        Map<String, dynamic> mutableBag = Map.from(bagList[0]);
        mutableBag['category_name'] = categoryName;

        return mutableBag;
      } else {
        print('No category data found for ID: $categoryId');
      }
    } else {
      print('No bag data found for ID: $bagId');
    }

    return null;
  }

  Future<void> editBagWithImage(Bag bag, Stock stock) async {
    final Database database = await _database.database;

    await database.update(
      'bag',
      {
        DatabaseHelper.nameColumn: bag.name,
        DatabaseHelper.priceColumn: bag.price,
        DatabaseHelper.imagePathColumn: bag.imagePath,
      },
      where: 'id = ?',
      whereArgs: [bag.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await database.update(
      'stock_bag',
      {
        DatabaseHelper.stockColumn: stock.stock,
      },
      where: 'bag_id = ?',
      whereArgs: [bag.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> registerUser(Users users) async {
    final Database database = _database.database;

    try {
      await database.insert(
        DatabaseHelper.usersTable,
        {
          DatabaseHelper.usernameColumn: users.username,
          DatabaseHelper.passwordColumn: users.password,
          DatabaseHelper.userTypeColumn: users.userType,
        },
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
      return {
        'isValid': true,
        'userType': user[0]
            ['user_type'], // Replace 'userType' with the actual column name
        'username': user[0]['username'],
        'password': user[0]['password'],
      };
    } else {
      // Return validation result and null for user type
      return {
        'isValid': false,
        'userType': null,
      };
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    final Database db = await database;

    try {
      // Begin the database transaction
      await db.transaction((txn) async {
        // Delete bags associated with the category
        await txn.delete(
          'bag',
          where: 'category_id = ?',
          whereArgs: [categoryId],
        );

        await txn.delete(
          'stock_bag',
          where: 'category_id = ?',
          whereArgs: [categoryId],
        );

        // Delete the category itself
        await txn.delete(
          'category_bag',
          where: 'id = ?',
          whereArgs: [categoryId],
        );
      });
    } catch (e) {
      print('Error deleting category: $e');
      rethrow; // Re-throw the exception after logging
    }
  }
}
