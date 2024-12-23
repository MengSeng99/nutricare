import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare/admin_site/admin_dashboard.dart';
import 'package:nutricare/specialist_site/specialist_dashboard.dart';
import 'main/navigation_bar.dart';
import 'main/splashscreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Global key for ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  // This will be called when the app is in the background or terminated
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
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

Future<void> requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }
}

void _setupFCMListeners() {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Get the token
  messaging.getToken().then((String? token) {
    print("FCM Token: $token");
    // Store the FCM token if needed, e.g., send it to your server
  });

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received message: ${message.notification?.title}');
    if (message.notification != null) {
      // Show a notification, or handle it as preferred
    }
  });

  // Handle when a user taps on a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message clicked!');
    // Navigate to specific page based on message data
  });
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
          requestNotificationPermissions();
          _setupFCMListeners();
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