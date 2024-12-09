import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare/admin_site/settings/admin_earning.dart';
import 'package:nutricare/admin_site/settings/admin_feedback.dart';
import 'package:nutricare/admin_site/settings/admin_specialist_enquiry.dart';
import 'package:nutricare/admin_site/settings/service_map.dart';
import 'package:nutricare/authentication_process/login.dart';

import 'admin_specialist_deactivation.dart';

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
          _buildSettingOption(context, Icons.attach_money_outlined, 'Earning', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminEarningsScreen()));
          }),
          const SizedBox(height: 10),
          _buildSettingOption(context, Icons.feedback_outlined, 'Feedback', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminFeedbackScreen()));
          }),
          const SizedBox(height: 10),
          _buildSettingOption(context, Icons.question_answer_outlined, 'Specialist Enquiry', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSpecialistEnquiriesScreen()));
          }),
          const SizedBox(height: 10),
          _buildSettingOption(context, Icons.report_problem_outlined, 'Deactivation Enquiries', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminEnquiryReviewScreen(
                  ),
                ),
              );
            }),
          const SizedBox(height: 10),
          _buildSettingOption(context, Icons.map_outlined, 'Service Map', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceMapScreen()));
          }),
          const SizedBox(height: 60),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 20),
          _buildLogoutOption(context),
          const SizedBox(height: 20), // Add space above the new button
          // ElevatedButton(
          //  onPressed: () async {
          //   await saveTimeSlotsToFirestore(specialistId);
          //   // Show a snackbar after creating the time slots
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(content: Text('Time slots created successfully!')),
          //   );
          // },
          //   style: ElevatedButton.styleFrom(
          //     foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 90, 113, 243), // Text color
          //     padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0), // Button padding
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(8), // Rounded corners
          //     ),
          //   ),
          //   child: const Text('Create Time Slots'),
          // ),
        ],
      ),
    ),
  );
}

Future<void> saveTimeSlotsToFirestore(String specialistId) async {
    // Define the date range and time slots
    DateTime startDate = DateTime(2024, 12, 2);
    DateTime endDate = DateTime(2024, 12, 31);
    List<String> timeSlots = ["09:00", "10:30", "14:00", "15:30"];

    // Excluded dates: 7, 8, 14, 15, 21, 22, 28, 29
    Set<int> excludedDays = {7, 8, 14, 15, 21, 22, 28, 29};

    // Iterate over each day in the date range
    for (DateTime date = startDate; date.isBefore(endDate.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      // Check if the date is a weekend or in excludedDays
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday || excludedDays.contains(date.day)) {
        continue; // Skip this date
      }

      // Format the date to yyyy-MM-dd
      String dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      // Create a document reference for the specific appointment mode (for example, 'Online')
      var appointmentDocRef = FirebaseFirestore.instance
          .collection('specialists')
          .doc(specialistId)
          .collection('appointments')
          .doc('Physical');

      // Get the existing data
      DocumentSnapshot snapshot = await appointmentDocRef.get();

      // Variable to hold the date slots
      Map<String, dynamic> dateSlots;

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>?;
        dateSlots = data?['date_slots'] != null
            ? Map<String, dynamic>.from(data!['date_slots'])
            : {};
      } else {
        dateSlots = {};
      }

      // Initialize date slots if not present
      if (dateSlots[dateKey] == null) {
        dateSlots[dateKey] = [];
      }

      // Add the time slots for the current date
      for (String time in timeSlots) {
        if (!dateSlots[dateKey]!.contains(time)) {
          dateSlots[dateKey].add(time);
        }
      }

      // Update the Firestore document
      await appointmentDocRef.set({'date_slots': dateSlots}, SetOptions(merge: true));
    }
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