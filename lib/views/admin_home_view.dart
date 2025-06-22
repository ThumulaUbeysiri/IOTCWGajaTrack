import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import '../models/elephant.dart';
import '../controllers/auth_controller.dart';

class AdminHomeView extends StatefulWidget {
  @override
  State<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends State<AdminHomeView> {
  final dbRef = FirebaseDatabase.instance.ref();
  List<Elephant> elephants = [];

  @override
  void initState() {
    super.initState();
    _loadElephants();
  }

  Future<void> _loadElephants() async {
    final snap = await dbRef.child('elephants').get();
    List<Elephant> list = [];
    for (var child in snap.children) {
      list.add(Elephant.fromMap(child.key!, Map<String, dynamic>.from(child.value as Map)));
    }
    setState(() => elephants = list);
  }

  void _logout() async {
    await AuthController().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Create Driver Account',
            onPressed: () {
              Navigator.pushNamed(context, '/admin/create_driver');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(6.9271, 79.8612),
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: elephants
                .map((e) => Marker(
              point: LatLng(e.lat, e.lon),
              width: 30,
              height: 30,
              child: const Icon(Icons.pets, color: Colors.brown, size: 30),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
