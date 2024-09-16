import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Profile_page.dart';
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
  List<Map<String, dynamic>> contacts = [];

  // List of emergency contacts
  // List<Map<String, String>> contacts = [
  //   {'name': 'Women helpline', 'phone': '181'},
  //   {'name': 'Police', 'phone': '100'},
  //   {'name': 'Ambulance', 'phone': '108'},
  //   {'name': 'Fire Brigade', 'phone': '101'},
  // ];

  @override
  void initState() {
    super.initState();
    _fetchContactsForUser();
  }


  Future<void> _fetchContactsForUser() async {
    try {
      String? userEmail = _auth.currentUser?.email;

      // Define default contacts
      final List<Map<String, dynamic>> defaultContacts = [
        {'name': 'Women helpline', 'phone': '181', 'email': 'No email'},
        {'name': 'Police', 'phone': '100', 'email': 'No email'},
        {'name': 'Ambulance', 'phone': '108', 'email': 'No email'},
        {'name': 'Fire Brigade', 'phone': '101', 'email': 'No email'},
      ];

      if (userEmail != null) {
        // Fetch contacts for the logged-in user
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('contacts')
            .get(); // Fetch all contacts

        List<Map<String, dynamic>> fetchedContacts = querySnapshot.docs.map((doc) {
          String email = doc['email'] ?? '';
          // Include the document only if the email matches the user's email or is an empty string
          if (email == userEmail || email.isEmpty) {
            return {
              'name': doc['name'] ?? 'Unknown',
              'phone': doc['phone'] ?? 'No phone number',
              'email': email.isEmpty ? 'No email' : email,
            };
          } else {
            return null; // Filter out contacts that don't match
          }
        }).where((contact) => contact != null).toList().cast<Map<String, dynamic>>();

        // Check if the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            contacts = fetchedContacts;
          });
        }
      } else {
        // If no user is logged in, display default contacts
        if (mounted) {
          setState(() {
            contacts = defaultContacts;
          });
        }
      }
    } catch (e) {
      print('Error fetching contacts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch contacts')),
        );
      }
    }
  }



  Future<void> addContact(String name,String phone) async {
    // Get the current signed-in user
    User? user = FirebaseAuth.instance.currentUser;

    // Check if the user is signed in
    if (user != null) {
      String email = user.email ?? ''; // Get the user's email, default to empty string if null

      // Add the contact to Firestore with the signed-in user's email
      await FirebaseFirestore.instance.collection('contacts').add({
        'name': name,
        'phone': phone,
        'email': email, // Add the signed-in user's email
      });
    } else {
      print("No user is signed in.");
      // Handle the case where no user is signed in, perhaps by prompting login
    }
  }

  Future<void> deleteContact(String phone) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String email = user.email ?? '';
      try {
        CollectionReference contactsRef = FirebaseFirestore.instance.collection('contacts');
        QuerySnapshot snapshot = await contactsRef
            .where('phone', isEqualTo: phone)
            .where('email', isEqualTo: email)
            .get();

        if (snapshot.docs.isNotEmpty) {
          for (var doc in snapshot.docs) {
            await doc.reference.delete();
            print("Contact with phone $phone deleted successfully.");
          }
          removeContact(phone);
        } else {
          print("No contact found with phone $phone.");
        }
      } catch (e) {
        print("Error deleting contact: $e");
      }
    } else {
      print("No user is signed in.");
    }
  }

  void removeContact(String phone) {
    setState(() {
      // Find and remove the contact with the given phone number
      contacts.removeWhere((contact) => contact['phone'] == phone);
    });
  }


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

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get current position and move map to that location
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
  }


  void _sendSOS() async {
    _getCurrentLocation();

    const String emergencyMessage = 'Emergency! I need help. This is my current location: ';
    String location = 'https://maps.google.com/?q=$latitude,$longitude';
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: '100', // You can replace this with an emergency number or a contact's number
      queryParameters: <String, String>{
        'body': '$emergencyMessage $location',
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send SOS message')),
      );
    }
    print(latitude);
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
                            addContact(contact.displayName ?? 'Unknown',phone);
                            contacts.add({
                              'name': contact.displayName ?? 'Unknown',
                              'phone': phone,
                            });
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
  Future<void> _logout(BuildContext context) async {
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

  void _showCustomHorizontalMenu(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser; // Check if user is logged in

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft, // Align to the left of the screen
          child: Material(
            color: Colors.transparent,
            child: FractionallySizedBox(
              widthFactor: 0.5, // Take up half the screen width
              heightFactor: 1,  // Full height of the screen
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red[50], // Custom color for the background
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(25.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0), // Add top padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align to the start of the column
                    mainAxisAlignment: MainAxisAlignment.start,   // Items start from the top
                    children: [
                      const Text(
                        "Menu",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (currentUser != null) ...[

                        const SizedBox(height: 20), // Add some space before profile
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.blue),
                          title: const Text('Profile', style: TextStyle(fontSize: 18)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfilePage()),
                            );
                          },
                        ),
                        const Divider(),
                        const SizedBox(height: 20), // Add some space between the options
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Logout', style: TextStyle(fontSize: 18)),
                          onTap: () {
                            _logout(context); // Logout function
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 20),
                        ListTile(
                          leading: const Icon(Icons.login, color: Colors.green),
                          title: const Text('Login', style: TextStyle(fontSize: 18)),
                          onTap: () {
                            Navigator.pushNamed(context, '/login');
                          },
                        ),
                        const Divider(),
                        const SizedBox(height: 20), // Add some space
                        ListTile(
                          leading: const Icon(Icons.app_registration, color: Colors.orange),
                          title: const Text('Register', style: TextStyle(fontSize: 18)),
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0), // Starts from the left side
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;
    // Filter contacts based on search query
    final filteredContacts = contacts
        .where((contact) =>
    contact['name']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
        contact['phone']!.contains(searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Nirbhaya 24X7'),
        // Move the PopupMenuButton to the leading property to place it on the left side
        leading: IconButton(
          icon: const Icon(Icons.menu), // Hamburger icon
          onPressed: () => _showCustomHorizontalMenu(context), // Show the custom menu
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
                          Container(
                            child: Row(


                              children: [
                                Text(contact['phone']!,
                                    style: const TextStyle(color: Colors.black)),

                                contact['email'] != 'No email'
                                    ? IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deleteContact(contact['phone']!), // Pass phone to deleteContact
                                )
                                    : const SizedBox.shrink(), // This hides the button if the condition is false

                              ],
                            ),
                          ),

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
                                  onPressed: () => _messageContact(contact['phone']!),
                                  icon: const Icon(Icons.message),
                                  label: const Text('Message'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                // Conditionally render the IconButton based on whether the contact has an email

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
            ElevatedButton(
              onPressed: _sendSOS,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('SOS'),
            ),

          ],
        ),
      ),
      // Floating action button to add a contact from the phone
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
        onPressed: _addContactFromPhone,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}