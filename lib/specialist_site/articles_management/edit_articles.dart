import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditArticleScreen extends StatefulWidget {
  final String articleId; // ID of the article to be edited
  final String title;
  final String subtitle;
  final String description;
  final String content;
  final String imageUrl;

  const EditArticleScreen({
    super.key,
    required this.articleId,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.content,
    required this.imageUrl,
  });

  @override
  _EditArticleScreenState createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController subtitleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  File? _image; // To hold the selected image
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.title;
    subtitleController.text = widget.subtitle;
    descriptionController.text = widget.description;
    contentController.text = widget.content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Article',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243))),
        backgroundColor: Colors.white,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
            bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(
          height: 0.5,
          color: Color.fromARGB(255, 220, 220, 241),
        ),
      ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        ? (widget.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: const Center(
                                    child: Text('Tap to pick an image')),
                              ))
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
                    onPressed: _updateArticle,
                    child: const Text('Update Article',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
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

  Future<void> _updateArticle() async {
    // Validate fields
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

    String imageUrl;
    if (_image != null) {
      // Delete the old image from Firebase Storage
      await _deleteOldImage(widget.imageUrl);
      // Upload the new image to Firebase Storage
      imageUrl = await _uploadImage();
    } else {
      imageUrl = widget.imageUrl; // Keep the existing image URL
    }

    // Get current date
    Timestamp lastUpdate = Timestamp.now(); // New last update timestamp

    // Update article document in Firestore
    await FirebaseFirestore.instance
        .collection('articles')
        .doc(widget.articleId)
        .update({
      'imageUrl': imageUrl,
      'title': titleController.text,
      'subtitle': subtitleController.text,
      'description': descriptionController.text,
      'content': contentController.text,
      'specialistId': specialistId,
      'lastUpdate': lastUpdate, // Save the last update timestamp
    });

    // Create a map to hold the updated data
    Map<String, dynamic> updatedArticle = {
      'imageUrl': imageUrl,
      'title': titleController.text,
      'subtitle': subtitleController.text,
      'description': descriptionController.text,
      'content': contentController.text,
      'specialistId': specialistId,
      'lastUpdate': lastUpdate,
    };

    // Clear the fields after updating
    titleController.clear();
    subtitleController.clear();
    descriptionController.clear();
    contentController.clear();
    setState(() {
      _image = null;
    });

    // Navigate back and pass the updated article
    Navigator.pop(context, updatedArticle); // Pass the updated article data
  }

  Future<String> _uploadImage() async {
    // Define the path in Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('articles/${DateTime.now().millisecondsSinceEpoch}.jpg');

    // Upload the image
    UploadTask uploadTask = storageRef.putFile(_image!);
    TaskSnapshot snapshot = await uploadTask;

    // Get the download URL
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _deleteOldImage(String imageUrl) async {
    // Create a reference to the old image in Firebase Storage
    final imageRef = FirebaseStorage.instance.refFromURL(imageUrl);
    // Delete the old image
    await imageRef.delete();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }
}
