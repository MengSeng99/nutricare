// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutricare/user_profile_management/change_password.dart';
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
          _profilePicUrl = userData.data()?.containsKey('profile_pic') == true ? userData['profile_pic'] : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _username = 'Guest';
          _email = 'guest@example.com';
          _profilePicUrl = null;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Your Profile",
          style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        actions: [
          // Edit Profile Button
          IconButton(
            icon: const Icon(Icons.edit, color: Color.fromARGB(255, 90, 113, 243)),
            onPressed: () async {
              // Navigate to the EditProfileScreen and wait for the result
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );

              // If the result is not null, update the username and profile_pic URL
              if (result != null && result is Map<String, dynamic>) {
                setState(() {
                  _username = result['username'] ?? _username;
                  _profilePicUrl = result['profile_pic'] ?? _profilePicUrl;
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
                            : const AssetImage('images/user_profile/default_profile.png') as ImageProvider, // Placeholder image
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

                    // // Logout Button
                    // Container(
                    //   width: double.infinity,
                    //   margin: const EdgeInsets.symmetric(vertical: 10.0),
                    //   child: OutlinedButton.icon(
                    //     style: OutlinedButton.styleFrom(
                    //       side: const BorderSide(color: Colors.red),
                    //       padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(30),
                    //       ),
                    //     ),
                    //     icon: const Icon(Icons.logout, color: Colors.red),
                    //     label: const Text(
                    //       "Logout",
                    //       style: TextStyle(color: Colors.red, fontSize: 16.0),
                    //     ),
                    //     onPressed: () {
                    //       FirebaseAuth.instance.signOut().then((value) {
                    //         Navigator.pushAndRemoveUntil(
                    //           context,
                    //           MaterialPageRoute(builder: (context) => const LoginPage()),
                    //           (Route<dynamic> route) => false,
                    //         );
                    //         ScaffoldMessenger.of(context).showSnackBar(
                    //           SnackBar(
                    //             content: const Text('Account logged out successfully.'),
                    //             backgroundColor: Colors.green,
                    //           ),
                    //         );
                    //       });
                    //     },
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
    );
  }
}
