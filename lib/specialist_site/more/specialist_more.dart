import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutricare/specialist_site/more/specialist_deactivation.dart';
import 'package:nutricare/specialist_site/more/specialist_earning.dart';
import '../../authentication_process/login.dart';
import '../../food_recipe/food_recipe.dart';
import '../../settings/feedback.dart';
import 'package:nutricare/admin_site/specialist_management/admin_specialist_details.dart';

class SpecialistMoreScreen extends StatelessWidget {
  const SpecialistMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'More Services',
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
            // Adding the Your Profile option
            _buildSettingOption(context, Icons.person, 'Your Profile', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminSpecialistsDetailsScreen(
                    specialistId: currentUserId, 
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            _buildSettingOption(context, Icons.restaurant, 'Food Recipe', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodRecipeScreen()));
            }),
            const SizedBox(height: 10),
            _buildSettingOption(context, Icons.feedback_outlined, 'Feedback', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()));
            }),
            const SizedBox(height: 10),
            _buildSettingOption(context, Icons.attach_money_outlined, 'Earning', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EarningsScreen()));
            }),
            const SizedBox(height: 10),
            // Adding the Deactivation Enquiries option
            _buildSettingOption(context, Icons.report_problem_outlined, 'Deactivation Enquiries', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpecialistDeactivation(
                    specialistId: currentUserId, // Pass current user ID
                  ),
                ),
              );
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
          backgroundColor: Colors.white,
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
      // Handle error if necessary
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error logging out: ${e.toString()}'),
      ));
    }
  }
}