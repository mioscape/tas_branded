import 'package:flutter/material.dart';

class DetailItemPage extends StatefulWidget {
  final Map<String, dynamic> bag;

  DetailItemPage({required this.bag});

  @override
  _DetailItemPageState createState() => _DetailItemPageState();
}

class _DetailItemPageState extends State<DetailItemPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display item details here, for example:
            Text('name: ${widget.bag['name']}'),
            Text('Price: ${widget.bag['price']}'),
            Text('Stock: ${widget.bag['stock']}'),
            // Add more details as needed
          ],
        ),
      ),
    );
  }
}
