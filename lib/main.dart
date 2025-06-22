import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Make sure this file exists

// Views
import 'views/login_view.dart';
import 'views/admin_home_view.dart';
import 'views/admin_create_driver_view.dart';
import 'views/driver_home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const GajaTrackApp());
}

class GajaTrackApp extends StatelessWidget {
  const GajaTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GajaTrack',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginView(),
        '/admin': (context) => AdminHomeView(),
        '/admin/create_driver': (context) => AdminCreateDriverView(),
        '/driver': (context) => DriverHomeView(),
      },
    );
  }
}
