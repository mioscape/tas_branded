// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bag_branded/services/database_helper.dart';
import 'package:search_page/search_page.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';

class ShopPage extends StatefulWidget {
  final String? username;

  const ShopPage({super.key, this.username});

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late DatabaseHelper _databaseHelper;
  List<Map<String, dynamic>> _originalBagList = [];
  Map<int, List<Map<String, dynamic>>> _categorizedBag = {};
  final _currencyFormatter = CurrencyTextInputFormatter(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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

  Widget buildCard(BuildContext context, Map<String, dynamic> bag,
      String category, String type) {
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
                    if (type == 'shop') ...[
                      Text(
                        (bag['name'].toString().length >= 13)
                            ? '${bag['name'].toString().substring(0, 13)}...'
                            : bag['name'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '${bag['category_name']} - ${bag['name'].toString()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4.0),
                    Text(
                      _currencyFormatter.format(bag['price'].toString()),
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
    final isInCart =
        await _databaseHelper.isBagInCart(bagId, widget.username!, 'pending');

    if (isInCart) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bag is already in the cart.'),
          content: const Text(
            'Please go to the cart to change the quantity.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      await _databaseHelper.addToCart(bagId, 1, widget.username!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bag added to the cart.'),
          duration: Duration(seconds: 2),
        ),
      );

      _readData();
    }
  }

  ImageProvider<Object>? getImageProvider(Map<String, dynamic> item) {
    if (item['image_path'] != null) {
      return FileImage(File(item['image_path']));
    } else {
      return const AssetImage('assets/images/no_image.png');
    }
  }

  void _showItemDetails(Map<String, dynamic> item, String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
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
                Container(
                  width: double.infinity,
                  height: 300.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    image: DecorationImage(
                      image: getImageProvider(item)!,
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
                        _currencyFormatter.format(item['price'].toString()),
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
                const Divider(),
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 200.0, // Adjust the maxHeight as needed
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Description:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  Text(
                                    '${item['description'] ?? 'No description available'}',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ])),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0), // Adjusted spacing
                Container(
                  alignment: Alignment.center,
                  child: item['stock'] > 0
                      ? OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            fixedSize: const Size(400.0, 50.0),
                          ),
                          onPressed: () {
                            _buyBag(item['id']);
                            Navigator.pop(context);
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
                      buildCard(context, bag, bag['category_name'], 'search'),
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
                        return buildCard(
                            context, bag, bag['category_name'], 'shop');
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
                                    context, bag, bag['category_name'], 'shop');
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
