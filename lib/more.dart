// MoreScreen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutricare/bmi_features/bmi_tracker.dart';
import 'package:nutricare/health_record.dart';
import 'package:nutricare/user_profile.dart';

import 'settings/settings.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _username = 'Guest';
  String? _profilePicUrl; // Variable to store profile picture URL
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userData.exists && userData.data() != null) {
        setState(() {
          _username = userData['name'] ?? 'Guest'; // Use 'Guest' as default if 'name' is null
          _profilePicUrl = userData.data()?.containsKey('profile_pic') == true ? userData['profile_pic'] : null; // Set profilePicUrl if it exists
          _isLoading = false;
        });
      }
    }
  } catch (e) {
    setState(() {
      _username = 'Guest';
      _profilePicUrl = null;
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'More Services',
          style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color.fromARGB(255, 90, 113, 243)),
            onPressed: () {
              // Navigate to the SettingsScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Profile Box
                    Container(
                      padding: const EdgeInsets.all(30.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        // border: Border.all(color: Colors.grey[400]!), 
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // User Icon
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: _profilePicUrl != null
                                ? NetworkImage(_profilePicUrl!)
                                : const AssetImage('images/user_profile/default_profile.png') as ImageProvider,
                            backgroundColor: Colors.grey[200],
                          ),
                          const SizedBox(width: 56),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                ElevatedButton(
                                  onPressed: () async {
                                    final updatedProfileData = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const UserProfileScreen(),
                                      ),
                                    );

                                    if (updatedProfileData != null && updatedProfileData is Map<String, dynamic>) {
                                      setState(() {
                                        _username = updatedProfileData['name'];
                                        _profilePicUrl = updatedProfileData['profile_pic'];
                                      });
                                    } else {
                                      _fetchUserName();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'View Profile',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15), // Space between sections

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
                          MaterialPageRoute(builder: (context) => const HealthRecordScreen()),
                        );
                      },
                      child: Container(
                        width: double.infinity, // Full width
                        padding: const EdgeInsets.all(16.0), // Padding for the box
                        decoration: BoxDecoration(
                          color: Colors.white, // White background
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[400]!), 
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
                                color: Color.fromARGB(255, 90, 113, 243),
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
                    const SizedBox(height: 15), // Space between sections

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
                          MaterialPageRoute(builder: (context) => const BmiTrackerScreen()),
                        );
                      },
                      child: Container(
                        width: double.infinity, // Full width
                        padding: const EdgeInsets.all(16.0), // Padding for the box
                        decoration: BoxDecoration(
                          color: Colors.white, // White background
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[400]!), 
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
                                    style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
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
