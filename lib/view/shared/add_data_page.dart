import 'package:flutter/material.dart';
import 'package:bag_branded/view/bag/add_page.dart';
import 'package:bag_branded/view/category/add_page.dart';
import 'package:bag_branded/services/database_helper.dart';

class TabbedPage extends StatelessWidget {
  final DatabaseHelper databaseHelper;
  final String username;

  const TabbedPage(
      {super.key, required this.databaseHelper, required this.username});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Data'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Category'),
              Tab(text: 'Bag'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AddCategoryPage(username: username),
            AddBagPage(databaseHelper: databaseHelper, username: username),
          ],
        ),
      ),
    );
  }
}
