import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bag_branded/services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:search_page/search_page.dart';

class ShopPage extends StatefulWidget {
  final String? username;

  ShopPage({this.username});

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late DatabaseHelper _databaseHelper;
  List<Map<String, dynamic>> _originalBagList = [];
  Map<int, List<Map<String, dynamic>>> _categorizedBag = {};

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _readData();
  }

  Future<void> _readData() async {
    await _databaseHelper.initializeDatabase();

    final List<Map<String, dynamic>> bagList =
        await _databaseHelper.getAllBag();

    setState(() {
      _originalBagList = List.from(bagList);
      _categorizedBag = _groupDataByCategory(_originalBagList);
    });
  }

  Map<int, List<Map<String, dynamic>>> _groupDataByCategory(
      List<Map<String, dynamic>> bagList) {
    Map<int, List<Map<String, dynamic>>> groupedData = {};

    for (var bag in bagList) {
      var categoryId = bag['category_id'] as int?;
      if (categoryId != null) {
        if (!groupedData.containsKey(categoryId)) {
          groupedData[categoryId] = [];
        }
        groupedData[categoryId]!.add(bag);
      }
    }

    return groupedData;
  }

  Widget buildCard(
      BuildContext context, Map<String, dynamic> bag, String category) {
    double cardWidth = 200.0;
    int stock = bag['stock'] ?? 0;

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: InkWell(
          onTap: () {
            // Handle card tap, e.g., navigate to details page
            // _navigateToDetailItemPage(context, bag);
            _showItemDetails(bag, category);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    topRight: Radius.circular(12.0),
                  ),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: bag['image_path'] != null
                        ? FileImage(File(bag['image_path']))
                        : const AssetImage('assets/images/no_image.png')
                            as ImageProvider,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (bag['name'].toString().length >= 13)
                          ? '${bag['name'].toString().substring(0, 13)}...'
                          : bag['name'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      formatCurrency(bag['price']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      'Stock: $stock',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: stock > 0
                    ? Container(
                        alignment: Alignment.center,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            fixedSize: const Size(168, 48),
                          ),
                          onPressed: () {
                            _buyBag(bag['id']);
                          },
                          child: const Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      )
                    : const Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.0,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _buyBag(int bagId) async {
    // Check if the bag is already in the cart
    final isInCart = await _databaseHelper.isBagInCart(bagId, widget.username!);

    if (isInCart) {
      // Show a message or handle the case where the bag is already in the cart
      print('Bag is already in the cart.');
    } else {
      // Add the bag to the cart
      await _databaseHelper.addToCart(bagId, 1, widget.username!);
      print('Bag added to the cart.');

      // Refresh the data to update the UI
      _readData();
    }
  }

  String formatCurrency(int price) {
    final NumberFormat formatCurrency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(price);
  }

  ImageProvider<Object>? getImageProvider(Map<String, dynamic> item) {
    if (item['image_path'] != null) {
      return FileImage(File(item['image_path']));
    } else {
      return const AssetImage('assets/images/no_image.png')
          as ImageProvider<Object>;
    }
  }

  void _showItemDetails(Map<String, dynamic> item, String category) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                  margin: const EdgeInsets.only(bottom: 16.0),
                ),
              ),
              // Image at the top center
              Container(
                width: double.infinity,
                height: 200.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                    image: getImageProvider(item)!, // Explicit casting
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$category - ${item['name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      formatCurrency(item['price']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 18.0,
                      ),
                    ),
                    Text(
                      'Stock: ${item['stock']}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(), // Add spacer to push the button to the bottom
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16.0),
                child: item['stock'] > 0
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          fixedSize: const Size(400.0, 50.0),
                        ),
                        onPressed: () {
                          // Add functionality for the "Add to Cart" button
                        },
                        child: const Text('Add to Cart'),
                      )
                    : const Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16.0,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SearchPage(
                  items: _originalBagList,
                  searchLabel: 'Search Bag',
                  suggestion: const Center(
                    child: Text('Filter bag by name, category, or price'),
                  ),
                  failure: const Center(
                    child: Text('No bag found :('),
                  ),
                  filter: (bag) => [
                    bag['name'].toString(),
                    bag['category_name'].toString(),
                    bag['price'].toString(),
                  ],
                  builder: (bag) =>
                      buildCard(context, bag, bag['category_name']),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'All Categories',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: 367.0,
              padding: const EdgeInsets.all(16.0),
              child: _originalBagList.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _originalBagList.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> bag = _originalBagList[
                            _originalBagList.length - index - 1];
                        return buildCard(context, bag, bag['category_name']);
                      },
                    )
                  : const Center(
                      child: Text('No bags available :('),
                    ),
            ),
            const Divider(),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _categorizedBag.keys.length,
              itemBuilder: (context, index) {
                int categoryId = _categorizedBag.keys.elementAt(index);
                List<Map<String, dynamic>> categoryItems =
                    _categorizedBag[categoryId]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Category ${categoryItems[0]['category_name']}',
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      height: 367.0,
                      child: categoryItems.isNotEmpty
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categoryItems.length,
                              itemBuilder: (context, itemIndex) {
                                Map<String, dynamic> bag =
                                    categoryItems[itemIndex];
                                return buildCard(
                                    context, bag, bag['category_name']);
                              },
                            )
                          : const Center(
                              child: Text('No bags available :('),
                            ),
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
