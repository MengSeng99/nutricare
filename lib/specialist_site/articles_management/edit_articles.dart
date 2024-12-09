import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditArticleScreen extends StatefulWidget {
  final VoidCallback onArticleUpdated;
  final String articleId; // ID of the article to be edited
  final String title;
  final String subtitle;
  final String description;
  final String content;
  final String imageUrl;
  final List<String> tags; // Add tags field
  final String? youtubeLink; // Add YouTube link field

  const EditArticleScreen({
    super.key,
    required this.articleId,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.content,
    required this.imageUrl,
    required this.tags, // Initialize with existing tags
    this.youtubeLink, // Initialize with existing YouTube link
    required this.onArticleUpdated,
  });

  @override
  _EditArticleScreenState createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController subtitleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController youtubeLinkController = TextEditingController();
  final TextEditingController tagsController = TextEditingController(); // Controller for tags
  
  File? _image; // To hold the selected image
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Populate the controllers with the current article data
    titleController.text = widget.title;
    subtitleController.text = widget.subtitle;
    descriptionController.text = widget.description;
    contentController.text = widget.content;
    youtubeLinkController.text = widget.youtubeLink ?? '';
    tagsController.text = widget.tags.join(', '); // Join existing tags for easy editing
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
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 0.5, color: Color.fromARGB(255, 220, 220, 241)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color.fromARGB(255, 221, 222, 226), width: 1),
            borderRadius: BorderRadius.circular(15),
          ),
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
                                child: const Center(child: Text('Tap to pick an image')),
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
                _buildTextField(subtitleController, 'Subtitle', maxLines: 2),
                const SizedBox(height: 10),

                // Description TextField
                _buildTextField(descriptionController, 'Description', maxLines: 3),
                const SizedBox(height: 10),

                // Content TextField
                _buildTextField(contentController, 'Content', maxLines: 10),
                const SizedBox(height: 10),

                // YouTube Link TextField
                _buildTextField(youtubeLinkController, 'YouTube Link'),
                const SizedBox(height: 10),

                // Tags TextField
                _buildTextField(tagsController, 'Tags (comma separated)'),
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

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16),
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
    // Check for changes
    if (titleController.text == widget.title &&
        subtitleController.text == widget.subtitle &&
        descriptionController.text == widget.description &&
        contentController.text == widget.content &&
        tagsController.text == widget.tags.join(', ') &&
        _image == null && youtubeLinkController.text == (widget.youtubeLink ?? '')) {
      _showSnackbar('No changes made.');
      return; // Do not update if no changes
    }

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

    // Convert tags from string to list and trim spaces
  List<String> tags = tagsController.text
      .split(',')
      .map((tag) => tag.trim()) // Trim whitespace from each tag
      .where((tag) => tag.isNotEmpty) // Remove empty tags
      .toList();

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
      'tags': tags, // Save the updated tags
      'youtubeLink': youtubeLinkController.text, // Save the YouTube link
      'lastUpdate': lastUpdate, // Save the last update timestamp
    });

    // Clear the fields after updating
    titleController.clear();
    subtitleController.clear();
    descriptionController.clear();
    contentController.clear();
    youtubeLinkController.clear();
    tagsController.clear();
    setState(() {
      _image = null; // Reset the image state
    });
 // After successfully updating the article
    widget.onArticleUpdated(); // Call the provided callback

    // Navigate back
    Navigator.pop(context); // Close the editing screen
    _showSnackbar('Article updated successfully.');
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