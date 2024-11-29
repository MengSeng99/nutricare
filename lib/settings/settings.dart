import 'package:flutter/material.dart';
import 'package:nutricare/authentication_process/login.dart';
import 'client_info.dart'; // Import the ClientInfoScreen
import 'help.dart';
import 'feedback.dart';
import 'payment_methods.dart'; // Import the HelpScreen
import 'package:firebase_auth/firebase_auth.dart'; // Assuming you're using Firebase Auth

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingOption(context, Icons.person_outlined, 'Personal Details', () {
              // Navigate to ClientInfoScreen
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientInfoScreen()));
            }),
            const SizedBox(height: 10),
            _buildSettingOption(context, Icons.payment, 'Payment Methods', () {
              // Navigate to PaymentMethodsScreen
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()));
            }),
            const SizedBox(height: 10),
            _buildSettingOption(context, Icons.feedback_outlined, 'Feedback', () {
              // Navigate to LanguageScreen
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()));
            }),
            const SizedBox(height: 10),
            _buildSettingOption(context, Icons.help_outline_outlined, 'Help and FAQs', () {
              // Navigate to HelpScreen
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
            }),
            const SizedBox(height: 60),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 20),
            _buildLogoutOption(context), // Add the logout option
          ],
        ),
      ),
    );
  }

  // Widget to build each setting option
  Widget _buildSettingOption(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[400]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color.fromARGB(255, 90, 113, 243), size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

 // Widget to build the logout option
Widget _buildLogoutOption(BuildContext context) {
  return GestureDetector(
    onTap: () {
      // Show confirmation dialog before logging out
      _showLogoutConfirmationDialog(context);
    },
    child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          Icon(Icons.logout, color: Colors.red, size: 30), // Log Out Icon
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Log Out',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red), // Red text
            ),
          ),
        ],
      ),
    ),
  );
}

// Confirmation dialog for logout
void _showLogoutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          "Confirm Logout",
          style: TextStyle(fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 90, 113, 243),) 
        ),
        content: const Text(
          "Are you sure you want to log out?",
          style: TextStyle(fontSize: 14.0),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop(); // Dismiss the dialog
              await _handleLogout(context); // Proceed to logout
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("You have been logged out successfully."),
                duration: Duration(seconds: 1),
              ));
            },
            child: const Text("Yes, Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

// Handle the logout functionality
Future<void> _handleLogout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    // Navigate to login or home screen after logging out
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  } catch (e) {
    // Handle error
    // print("Error logging out: $e");
  }
}
}