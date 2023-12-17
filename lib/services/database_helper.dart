import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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
  static const String cartTable = 'cart';

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

  // cartTable columns
  static const String quantityColumn = 'quantity';
  static const String statusColumn = 'status';

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
      join(await getDatabasesPath(), 'bag_branded_dev.db'),
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
        await db.execute('''
          CREATE TABLE cart (
            id INTEGER PRIMARY KEY,
            bag_id INTEGER,
            quantity INTEGER,
            username TEXT,
            status TEXT,
            FOREIGN KEY (bag_id) REFERENCES bag(id)
            FOREIGN KEY (username) REFERENCES users(username)
          )
        ''');
      },
      version: 1,
    );

    return _database;
  }

  Future<List<Map<String, dynamic>>> getAllBag() async {
    final Database db = await database;

    final List<Map<String, dynamic>> bagList = await db.rawQuery('''
    SELECT bag.*, COALESCE(stock_bag.stock, 0) AS stock
    FROM bag
    LEFT JOIN stock_bag ON bag.id = stock_bag.bag_id
    ''');

    List<Map<String, dynamic>> newBagList = List.from(bagList);

    for (var i = 0; i < bagList.length; i++) {
      final int categoryId = bagList[i]['category_id'] as int;

      // Fetch category_name based on category_id
      final List<Map<String, dynamic>> categoryData = await db.query(
        'category_bag',
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      if (categoryData.isNotEmpty) {
        final String categoryName = categoryData[0]['name'] as String;

        Map<String, dynamic> mutableBag = Map.from(bagList[i]);
        mutableBag['category_name'] = categoryName;
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

    final List<Map<String, dynamic>> bagList = await db.rawQuery('''
    SELECT bag.*, COALESCE(stock_bag.stock, 0) AS stock
    FROM bag
    LEFT JOIN stock_bag ON bag.id = stock_bag.bag_id
    WHERE added_by = ?
    ''', [username]);

    List<Map<String, dynamic>> newBagList = List.from(bagList);

    for (var i = 0; i < bagList.length; i++) {
      final int categoryId = bagList[i]['category_id'] as int;

      final List<Map<String, dynamic>> categoryData = await db.query(
        'category_bag',
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      if (categoryData.isNotEmpty) {
        final String categoryName = categoryData[0]['name'] as String;

        Map<String, dynamic> mutableBag = Map.from(bagList[i]);
        mutableBag['category_name'] = categoryName;
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
      final int categoryId = bagList[0]['category_id'] as int;

      final List<Map<String, dynamic>> categoryData = await db.query(
        'category_bag',
        where: 'id = ?',
        whereArgs: [categoryId],
      );
      if (categoryData.isNotEmpty) {
        final String categoryName = categoryData[0]['name'] as String;

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

    final List<Map<String, dynamic>> isUsernameTaken = await database.query(
      usersTable,
      where: 'username = ?',
      whereArgs: [users.username],
    );

    if (isUsernameTaken.isNotEmpty) {
      return false;
    } else {
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
        return true;
      } catch (e) {
        print('Error registering user: $e');
        return false; // Registration failed
      }
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
        'userType': user[0]['user_type'],
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
      await db.transaction((txn) async {
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

        await txn.delete(
          'category_bag',
          where: 'id = ?',
          whereArgs: [categoryId],
        );
      });
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(int id) async {
    final Database db = await database;

    try {
      await db.transaction((txn) async {
        await txn.delete(
          'cart',
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      print('Error deleting cart: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems(
      String username, String status) async {
    final Database db = await initializeDatabase();

    final List<Map<String, dynamic>> cartItems = await db.rawQuery(
      'SELECT * FROM $cartTable WHERE username = ? AND status = ?',
      [username, status],
    );

    final List<Map<String, dynamic>> completeCartItems = [];
    for (final cartItem in cartItems) {
      final bagDetails = await getBagDetails(cartItem['bag_id']);
      if (bagDetails != null) {
        completeCartItems.add({
          ...cartItem,
          'id': cartItem['id'],
          'name': bagDetails['name'],
          'image_path': bagDetails['image_path'],
          'stock': bagDetails['stock'],
          'price': bagDetails['price'],
        });
      }
    }

    return completeCartItems;
  }

  Future<Map<String, dynamic>?> getBagDetails(int bagId) async {
    final Database db = await initializeDatabase();

    final List<Map<String, dynamic>> bagDetails = await db.rawQuery('''
    SELECT bag.*, COALESCE(stock_bag.stock, 0) AS stock
    FROM $bagTable
    LEFT JOIN $stockBagTable ON $bagTable.id = $stockBagTable.bag_id
    WHERE $bagTable.id = ?
    LIMIT 1
    ''', [bagId]);

    return bagDetails.isNotEmpty ? bagDetails.first : null;
  }

  Future<bool> isBagInCart(int bagId, String username, String status) async {
    final Database db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      cartTable,
      where: 'bag_id = ? AND username = ? AND status = ?',
      whereArgs: [bagId, username, status],
    );

    return result.isNotEmpty;
  }

  Future<void> addToCart(int bagId, int quantity, String username) async {
    final Database db = await database;

    final bool isInCart = await isBagInCart(bagId, username, 'pending');

    if (isInCart) {
      await db.update(
        cartTable,
        {'quantity': quantity},
        where: 'bag_id = ? AND username = ?',
        whereArgs: [bagId, username],
      );
    } else {
      await db.insert(
        cartTable,
        {
          'bag_id': bagId,
          'quantity': quantity,
          'username': username,
          'status': 'pending',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> updateCartItemQuantity(int id, int newQuantity) async {
    final Database db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      cartTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      await db.update(
        cartTable,
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      print('Error: Bag not found in the cart.');
    }
  }

  Future<void> checkoutCart(String username, int bagId) async {
    final Database db = await database;

    // Get the bag details
    final bagDetails = await db.query(
      'stock_bag',
      where: 'bag_id = ?',
      whereArgs: [bagId],
      limit: 1,
    );

    if (bagDetails.isNotEmpty) {
      final int availableStock = (bagDetails.first['stock'] as int?) ?? 0;
      print('Available stock: $availableStock');

      final int totalQuantityInCart = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT SUM(quantity) FROM cart WHERE bag_id = ? AND username = ? AND status = ?',
            [bagId, username, 'pending'],
          )) ??
          0;

      print('Total quantity in cart: $totalQuantityInCart');

      if (totalQuantityInCart <= availableStock) {
        final int remainingStock = availableStock - totalQuantityInCart;
        print('Remaining stock: $remainingStock');

        await db.update(
          'stock_bag',
          {'stock': remainingStock},
          where: 'bag_id = ?',
          whereArgs: [bagId],
        );

        await db.update(
          'cart',
          {'status': 'done'},
          where: 'bag_id = ? AND username = ?',
          whereArgs: [bagId, username],
        );
      } else {
        throw Exception('Checkout failed. Quantity exceeds available stock.');
      }
    } else {
      throw Exception('Bag not found.');
    }
  }
}
