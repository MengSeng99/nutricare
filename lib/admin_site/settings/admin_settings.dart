import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare/admin_site/settings/admin_feedback.dart';
import 'package:nutricare/authentication_process/login.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color.fromARGB(255, 90, 113, 243),
            fontWeight: FontWeight.bold,
          ),
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
            _buildSettingOption(context, Icons.feedback_outlined, 'Feedback', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminFeedbackScreen()));
              // Replace with actual route when implemented
            }),
            const SizedBox(height: 10),
            _buildSettingOption(context, Icons.question_answer, 'Specialist Enquiry', () {
              // Navigate to Specialist Enquiry Screen (if implemented)
              // Replace with actual route when implemented
            }),
            const SizedBox(height: 60),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 20),
            _buildLogoutOption(context),
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
            const Icon(Icons.logout, color: Colors.red, size: 30), // Log Out Icon
            const SizedBox(width: 16),
            Expanded(
              child: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red), // Red text
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 90, 113, 243),
            )
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
      // Navigate to login after logging out
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false, // This removes all previous routes
      );
      // Optional snack bar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    } catch (e) {
      // Handle error if necessary
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error logging out: ${e.toString()}'),
      ));
    }
  }
}