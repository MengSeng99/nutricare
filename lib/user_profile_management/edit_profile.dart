import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String? _profilePicUrl;
  bool _isLoading = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userData.exists) {
          setState(() {
            _usernameController.text = userData['name'] ?? '';
            _profilePicUrl = userData['profile_pic'];
          });
        }
      }
    } catch (e) {
      // print('Failed to load user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storageRef = FirebaseStorage.instance.ref().child('user_profiles/${user.uid}.jpg');
        await storageRef.putFile(imageFile);
        return await storageRef.getDownloadURL();
      }
    } catch (e) {
      // print('Image upload failed: $e');
    }
    return null;
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Upload the new profile picture if a new image is selected
        if (_image != null) {
          _profilePicUrl = await _uploadImage(_image!);
        }

        // Update the user's profile information in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _usernameController.text,
          'profile_pic': _profilePicUrl,
        });

        // Navigate back to the UserProfileScreen with the updated data
        Navigator.pop(context, {'username': _usernameController.text, 'profile_pic': _profilePicUrl});

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // print('Failed to update profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile', 
        style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile Picture
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 100.0,
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : (_profilePicUrl != null
                                ? NetworkImage(_profilePicUrl!)
                                : const AssetImage('images/user_profile/default_profile.png')) as ImageProvider,
                        child: _image == null && _profilePicUrl == null
                            ? const Icon(Icons.camera_alt, size: 40.0, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Username Text Field
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          "Save",
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                        onPressed: _saveProfile,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
