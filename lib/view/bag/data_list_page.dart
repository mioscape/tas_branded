// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bag_branded/services/database_helper.dart';
import 'package:bag_branded/view/bag/edit_page.dart';
import 'package:intl/intl.dart';

class DataListPage extends StatefulWidget {
  final String username;
  final String password;
  @override
  _DataListPageState createState() => _DataListPageState();

  const DataListPage(
      {super.key, required this.username, required this.password});
}

class _DataListPageState extends State<DataListPage> {
  late DatabaseHelper _databaseHelper;
  List<Map<String, dynamic>> _originalBagList = [];
  List<Map<String, dynamic>> _bagList = [];
  Map<String, List<Map<String, dynamic>>> categoryData = {};
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _readData();
  }

  Future<void> _readData() async {
    await _databaseHelper.initializeDatabase();

    //
    final List<Map<String, dynamic>> bagList =
        await _databaseHelper.getDataBag(widget.username);

    setState(() {
      _originalBagList = List.from(bagList);
      _bagList = bagList;
      categoryData = _groupDataByCategory(_bagList);
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupDataByCategory(
      List<Map<String, dynamic>> bagList) {
    Map<String, List<Map<String, dynamic>>> groupedData = {};

    for (var bag in bagList) {
      var categoryId = bag['category_id'] as int?;
      var categoryName = bag['category_name'] as String?;

      if (categoryId != null && categoryName != null) {
        var categoryKey = '$categoryId-$categoryName';

        if (!groupedData.containsKey(categoryKey)) {
          groupedData[categoryKey] = [];
        }

        groupedData[categoryKey]!.add(bag);
      }
    }

    return groupedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                return buildSearchBar(controller);
              },
              suggestionsBuilder:
                  (BuildContext context, SearchController controller) {
                return buildSuggestions(controller);
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: categoryData.keys.length,
                itemBuilder: (context, index) {
                  String categoryKey = categoryData.keys.elementAt(index);
                  List<Map<String, dynamic>> dataCategory =
                      categoryData[categoryKey]!;

                  List<String> parts = categoryKey.split('-');
                  int categoryId = int.parse(parts[0]);
                  String categoryName = parts[1];

                  return ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Category $categoryName'),
                        IconButton(
                          icon: const Icon(Icons.delete_forever_outlined),
                          onPressed: () {
                            _deleteCategoryButtonPressed(categoryId);
                          },
                        ),
                      ],
                    ),
                    children: [
                      ...dataCategory.map((bag) {
                        return buildListTile(context, bag);
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBar(SearchController controller) {
    return SearchBar(
      controller: controller,
      hintText: 'Search Bags',
      padding: const MaterialStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 16.0)),
      onTap: () {
        controller.openView();
      },
      onChanged: (_) {
        controller.openView();
      },
      leading: const Icon(Icons.search),
    );
  }

  Iterable<Widget> buildSuggestions(SearchController controller) {
    final List<Map<String, dynamic>> filteredBagList = _originalBagList
        .where((bag) => bag['name']
            .toString()
            .toLowerCase()
            .contains(controller.text.toLowerCase()))
        .toList();

    return filteredBagList.map((bag) {
      return buildListTile(context, bag);
    });
  }

  Widget buildListTile(BuildContext context, Map<String, dynamic> bag) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            fit: BoxFit.cover,
            image: bag['image_path'] != null
                ? FileImage(File(bag['image_path']))
                : const AssetImage('assets/images/no_image.png')
                    as ImageProvider,
          ),
        ),
      ),
      title: Text(bag['name']),
      subtitle: Text(
          'Price: ${formatCurrency(bag['price'])}\nStock: ${bag['stock']}'),
      trailing: PopupMenuButton<String>(
        itemBuilder: (BuildContext context) {
          return {'Edit', 'Delete', 'Open Image'}.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
        onSelected: (String choice) {
          switch (choice) {
            case 'Edit':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditBagPage(
                    bagId: bag['id'],
                    onBagUpdated: () {
                      _readData();
                    },
                  ),
                ),
              );
              break;
            case 'Delete':
              _deleteData(bag['id']);
              break;
            case 'Open Image':
              _openImage(bag['image_path']);
              break;
          }
        },
      ),
    );
  }

  void _deleteCategoryButtonPressed(categoryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category Confirmation'),
          content: const Text(
              'Are you sure you want to delete this category and all associated bags?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _deleteCategoryPassword(categoryId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategoryPassword(int categoryId) {
    final password = widget.password;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password to Delete Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_passwordController.text == password) {
                  await _deleteCategory(categoryId);
                  await _readData();
                  _passwordController.clear();
                  Navigator.of(context).pop();
                } else {
                  _showErrorDialog(context, 'Incorrect password');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCategory(int categoryId) async {
    try {
      await _databaseHelper.deleteCategory(categoryId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category deleted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error deleting category'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteData(int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Data Confirmation'),
          content: const Text('Are you sure you want to delete this data?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red),
              ),
              onPressed: () async {
                await _databaseHelper.deleteBag(id);
                _readData();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _openImage(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.0),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  String formatCurrency(int price) {
    final NumberFormat formatCurrency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(price);
  }
}
