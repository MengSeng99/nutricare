import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../specialist_site/client_management/diet_history.dart';

class DietProgressScreen extends StatelessWidget {
  const DietProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user's UID from Firebase
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diet Progress',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 90, 113, 243),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: Center(
        child: userId != null
            ? DietHistoryWidget(clientId: userId) // Embed the widget
            : const Text("You need to be logged in to see the diet history."),
      ),
    );
  }
}