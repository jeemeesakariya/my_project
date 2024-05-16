import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:async'; // Import Timer from dart:async
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variables
  String _location = 'Unknown';
  bool _isGeolocationEnabled = false;
  Duration _timeSpent = Duration.zero; // Time spent within geofenced area
  DateTime? _startTime;

  final double _latitude = 22.2987587;
  final double _longitude = 73.2254654;
  final double _radius = 1000; // in meters
  final String _recipientEmail = 'aryan14502@gmail.com';

  @override
  void initState() {
    super.initState();
    _checkGeolocationEnabled();
    _requestLocationPermission();
  }

  // Check if geolocation is enabled
  Future<void> _checkGeolocationEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Geolocation is disabled, handle it (e.g., show a message)
      print('Geolocation services are disabled.');
    } else {
      _isGeolocationEnabled = true;
      _getCurrentLocation();
    }
  }

  // Request location permission
  Future<void> _requestLocationPermission() async {
    final PermissionStatus permission = await Permission.locationWhenInUse.request();
    if (permission.isGranted) {
      _getCurrentLocation();
    } else if (permission.isDenied) {
      print('Location permission denied.');
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final double distance = _calculateDistance(position.latitude, position.longitude);
      _updateLocation(position.latitude, position.longitude);
      if (distance <= _radius) {
        // User is within the geofenced area, start tracking time
        _startTime = DateTime.now();
        _startTrackingTime();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Calculate distance from geofence center
  double _calculateDistance(double userLatitude, double userLongitude) {
    final double earthRadius = 6371e3; // Earth radius in meters

    // Convert degrees to radians
    final double userLatRad = userLatitude * (math.pi / 180); // Use radians conversion
    final double userLonRad = userLongitude * (math.pi / 180);
    final double geofenceLatRad = _latitude * (math.pi / 180);
    final double geofenceLonRad = _longitude * (math.pi / 180);

    // Calculate the difference in latitudes and longitudes
    final double dLat = geofenceLatRad - userLatRad;
    final double dLon = geofenceLonRad - userLonRad;

    // Haversine formula (source: https://en.wikipedia.org/wiki/Haversine_formula)
    final double a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(userLatRad) * math.cos(geofenceLatRad) * math.pow(math.sin(dLon / 2), 2);
    final double c = 2 * math.asin(math.sqrt(a));

    // Distance in meters
    final double distance = earthRadius * c;

    return distance;
  }

  // Update location display and state
  void _updateLocation(double latitude, double longitude) {
    setState(() {
      _location = 'Lat: $latitude, Lon: $longitude';
    });
  }

  // Start tracking time spent within geofenced area
  void _startTrackingTime() async {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Check if the user is still within the geofence every 5 seconds
      final currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (_isWithinGeofence(currentPosition)) {
        // Update the time spent
        _timeSpent = DateTime.now().difference(_startTime!);
        if (_timeSpent.inMinutes >= 5) {
          // If time spent is more than 5 minutes
          _sendEmail();
        }
        setState(() {});
      } else {
        // User is outside the geofence, stop tracking time
        timer.cancel();
        _timeSpent = Duration.zero; // Reset time spent
        setState(() {});
      }
    });
  }

  // Helper function to check if the user is currently within the geofence
  bool _isWithinGeofence(Position currentPosition) {
    // Calculate the distance to the geofence center
    final distance = _calculateDistance(currentPosition.latitude, currentPosition.longitude);
    return distance <= _radius;
  }

  // Send email
  void _sendEmail() async {
    String username = '210303108104@paruluniversity.ac.in'; // Your email
    String password = 'your_password'; // Your email password

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Your Name') // Your name
      ..recipients.add('aryan14502@gmail.com') // Recipient email
      ..subject = 'User Present' // Email subject
      ..text = 'The user is present in the same location for more than 5 minutes.' ; // Email body

    try {
      await send(message, smtpServer);
      print('Email sent successfully');
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoFencing'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Add functionality for button press here
                print('Button Pressed!');
              },
              child: const Text('Click Me'),
            ),
            Text('Current Location: $_location'),
            Text('Time Spent: ${_timeSpent.inHours.toString()}h ${_timeSpent.inMinutes % 60}m'), // Display time spent
          ],
        ),
      ),
    );
  }
}
