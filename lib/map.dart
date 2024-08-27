import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share/share.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _selectedLocation; // Stores the location selected by the user
  LatLng? _currentLocation;  // Stores the user's current location
  GoogleMapController? _mapController; // Controller to manage map actions
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
      _showLocationServiceError();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationPermissionError();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationPermissionError();
      return;
    }

    // Get current position and move map to that location
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _initialPosition = _currentLocation!;
    });

    // Animate camera if mapController is available
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_initialPosition, 14), // Set zoom level to 14
    );
  }

  void _showLocationServiceError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text('Please enable location services to use this feature.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLocationPermissionError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Denied'),
          content: const Text('Please grant location permissions to use this feature.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // When the map is created, save the controller
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // Handle map taps to select a location
  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });

    // Animate the camera to the tapped location and zoom in
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 16),
    );
  }

  // Generate deep link for the selected location
  String _generateDeepLink(LatLng location) {
    return 'https://maps.google.com/?q=${location.latitude},${location.longitude}';
  }

  // Share the deep link for either the selected or current location
  void _shareLocation() {
    LatLng? locationToShare = _selectedLocation ?? _currentLocation;

    if (locationToShare != null) {
      String deepLink = _generateDeepLink(locationToShare);
      Share.share('Check out this location: $deepLink');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available to share!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.red,
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
      body: Stack(
        children: [
          GoogleMap(
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
          // Position the FloatingActionButton in a SafeArea at the bottom-right, away from zoom controls
          SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 10), // Adjust padding to avoid overlap
                child: FloatingActionButton(
                  onPressed: _shareLocation,
                  backgroundColor: Colors.red, // Share button to share selected location
                  child: const Icon(Icons.share),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
