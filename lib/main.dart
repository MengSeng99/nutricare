import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare/admin_site/admin_dashboard.dart';
import 'package:nutricare/specialist_site/specialist_dashboard.dart';
import 'main/navigation_bar.dart';
import 'main/splashscreen.dart';

// Global key for ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'NutriCare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 90, 113, 243)),
        useMaterial3: true,
      ),
      home: const AuthGate(), // Use AuthGate to handle authentication
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(); // Display splash screen while loading
        }

        if (snapshot.hasData) {
          return snapshot.data!; // Navigate to the appropriate screen
        } else {
          return const SplashScreen(); // User is logged out; navigate to SplashScreen
        }
      },
    );
  }

  Future<Widget> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String email = user.email ?? ''; // Get the user's email

      // Check the email to determine the role
      if (email == 'admin@nutricare.com') {
        return const AdminDashboard(); // Direct to admin dashboard
      } else if (email.endsWith('@nutricare.com')) {
        return const SpecialistDashboard(); // Direct to specialist dashboard
      } else {
        return const MainScreen(); // Regular user screen
      }
    }

    return const SplashScreen(); // User is logged out
  }
}