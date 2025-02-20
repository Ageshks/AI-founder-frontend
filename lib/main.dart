import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Position? _currentPosition;
  bool _isTracking = false; // Tracking status
  Stream<Position>? _positionStream;
  late StreamSubscription<Position>? _positionSubscription;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  // Initialize Local Notifications
  void _initializeNotifications() {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = const DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show Notification
  Future<void> _showNotification() async {
    var androidDetails = const AndroidNotificationDetails(
        'channelId', 'AI Camera Alert',
        importance: Importance.max, priority: Priority.high);
    var iOSDetails = const DarwinNotificationDetails();
    var generalNotificationDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await flutterLocalNotificationsPlugin.show(0, 'AI Camera Nearby',
        'You are near an AI Camera!', generalNotificationDetails);
  }

  // Start Tracking Location
  void _startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("GPS is disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print("Location permission is permanently denied.");
        return;
      }
    }

    setState(() {
      _isTracking = true;
    });

    _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 10));

    _positionSubscription = _positionStream!.listen((Position position) {
      setState(() {
        _currentPosition = position;
      });

      _checkNearbyCameras(position.latitude, position.longitude);
    });
  }

  // Stop Tracking Location
  void _stopTracking() {
    _positionSubscription?.cancel();
    setState(() {
      _isTracking = false;
      _currentPosition = null;
    });
  }

  // Call API to Check Nearby Cameras
  Future<void> _checkNearbyCameras(double userLat, double userLon) async {
    const String apiUrl = "http://192.168.1.73:8080/api/cameras/nearby";

    final response =
        await http.get(Uri.parse('$apiUrl?userLat=$userLat&userLon=$userLon'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['nearby'] == true) {
        _showNotification();
      }
    } else {
      print("Error checking nearby cameras: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'AI Camera Radar',
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _currentPosition == null
                  ? const Text(
                      "Press 'Start Tracking' to begin",
                      style: TextStyle(fontSize: 18),
                    )
                  : Text(
                      "Lat: ${_currentPosition!.latitude}, Lon: ${_currentPosition!.longitude}",
                      style: const TextStyle(fontSize: 18),
                    ),
              const SizedBox(height: 20),
              _isTracking
                  ? const Text("Tracking active...",
                      style: TextStyle(color: Colors.green, fontSize: 18))
                  : const Text("Tracking stopped",
                      style: TextStyle(color: Colors.red, fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isTracking ? _stopTracking : _startTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTracking ? Colors.red : Colors.blue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15), // Bigger button
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text(_isTracking ? "Stop Tracking" : "Start Tracking"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
