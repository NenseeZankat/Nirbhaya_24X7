import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_project/register_page.dart';
import 'login_page.dart';
import 'contacts_page.dart';
import 'logout_page.dart'; // Import your logout page

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  // if(kIsWeb)
  //   {
      await Firebase.initializeApp(options: const FirebaseOptions(
          apiKey: "AIzaSyD9G9HVDYAB1ONNkx-dx7X5uIODWhUtbf8",
          authDomain: "my-project-333ab.firebaseapp.com",
          projectId: "my-project-333ab",
          storageBucket: "my-project-333ab.appspot.com",
          messagingSenderId: "695266334680",
          appId: "1:695266334680:web:770fc1aee6a318dd5884ad",
          measurementId: "G-RBVGL9S489"));
  //   }
  // else
  //   {
  //     await Firebase.initializeApp();
  //   }

  runApp(MaterialApp(
    title: 'Nirbhaya 24X7',
    initialRoute: '/contacts',
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
      initialRoute: '/contacts', // Default route
      routes: {
        '/login': (context) => const LoginPage(), // Login page route
        '/contacts': (context) => const ContactsPage(), // Contacts page route
        '/logout': (context) => const LogoutPage(), // Logout page route
      },
    );
  }
}
