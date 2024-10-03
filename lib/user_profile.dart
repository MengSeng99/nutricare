import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _username = 'Guest';
  String _email = 'guest@example.com';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Fetch user profile from Firestore based on current user's UID
  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Retrieve the email from the Firebase Auth user
        final userEmail = user.email ?? 'guest@example.com';

        // Retrieve the user's document from Firestore to get the username
        final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userData.exists && userData.data() != null) {
          setState(() {
            _username = userData['name'] ?? 'Guest';
            _email = userEmail;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _username = 'Guest';
        _email = 'guest@example.com';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircleAvatar(
                      radius: 60.0,
                      backgroundImage: const AssetImage('images/nutritionist.png'), // Placeholder image
                      backgroundColor: Colors.grey[200],
                    ),
                  ),

                  // User Name
                  Text(
                    _username,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Email Address
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _email,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  const Divider(height: 30, thickness: 1),

                  // Profile Options
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: Color.fromARGB(255, 90, 113, 243)),
                    title: const Text("Edit Profile"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to edit profile page
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: Color.fromARGB(255, 90, 113, 243)),
                    title: const Text("Change Password"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to change password page
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined, color: Color.fromARGB(255, 90, 113, 243)),
                    title: const Text("Notification Settings"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to notification settings page
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: Color.fromARGB(255, 90, 113, 243)),
                    title: const Text("Help & Support"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to help and support page
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red), // Logout icon in red color
                    title: const Text("Logout"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Handle logout action and navigate to Login page
                      FirebaseAuth.instance.signOut().then((value) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (Route<dynamic> route) => false,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
