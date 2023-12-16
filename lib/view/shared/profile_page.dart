import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bag_branded/view/auth/login_page.dart';

class ProfilePage extends StatelessWidget {
  final String username;
  final String userType;

  ProfilePage({required this.username, required this.userType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 100,
                  child: Icon(
                    Icons.person,
                    size: 100,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hello,',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$username!',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'User Type: $userType',
                  style: const TextStyle(
                      fontSize: 20, fontStyle: FontStyle.normal),
                ),
                const SizedBox(height: 32),
                const DarkModeSwitch(),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _logout(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Logout',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Perform logout actions, if any

                // Navigate to the login page and remove all existing routes from the stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false, // Remove all existing routes
                );
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}

class DarkModeSwitch extends StatelessWidget {
  const DarkModeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return SwitchListTile(
      title: const Text('Dark Mode'),
      value: isDarkMode,
      onChanged: (value) {
        Provider.of<ThemeProvider>(context, listen: false).toggleDarkMode();
      },
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
