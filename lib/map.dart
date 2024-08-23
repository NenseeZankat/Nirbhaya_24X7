import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _selectedLocation; // Stores the location selected by the user
  late GoogleMapController mapController; // Controller to manage map actions
  LatLng _initialPosition = const LatLng(37.7749, -122.4194); // Default to San Francisco

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get the user's current location when the screen loads
  }

  // Fetches the user's current location and updates the map position
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Get current position and move map to that location
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_initialPosition, 14), // Set zoom level to 14
      );
    });
  }

  // When the map is created, save the controller
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Handle map taps to select a location
  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;

      // Animate the camera to the tapped location and zoom in
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(position, 16),
      );
      _initialPosition = LatLng(position.latitude, position.longitude); // Update initial position
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.blue,
        actions: [
          // Show check button if a location is selected, return location on press
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
            ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated, // Initialize map controller
        initialCameraPosition: CameraPosition(
          target: _initialPosition, // Start map at initial position
          zoom: 14, // Set initial zoom level
        ),
        onTap: _onMapTapped, // Handle taps on the map to select location
        markers: _selectedLocation != null // Show a marker at the selected location
            ? {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: _selectedLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        }
            : {},
        myLocationEnabled: true, // Enable user's current location display
        myLocationButtonEnabled: true, // Enable button to center map on user's location
      ),
    );
  }
}
