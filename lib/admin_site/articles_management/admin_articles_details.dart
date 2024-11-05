import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../specialist_management/admin_specialist_details.dart';

class ArticlesDetailsScreen extends StatelessWidget {
  final String articleId;
  final String specialistId; // Added to pass specialist's ID
  final String specialistName;

  const ArticlesDetailsScreen({
    super.key,
    required this.articleId,
    required this.specialistId, // Accepting specialist id
    required this.specialistName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Article Details',
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
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)), // Back button color
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('articles').doc(articleId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error loading article details'));
          }

          final articleData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article Title
                  Text(
                    articleData['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Specialist Name (Clickable)
                  GestureDetector(
                    onTap: () {
                      // Navigate to AdminSpecialistsDetailsScreen and pass specialistId
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminSpecialistsDetailsScreen(specialistId: specialistId),
                        ),
                      );
                    },
                    child: Text(
                      'Dr. $specialistName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 90, 113, 243),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Post Date
                  Text(
                    'Posted on: ${(articleData['postDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  // Article Image
                  articleData['imageUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                          child: Image.network(articleData['imageUrl'], fit: BoxFit.cover),
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    'Subtitle: ${articleData['subtitle'] ?? 'No Subtitle'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 90, 113, 243),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    'Description: ${articleData['description'] ?? 'No Description'}',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  // Content
                  Text(
                    'Content:',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    articleData['content'] ?? 'No Content',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  // Attractive Like Count Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 90, 113, 243),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Likes Collected: ${articleData['likeCount'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}