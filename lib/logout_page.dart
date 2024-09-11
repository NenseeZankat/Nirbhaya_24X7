import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import Firebase Auth package

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  void _logout(BuildContext context) async {
    // Firebase sign out
    await FirebaseAuth.instance.signOut();  // Sign out the user from Firebase

    // Navigate back to the login page or main entry page
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  State<StatefulWidget> createState() {
    throw UnimplementedError();
  }
}
