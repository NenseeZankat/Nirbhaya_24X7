import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import Firebase Auth package

class LogoutPage extends StatefulWidget {
  const LogoutPage({Key? key}) : super(key: key);  // Proper key constructor

  @override
  _LogoutPageState createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  // Function to handle logout
  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();  // Sign out the user from Firebase

      // Navigate to the contacts page and clear the previous routes to prevent going back
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/contacts',  // Replace with your login or home page route
            (Route<dynamic> route) => false,  // Remove all previous routes
      );
    } catch (e) {
      // Handle errors (optional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logout Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _logout(context),  // Call the logout function
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
