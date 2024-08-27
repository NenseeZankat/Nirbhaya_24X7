import 'package:flutter/material.dart';
import 'package:my_project/register_page.dart';
import 'login_page.dart';
import 'contacts_page.dart';
import 'logout_page.dart'; // Import your logout page

void main() {
  runApp(MaterialApp(
    title: 'Nirbhaya 24X7',
    initialRoute: '/login',
    routes: {
      '/login': (context) => const LoginPage(),
      '/contacts': (context) => const ContactsPage(),
      '/register': (context) => const RegisterPage(),
    },
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirbhaya 24X7',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Default route
      routes: {
        '/login': (context) => const LoginPage(), // Login page route
        '/contacts': (context) => const ContactsPage(), // Contacts page route
        '/logout': (context) => const LogoutPage(), // Logout page route
      },
    );
  }
}
