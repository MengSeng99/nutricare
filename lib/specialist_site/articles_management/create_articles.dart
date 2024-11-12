import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreateArticleScreen extends StatefulWidget {
  const CreateArticleScreen({super.key});

  @override
  _CreateArticleScreenState createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController subtitleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  File? _image; // To hold the selected image
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Article',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243))),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _image == null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: const Center(child: Text('Tap to pick an image'))
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _image!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title TextField
                _buildTextField(titleController, 'Title'),
                const SizedBox(height: 10),

                // Subtitle TextField
                _buildTextField(subtitleController, 'Subtitle'),
                const SizedBox(height: 10),

                // Description TextField
                _buildTextField(descriptionController, 'Description'),
                const SizedBox(height: 10),

                // Content TextField
                _buildTextField(contentController, 'Content', maxLines: 5),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 90, 113, 243),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _saveArticle,
                    child: const 
                    Text('Post Article', 
                    style: TextStyle(fontSize: 18,color: Colors.white,fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveArticle() async {
    // Validate fields
    if (_image == null) {
      _showSnackbar('Please select an image.');
      return;
    }
    
    if (titleController.text.isEmpty) {
      _showSnackbar('Title cannot be empty.');
      return;
    }

    if (subtitleController.text.isEmpty) {
      _showSnackbar('Subtitle cannot be empty.');
      return;
    }

    if (descriptionController.text.isEmpty) {
      _showSnackbar('Description cannot be empty.');
      return;
    }

    if (contentController.text.isEmpty) {
      _showSnackbar('Content cannot be empty.');
      return;
    }

    // Get the user ID from Firebase Auth
    String? specialistId = _auth.currentUser?.uid;

    // Get the image URL from Firebase Storage
    String imageUrl = await _uploadImage();

    // Get current date
    Timestamp postDate = Timestamp.now();

    String title = titleController.text;
    String subtitle = subtitleController.text;
    String description = descriptionController.text;
    String content = contentController.text;

    await FirebaseFirestore.instance.collection('articles').add({
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'content': content,
      'specialistId': specialistId,
      'postDate': postDate,
    });

    // Clear the fields after saving
    titleController.clear();
    subtitleController.clear();
    descriptionController.clear();
    contentController.clear();
    setState(() {
      _image = null;
    });

    // Navigate back or show a success message
    Navigator.pop(context);
  }

  Future<String> _uploadImage() async {
    // Define the path in Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child('articles/${DateTime.now().millisecondsSinceEpoch}.jpg');

    // Upload the image
    UploadTask uploadTask = storageRef.putFile(_image!);
    TaskSnapshot snapshot = await uploadTask;

    // Get the download URL
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }
}