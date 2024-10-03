import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutricare/bmi_tracker.dart';
import 'package:nutricare/health_record.dart';
import 'package:nutricare/user_profile.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  // Store the username
  String _username = 'Guest';
  bool _isLoading = true; // To show loading state

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  // Fetch the username from Firestore based on the current user
  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userData.exists && userData.data() != null) {
          setState(() {
            _username = userData['name'] ?? 'Guest';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Handle any errors during the data fetch
      setState(() {
        _username = 'Guest';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back arrow button
        title: const Text(
          'More Services',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Profile Section
                    Row(
                      children: [
                        // User Icon
                        const CircleAvatar(
                          radius: 36, // User icon size
                          backgroundColor: Colors.blueAccent,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 36, // Icon size
                          ),
                        ),
                        const SizedBox(width: 36), // Space between icon and text

                        // Username and View Profile Button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Use the username fetched and stored in _username
                              Text(
                                _username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4), // Space between username and button
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UserProfileScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 90, 113, 243), // Button color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5), // Rounded corners
                                  ),
                                ),
                                child: const Text(
                                  'View Profile',
                                  style: TextStyle(color: Colors.white), // Button text color
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30), // Space between sections

                    // My Health Data Section
                    const Text(
                      'My Health Data',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 10), // Space between title and content

                    // Health Records Box
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HealthRecordScreen()), // Navigate to Health Record screen
                  );
                },
                child: Container(
                  width: double.infinity, // Full width
                  padding: const EdgeInsets.all(16.0), // Padding for the box
                  decoration: BoxDecoration(
                    color: Colors.white, // White background
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2), // Light shadow for depth
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3), // Position of the shadow
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Centered Health Records Image
                      Center(
                        child: Image.asset(
                          'images/health-record.png', // Ensure this image path is correct
                          width: 100, // Smaller size for 1x1 image
                          height: 100, // Smaller size for 1x1 image
                        ),
                      ),
                      const SizedBox(height: 10), // Space between image and title
                      const Text(
                        'Health Records',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color:  Color.fromARGB(255, 90, 113, 243)
                        ),
                      ),
                      const SizedBox(height: 4), // Space between title and subtitle
                      const Text(
                        'Lab Results and more',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30), // Space between sections

              // BMI Tracker Section
              const Text(
                'BMI Tracker',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10), // Space between title and content
              
              // BMI Tracker Box
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BmiTrackerScreen()), // Navigate to BMI Tracker screen
                  );
                },
                child: Container(
                  width: double.infinity, // Full width
                  padding: const EdgeInsets.all(16.0), // Padding for the box
                  decoration: BoxDecoration(
                    color: Colors.white, // White background
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2), // Light shadow for depth
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3), // Position of the shadow
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Replace Icon with the BMI image
                      Image.asset(
                        'images/bmi.png', // Replace with the path to the BMI image
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 16), // Space between image and text
                      // Description of BMI Tracker
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Body Mass Index (BMI)',
                              style: TextStyle(fontSize: 16, color:  Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4), // Space between description lines
                            Text(
                              'Monitor your weight and health effectively.',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

