// ignore_for_file: use_build_context_synchronously, avoid_print, library_private_types_in_public_api

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bag_branded/services/database_helper.dart';
import 'package:intl/intl.dart';

class CartPage extends StatefulWidget {
  final String? username;

  const CartPage({super.key, this.username});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  late DatabaseHelper _databaseHelper;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _databaseHelper = DatabaseHelper();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent('pending'),
          _buildTabContent('done'),
        ],
      ),
    );
  }

  Widget _buildTabContent(String status) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getCartItems(widget.username!, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No items in the cart.'),
          );
        } else {
          List<Map<String, dynamic>> cartItems = snapshot.data!;
          Future<void> readData() async {
            try {
              final List<Map<String, dynamic>> cartItems0 =
                  await _databaseHelper.getCartItems(
                      widget.username!, 'pending');

              setState(() {
                cartItems = cartItems0;
              });
            } catch (e) {
              print('Error reading data: $e');
            }
          }

          return ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> cartItem = cartItems[index];

              void decrementQuantity(StateSetter setState) {
                if (cartItem['quantity'] > 1) {
                  setState(() {
                    cartItem['quantity']--;

                    _databaseHelper.updateCartItemQuantity(
                      cartItem['id'],
                      cartItem['quantity'],
                    );
                  });
                }
              }

              void incrementQuantity(StateSetter setState) {
                if (cartItem['quantity'] < cartItem['stock']) {
                  setState(() {
                    cartItem['quantity']++;

                    _databaseHelper.updateCartItemQuantity(
                      cartItem['id'],
                      cartItem['quantity'],
                    );
                  });
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Out of Stock'),
                      content: const Text(
                        'The quantity you have selected is not available.',
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
                }
              }

              void showCartItemDetails(Map<String, dynamic> cartItem) {
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
                          Container(
                            width: double.infinity,
                            height: 200.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              image: DecorationImage(
                                image: cartItem['image_path'] != null
                                    ? FileImage(File(cartItem['image_path']))
                                    : const AssetImage(
                                            'assets/images/no_image.png')
                                        as ImageProvider,
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
                                  '${cartItem['category_name']} - ${cartItem['name']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  formatCurrency(cartItem['price']),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18.0,
                                  ),
                                ),
                                Text(
                                  'Stock: ${cartItem['stock']}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16.0,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () {
                    showCartItemDetails(cartItem);
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
                            image: cartItem['image_path'] != null
                                ? FileImage(File(cartItem['image_path']))
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
                              '${cartItem['category_name']} - ${cartItem['name'].toString()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              formatCurrency(cartItem['price']),
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            if (status == 'done') ...[
                              const SizedBox(height: 4.0),
                              Text(
                                'Total: ${formatCurrency(cartItem['price'] * cartItem['quantity'])}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Stock: ${cartItem['stock']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            StatefulBuilder(
                              builder: (context, setState) => Row(
                                children: [
                                  const Text('Quantity:'),
                                  SizedBox(
                                    width: 130,
                                    child: Row(
                                      children: [
                                        if (cartItem['stock'] == 0 ||
                                            status == 'done')
                                          ...[]
                                        else ...[
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () {
                                              decrementQuantity(setState);
                                            },
                                          ),
                                        ],
                                        if (cartItem['stock'] == 0) ...[
                                          const Text(
                                            ' Out of Stock',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 16.0,
                                            ),
                                          ),
                                        ] else ...[
                                          if (status == 'done') ...[
                                            Text(
                                              ' ${cartItem['quantity']}',
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                              ),
                                            ),
                                          ] else ...[
                                            SizedBox(
                                              width: 50,
                                              height: 40,
                                              child: TextField(
                                                keyboardType:
                                                    TextInputType.number,
                                                controller:
                                                    TextEditingController(
                                                  text: cartItem['quantity']
                                                      .toString(),
                                                ),
                                                textAlign: TextAlign.center,
                                                readOnly: true,
                                                decoration:
                                                    const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                        if (cartItem['stock'] == 0 ||
                                            status == 'done')
                                          ...[]
                                        else ...[
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              incrementQuantity(setState);
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status == 'pending') ...[
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            alignment: Alignment.center,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                fixedSize: const Size(200, 48),
                              ),
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Remove from Cart'),
                                    content: const Text(
                                      'Are you sure you want to remove this item from your cart?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await _databaseHelper
                                              .removeFromCart(cartItem['id']);
                                          await readData();
                                          Navigator.pop(context);
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text(
                                'Remove from Cart',
                                style: TextStyle(
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (cartItem['stock'] == 0 || status == 'done')
                        ...[]
                      else ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16),
                          child: Container(
                            alignment: Alignment.center,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                fixedSize: const Size(200, 48),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Checkout'),
                                    content: Text(
                                      'Are you sure you want to checkout? You will not be able to edit your cart after this.\nTotal: ${formatCurrency(cartItem['price'] * cartItem['quantity'])}',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await _checkout(cartItem['bag_id']);
                                          await readData();
                                          Navigator.pop(context);
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text(
                                'Checkout',
                                style: TextStyle(
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<void> _checkout(int bagId) async {
    try {
      await _databaseHelper.checkoutCart(widget.username!, bagId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkout successful!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error during checkout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkout failed. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String formatCurrency(int price) {
    final NumberFormat formatCurrency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(price);
  }
}
