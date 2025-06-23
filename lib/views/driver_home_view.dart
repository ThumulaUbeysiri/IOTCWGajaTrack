import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class DriverHomeView extends StatefulWidget {
  @override
  State<DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends State<DriverHomeView> {
  late final MapController _mapController = MapController();

  LatLng trainLocation = LatLng(0, 0);
  List<LatLng> elephants = [];
  double radius = 3000; // meters

  Color _getAlertColor(LatLng elephant) {
    final distance = Distance().as(LengthUnit.Meter, trainLocation, elephant);
    if (distance < 1000) return Colors.redAccent;
    if (distance < 3000) return Colors.orangeAccent;
    return Colors.green;
  }

  final dbRef = FirebaseDatabase.instance.ref();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndStart();
    _loadElephantData();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _startTracking();
      _loadElephantData();
    });
  }

  Future<void> _requestPermissionAndStart() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    _startTracking();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      Position pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 10));

      LatLng newLocation = LatLng(pos.latitude, pos.longitude);

      setState(() {
        trainLocation = newLocation;
      });

      _mapController.move(newLocation, _mapController.camera.zoom);
    } catch (e) {
      print('Error getting location or timeout: $e');
    }
  }

  Future<void> _loadElephantData() async {
    final snap = await dbRef.child('elephants').get();
    List<LatLng> temp = [];
    for (final child in snap.children) {
      final lat = (child.child('lat').value as num).toDouble();
      final lon = (child.child('lon').value as num).toDouble();
      temp.add(LatLng(lat, lon));
    }
    setState(() => elephants = temp);
  }

  double _closestElephantDistance() {
    if (elephants.isEmpty) return double.infinity;

    final dist = elephants
        .map((e) => Distance().as(LengthUnit.Meter, trainLocation, e))
        .reduce((a, b) => a < b ? a : b);
    return dist;
  }

  Map<String, dynamic> _getWarningStatus() {
    final dist = _closestElephantDistance();

    if (dist < 1000) {
      return {
        'text': 'WARNING: Elephant very close!',
        'colors': [Colors.red.shade700, Colors.red.shade400],
        'icon': Icons.warning_amber_rounded,
      };
    } else if (dist < 3000) {
      return {
        'text': 'CAUTION: Elephant nearby',
        'colors': [Colors.deepOrange.shade700, Colors.deepOrange.shade400],
        'icon': Icons.error_outline,
      };
    } else {
      return {
        'text': 'Safe zone: No nearby elephants',
        'colors': [Colors.green.shade700, Colors.green.shade400],
        'icon': Icons.check_circle_outline,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Colors.white;
    final appBarColor = Colors.green.shade600;
    final mapBoxColor = Colors.green.shade50;
    final mapBorderColor = Colors.green.shade300;

    final warning = _getWarningStatus();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text(
          'Driver - GajaTrack',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            color: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            // Map container with border, shadow, rounded corners
            Container(
              height: 500,
              decoration: BoxDecoration(
                color: mapBoxColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: mapBorderColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: mapBorderColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: trainLocation,
                    initialZoom: 15,
                    keepAlive: true,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: trainLocation,
                          radius: 1000,
                          useRadiusInMeter: true,
                          color: Colors.red.withOpacity(0.2),
                          borderStrokeWidth: 1.5,
                          borderColor: Colors.redAccent,
                        ),
                        CircleMarker(
                          point: trainLocation,
                          radius: 3000,
                          useRadiusInMeter: true,
                          color: Colors.orange.withOpacity(0.15),
                          borderStrokeWidth: 1.5,
                          borderColor: Colors.yellow,
                        ),
                        CircleMarker(
                          point: trainLocation,
                          radius: radius,
                          useRadiusInMeter: true,
                          color: Colors.yellow.withOpacity(0.05),
                          borderStrokeWidth: 1.0,
                          borderColor: Colors.yellow,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: trainLocation,
                          width: 45,
                          height: 45,
                          child: Column(
                            children: const [
                              Icon(Icons.train, color: Colors.black, size: 40),
                              SizedBox(height: 2),
                            ],
                          ),
                        ),
                        ...elephants.map(
                              (e) => Marker(
                            point: e,
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.pets,
                              color: _getAlertColor(e),
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Warning/Caution message box with radiant background and icon
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: warning['colors'],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: warning['colors'][1].withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(warning['icon'], color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      warning['text'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
