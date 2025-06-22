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
  LatLng trainLocation = LatLng(0, 0);
  List<LatLng> elephants = [];
  double radius = 300; // meters

  final dbRef = FirebaseDatabase.instance.ref();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _startTracking();
    _loadElephantData();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _startTracking();
      _loadElephantData();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      trainLocation = LatLng(pos.latitude, pos.longitude);
    });
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

  Color _getAlertColor(LatLng elephant) {
    final distance = Distance().as(LengthUnit.Meter, trainLocation, elephant);
    if (distance < 100) return Colors.red;
    if (distance < 300) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: trainLocation,
          initialZoom: 15,
          // enable gestures, etc
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
                radius: radius,
                color: Colors.blue.withOpacity(0.3),
                useRadiusInMeter: true,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: trainLocation,
                width: 40,
                height: 40,
                child: const Icon(Icons.train, color: Colors.blue, size: 40),
              ),
              ...elephants.map((e) => Marker(
                point: e,
                width: 30,
                height: 30,
                child: Icon(Icons.pets, color: _getAlertColor(e), size: 30),
              )),
            ],
          ),
        ],
      ),
    );
  }
}
