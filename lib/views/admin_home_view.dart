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

  final LatLng _center = LatLng(6.9271, 79.8612);

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
    const backgroundColor = Color(0xFF1E1E2C);
    const appBarColor = Color(0xFF2A2A40);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text('Admin View', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Create Driver Account',
            onPressed: () {
              Navigator.pushNamed(context, '/admin/create_driver');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Container(
              height: 500,
              decoration: BoxDecoration(
                color: appBarColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.shade400.withOpacity(0.6),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: elephants
                          .map(
                            (e) => Marker(
                          point: LatLng(e.lat, e.lon),
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.pets, color: Colors.black54, size: 30),
                        ),
                      )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Elephant count info box below the map
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black26, Colors.black],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.shade400.withOpacity(0.7),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pets, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Text(
                    '${elephants.length} elephant${elephants.length == 1 ? '' : 's'} on the map',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
