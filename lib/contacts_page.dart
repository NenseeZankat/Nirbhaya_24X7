import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'map.dart'; // Import the map screen for selecting a location

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  double latitude = 0.0;
  double longitude = 0.0;
  String searchQuery = ''; // Store search query for filtering contacts
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // List<Map<String, dynamic>> contacts = [];

  // List of emergency contacts
  List<Map<String, String>> contacts = [
    {'name': 'Women helpline', 'phone': '181'},
    {'name': 'Police', 'phone': '100'},
    {'name': 'Ambulance', 'phone': '108'},
    {'name': 'Fire Brigade', 'phone': '101'},
  ];

  // _ContactsPageState()
  // {
  //   _fetchContactsForUser();
  // }
  //
  // Future<void> _fetchContactsForUser() async {
  //   try {
  //     String? userEmail = _auth.currentUser?.email;
  //
  //     if (userEmail != null) {
  //       QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //           .collection('contacts')
  //           .where('email', isEqualTo: userEmail)
  //           .get();
  //
  //       List<Map<String, dynamic>> fetchedContacts = querySnapshot.docs.map((doc) {
  //         return {
  //           'name': doc['name'] ?? 'Unknown',
  //           'phone': doc['phone'] ?? 'No phone number',
  //           'email': doc['email'] ?? 'No email',
  //         };
  //       }).toList();
  //
  //       // Check if the widget is still mounted before calling setState
  //       if (mounted) {
  //         setState(() {
  //           contacts = fetchedContacts;
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print('Error fetching contacts: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Failed to fetch contacts')),
  //       );
  //     }
  //   }
  // }


  // Future<void> addContact(String name,String phone) async {
  //   // Get the current signed-in user
  //   User? user = FirebaseAuth.instance.currentUser;
  //
  //   // Check if the user is signed in
  //   if (user != null) {
  //     String email = user.email ?? ''; // Get the user's email, default to empty string if null
  //
  //     // Add the contact to Firestore with the signed-in user's email
  //     await FirebaseFirestore.instance.collection('contacts').add({
  //       'name': name,
  //       'phone': phone,
  //       'email': email, // Add the signed-in user's email
  //     });
  //   } else {
  //     print("No user is signed in.");
  //     // Handle the case where no user is signed in, perhaps by prompting login
  //   }
  // }


  // Function to make a direct phone call
  void _callContact(String phone) async {
    await FlutterPhoneDirectCaller.callNumber(phone);
  }

  // Function to send a predefined SMS message
  void _messageContact(String phone) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{'body': 'Please help me....!'},
    );

    // Launch the SMS app if available
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch SMS app for $phone')),
      );
    }
  }

  // Function to open the map screen and select a location
  Future<void> _openMap() async {
    LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );

    // Update the selected latitude and longitude
    if (selectedLocation != null) {
      setState(() {
        latitude = selectedLocation.latitude;
        longitude = selectedLocation.longitude;
      });
      print('Selected Latitude: $latitude, Longitude: $longitude');
    }
  }

  // Function to check if the contact is a duplicate (by phone number)
  bool _isDuplicateContact(String phone) {
    for (var contact in contacts) {
      if (contact['phone'] == phone) {
        return true;
      }
    }
    return false;
  }

  // Function to add a contact from the user's phonebook
  Future<void> _addContactFromPhone() async {
    // Request permission to access contacts
    var permission = await Permission.contacts.request();

    if (permission.isGranted) {
      // Retrieve contacts from the device
      final Iterable<Contact> contactsFromDevice = await ContactsService.getContacts();

      // Show a dialog to select a contact
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Contact'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                children: contactsFromDevice.map((contact) {
                  return ListTile(
                    title: Text(contact.displayName ?? 'Unknown'),
                    subtitle: Text(contact.phones?.isNotEmpty == true
                        ? contact.phones!.first.value!
                        : 'No phone number'),
                    onTap: () {
                      // Add the selected contact if it's not a duplicate
                      if (contact.phones?.isNotEmpty == true) {
                        String phone = contact.phones!.first.value!;
                        if (!_isDuplicateContact(phone)) {
                          setState(() {
                            contacts.add({
                              'name': contact.displayName ?? 'Unknown',
                              'phone': phone,
                            });
                            // addContact(contact.displayName ?? 'Unknown',phone);
                          });
                          Navigator.of(context).pop();
                        } else {
                          // Show a message if the contact is a duplicate
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contact already exists')),
                          );
                        }
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    } else {
      // Handle permission denial
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission to access contacts denied')),
      );
    }
  }

  // Function to log out and navigate back to login page
  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    // Filter contacts based on search query
    final filteredContacts = contacts
        .where((contact) =>
    contact['name']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
        contact['phone']!.contains(searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('android/images/women_safety.jpeg'), // Ensure this path is correct
                  radius: 20, // Adjust the size of the logo as needed
                ),
                SizedBox(width: 10),
                Text('Nirbhaya 24X7'),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context), // Add logout functionality
            ),
          ],
        ),
        // Add a search bar at the bottom of the app bar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80.0), // Adjusted size for the search bar
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Contacts',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query; // Update the search query
                });
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: filteredContacts.length, // Use filtered contacts
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['name']!,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(contact['phone']!,
                              style: const TextStyle(color: Colors.black)),
                          Container(
                            color: Colors.grey[200],
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _callContact(contact['phone']!),
                                  icon: const Icon(Icons.call),
                                  label: const Text('Call'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _messageContact(contact['phone']!),
                                  icon: const Icon(Icons.message),
                                  label: const Text('Message'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Bottom navigation bar with map and share buttons
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: _openMap, // Open map to select a location
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _openMap, // For future sharing functionality
            ),
          ],
        ),
      ),
      // Floating action button to add a contact from the phone
      floatingActionButton: FloatingActionButton(
        onPressed: _addContactFromPhone,
        child: const Icon(Icons.add),
      ),
    );
  }
}
