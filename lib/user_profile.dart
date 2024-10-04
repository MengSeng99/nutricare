import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutricare/change_password.dart';
import 'login.dart';
import 'edit_profile.dart'; // Import the EditProfileScreen

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _username = 'Guest';
  String _email = 'guest@example.com';
  String? _profilePicUrl; // Add a variable to store the profile picture URL
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userEmail = user.email ?? 'guest@example.com';
        final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userData.exists && userData.data() != null) {
          setState(() {
            _username = userData['name'] ?? 'Guest';
            _email = userEmail;
            _profilePicUrl = userData['profile_pic']; // Fetch and store the profile picture URL
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _username = 'Guest';
        _email = 'guest@example.com';
        _profilePicUrl = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Edit Profile Button
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              // Navigate to the EditProfileScreen and wait for the result
              final updatedUsername = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );

              // If the result is not null, update the username state
              if (updatedUsername != null && updatedUsername is String) {
                setState(() {
                  _username = updatedUsername;
                });
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture with the fetched profile_pic URL
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircleAvatar(
                        radius: 60.0,
                        backgroundImage: _profilePicUrl != null
                            ? NetworkImage(_profilePicUrl!) // Use the fetched profile picture URL
                            : const AssetImage('') as ImageProvider, // Placeholder image
                        backgroundColor: Colors.grey[200],
                      ),
                    ),

                    // User Name
                    Text(
                      _username,
                      style: const TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 90, 113, 243),
                      ),
                    ),
                    const SizedBox(height: 8.0),

                    // Email Address
                    Text(
                      _email,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Change Password Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.lock_outline, color: Colors.white),
                        label: const Text(
                          "Change Password",
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                          );
                        },
                      ),
                    ),

                    // Logout Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.red, fontSize: 16.0),
                        ),
                        onPressed: () {
                          FirebaseAuth.instance.signOut().then((value) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                              (Route<dynamic> route) => false,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
