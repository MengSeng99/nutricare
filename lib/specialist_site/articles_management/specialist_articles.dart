import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'articles_details.dart';
import 'create_articles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SpecialistArticlesScreen extends StatelessWidget {
  const SpecialistArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Your Articles',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 90, 113, 243),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: const Color.fromARGB(255, 90, 113, 243),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateArticleScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('articles')
            .where('specialistId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading articles'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No articles found.'));
          }

          // Articles fetched successfully
          final articles = snapshot.data!.docs;

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];

              // Accessing article data safely
              final articleData = article.data() as Map<String, dynamic>?;

              // Setting default values in case fields might be absent
              final title = articleData?['title'] ?? 'No Title';
              final subtitle = articleData?['subtitle'] ?? 'No Subtitle';
              final description = articleData?['description'] ?? 'No Description';
              final content = articleData?['content'] ?? 'No Content';
              final imageUrl = articleData?['imageUrl'] ?? '';
              final postDate = articleData?['postDate'] as Timestamp?;
              final lastUpdate = articleData?['lastUpdate'] as Timestamp?;

              // Check if the likeCount field exists
              final likeCount = articleData?.containsKey('likeCount') == true ? articleData!['likeCount'] : 0;

              // Create DateFormat instance
              final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailScreen(
                        articleId: article.id,
                        title: title,
                        subtitle: subtitle,
                        description: description,
                        content: content,
                        imageUrl: imageUrl,
                        postDate: postDate!.toDate(), // Handle nullable Timestamp safely
                        lastUpdate: lastUpdate?.toDate(), // Handle nullable lastUpdate safely
                        likeCount: likeCount,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                        color: Color.fromARGB(255, 221, 222, 226), width: 1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image displayed at the top of the card
                        imageUrl.isNotEmpty
                            ? Image.network(imageUrl,
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover)
                            : const SizedBox(height: 150),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color.fromARGB(255, 90, 113, 243),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Subtitle
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Posted date with time
                        Text(
                          'Posted on: ${postDate != null ? dateFormat.format(postDate.toDate()) : 'Unknown date and time'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        // Last updated date with time (if it exists)
                        Text(
                          'Last Updated: ${lastUpdate != null ? dateFormat.format(lastUpdate.toDate()) : 'Never Updated'}',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Like Count
                        Text(
                          'Likes Collected: $likeCount',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        // Delete button
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteConfirmationDialog(
                                  context, title, article.id, imageUrl);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

 // Function for showing delete confirmation dialog
void _showDeleteConfirmationDialog(BuildContext context, String? articleTitle, String articleId, String? imageUrl) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Delete Article',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 90, 113, 243),
          ),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black),
            children: [
              const TextSpan(text: 'Are you sure you want to remove the article:\n'),
              TextSpan(
                text: articleTitle ?? "this article",
                style: const TextStyle(
                  color: Color.fromARGB(255, 90, 113, 243),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () async {
              // Delete the image from Firebase Storage
              if (imageUrl != null && imageUrl.isNotEmpty) {
                try {
                  final Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
                  await storageRef.delete();
                } catch (e) {
                  // print('Error deleting image: $e'); // Handle error as needed
                }
              }
              
              // Delete the article from Firestore
              await FirebaseFirestore.instance.collection('articles').doc(articleId).delete();
              Navigator.of(context).pop(); // Close the dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Article removed successfully',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}
}