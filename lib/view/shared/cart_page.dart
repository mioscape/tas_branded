import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bag_branded/services/database_helper.dart';
import 'package:intl/intl.dart';

class CartPage extends StatefulWidget {
  final String? username;

  CartPage({this.username});

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
    // Initialize the TabController
    _databaseHelper = DatabaseHelper();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // Dispose of the TabController when the widget is disposed
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        bottom: TabBar(
          controller: _tabController, // Set the TabController
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController, // Set the TabController
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
          return const CircularProgressIndicator();
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
              final List<Map<String, dynamic>> _cartItems =
                  await _databaseHelper.getCartItems(
                      widget.username!, 'pending');

              // Update the UI with the new cart items
              setState(() {
                cartItems = _cartItems;
              });
            } catch (e) {
              print('Error reading data: $e');
              // Handle the error, e.g., show an error message to the user
            }
          }

          return ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> cartItem = cartItems[index];

              void _decrementQuantity() {
                setState(() {
                  if (cartItem['quantity'] > 1) {
                    // If the quantity is greater than 1, decrement it
                    cartItem['quantity']--;

                    // Call your method to update the cart in the database
                    _databaseHelper.updateCartItemQuantity(
                        cartItem['id'], cartItem['quantity']);
                  }
                });
              }

              void _incrementQuantity() {
                setState(() {
                  if (cartItem['quantity'] < cartItem['stock']) {
                    cartItem['quantity']++;

                    _databaseHelper.updateCartItemQuantity(
                        cartItem['id'], cartItem['quantity']);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quantity limit reached.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                });
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () {
                    // Handle card tap, e.g., navigate to details page
                    // _navigateToCartItemDetails(context, cartItem);
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
                              (cartItem['name'].toString().length >= 50)
                                  ? '${cartItem['name'].toString().substring(0, 50)}...'
                                  : cartItem['name'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            // Text(
                            //   'Quantity: ${cartItem['quantity']}',
                            //   style: const TextStyle(
                            //     color: Colors.grey,
                            //   ),
                            // ),
                            Text(
                              'Stock: ${cartItem['stock']}',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            Row(
                              children: [
                                const Text('Quantity:'),
                                SizedBox(
                                  width: 130,
                                  child: Row(
                                    children: [
                                      if (cartItem['stock'] == 0)
                                        ...[]
                                      else ...[
                                        IconButton(
                                          icon: Icon(Icons.remove),
                                          onPressed: () {
                                            _decrementQuantity();
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
                                        SizedBox(
                                          width: 50,
                                          height: 40,
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            controller: TextEditingController(
                                                text: cartItem['quantity']
                                                    .toString()),
                                            textAlign: TextAlign.center,
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (cartItem['stock'] == 0)
                                        ...[]
                                      else ...[
                                        IconButton(
                                          icon: Icon(Icons.add),
                                          onPressed: () {
                                            _incrementQuantity();
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          alignment: Alignment.center,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              fixedSize: const Size(200, 48),
                            ),
                            onPressed: () async {
                              // Add functionality, e.g., remove from cart
                              await _databaseHelper
                                  .removeFromCart(cartItem['id']);
                              await readData();
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
                      if (cartItem['stock'] == 0)
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
                                // Add functionality, e.g., remove from cart
                                // _removeFromCart(cartItem['id']);
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

  String formatCurrency(int price) {
    final NumberFormat formatCurrency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatCurrency.format(price);
  }
}

class CartItemWidget extends StatefulWidget {
  final Map<String, dynamic> bagDetails;

  CartItemWidget({required this.bagDetails});

  @override
  _CartItemWidgetState createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late TextEditingController _quantityController;
  late int maxQuantity;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    // Initialize maxQuantity based on bagDetails['stock']
    maxQuantity = widget.bagDetails['stock'] ?? 0;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.bagDetails['name'].toString()),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Quantity:'),
              SizedBox(
                width: 120,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        // Decrease quantity
                        int currentQuantity =
                            int.parse(_quantityController.text);
                        if (currentQuantity > 1) {
                          setState(() {
                            _quantityController.text =
                                (currentQuantity - 1).toString();
                          });
                        }
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          // Update the quantity in your state or controller
                          // You can add validation to ensure it doesn't exceed maxQuantity
                          // Use TextEditingController or another state management solution
                          // to manage the quantity for each item in the cart
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        // Increase quantity
                        int currentQuantity =
                            int.parse(_quantityController.text);
                        if (currentQuantity < maxQuantity) {
                          setState(() {
                            _quantityController.text =
                                (currentQuantity + 1).toString();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      // Add more widgets as needed
    );
  }
}
