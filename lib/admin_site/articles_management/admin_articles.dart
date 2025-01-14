// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_articles_details.dart'; // Import the ArticlesDetailsScreen

class AdminArticlesScreen extends StatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  _AdminArticlesScreenState createState() => _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends State<AdminArticlesScreen> {
  String searchKeyword = '';
  List<String> selectedSpecialistIds = [];
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Articles',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243))),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Updated Search Field with Filter Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchKeyword = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search by Title", // New hint text
                      prefixIcon: const Icon(Icons.search), // Search icon
                      filled: true,
                      fillColor: const Color.fromARGB(255, 250, 250, 250)
                          .withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 221, 222, 226),
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 221, 222, 226),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 90, 113, 243),
                          width: 2.0,
                        ),
                      ),
                      suffixIcon: searchKeyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  searchKeyword = '';
                                  searchController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(
                    width:
                        12), // Add some space between the search field and filter button
                InkWell(
                  onTap: _showFilterDialog,
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedSpecialistIds.isNotEmpty
                          ? Color.fromARGB(255, 90, 113, 243).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 6.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: selectedSpecialistIds.isNotEmpty
                                ? Color.fromARGB(255, 90, 113, 243)
                                : Colors.grey,
                          ),
                          const SizedBox(
                              height: 4), // Add space between icon and text
                          Text(
                            'Filter',
                            style: TextStyle(
                              color: selectedSpecialistIds.isNotEmpty
                                  ? Color.fromARGB(255, 90, 113, 243)
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Articles List
          Expanded(
            child: ArticlesListView(
              searchKeyword: searchKeyword,
              selectedSpecialistIds: selectedSpecialistIds,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Filter by Specialists',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 90, 113, 243),
            ),
          ),
          content: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('articles').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No articles found'));
              }

              final articles = snapshot.data!.docs;
              final specialistIds = articles
                  .map((doc) =>
                      (doc.data() as Map<String, dynamic>)['specialistId'])
                  .toSet()
                  .toList(); // Getting unique specialistIds from the articles

              // Now we stream the specialists who have posted articles
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('specialists')
                    .where(FieldPath.documentId, whereIn: specialistIds)
                    .snapshots(),
                builder: (context, specialistSnapshot) {
                  if (specialistSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!specialistSnapshot.hasData ||
                      specialistSnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No specialists found'));
                  }

                  final specialists = specialistSnapshot.data!.docs;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: specialists.map((doc) {
                        final specialistData =
                            doc.data() as Map<String, dynamic>;
                        final specialistId = doc.id;
                        final specialistName =
                            specialistData['name'] ?? 'Unknown Specialist';

                        return RadioListTile<String>(
                          value: specialistId,
                          groupValue: selectedSpecialistIds.isNotEmpty
                              ? selectedSpecialistIds.first
                              : '',
                          title: Text(specialistName),
                          onChanged: (String? value) {
                            setState(() {
                              selectedSpecialistIds =
                                  value != null ? [value] : [];
                              Navigator.of(context).pop(); // Close the dialog
                            });
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSpecialistIds.clear(); // Clear the selections
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Clear Filter'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 90, 113, 243),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class ArticlesListView extends StatelessWidget {
  const ArticlesListView({
    super.key,
    required this.searchKeyword,
    required this.selectedSpecialistIds,
  });

  final String searchKeyword;
  final List<String> selectedSpecialistIds;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('articles')
          .orderBy('postDate', descending: true) // Sort articles by postDate
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No articles found'));
        }

        final articles = snapshot.data!.docs.where((article) {
          final articleData = article.data() as Map<String, dynamic>;
          final title = articleData['title']?.toLowerCase() ?? '';
          final matchesSearch = title.contains(searchKeyword.toLowerCase());
          final matchesSpecialist = selectedSpecialistIds.isEmpty ||
              selectedSpecialistIds.contains(articleData['specialistId']);

          return matchesSearch && matchesSpecialist;
        }).toList();

        // Show message if no articles match the search keyword
        if (articles.isEmpty) {
          return Center(
              child: Text('No articles with the title of "$searchKeyword"'));
        }

        return ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final articleData = articles[index].data() as Map<String, dynamic>;
            final articleId = articles[index].id;
            final title = articleData['title'] ?? 'No Title';
            final imageUrl = articleData['imageUrl'] ?? '';
            final specialistId = articleData['specialistId'];
            final postDate = (articleData['postDate'] as Timestamp).toDate();
            final lastUpdate = articleData.containsKey('lastUpdate') &&
                    articleData['lastUpdate'] != null
                ? (articleData['lastUpdate'] as Timestamp).toDate()
                : null;
            final subtitle = articleData['subtitle'] ?? '';
            final likeCount = articleData['likeCount'] ?? 0; // Add likeCount
            final tags = articleData['tags'] != null
                ? List<String>.from(articleData['tags'])
                : []; // Add tags

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('specialists')
                  .doc(specialistId)
                  .snapshots(),
              builder: (context, specialistSnapshot) {
                if (specialistSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (specialistSnapshot.hasError ||
                    !specialistSnapshot.hasData ||
                    specialistSnapshot.data == null ||
                    !specialistSnapshot.data!.exists) {
                  return const ListTile(
                      title: Text('Error loading specialist'));
                }

                final specialistData =
                    specialistSnapshot.data!.data() as Map<String, dynamic>;
                final specialistName =
                    specialistData['name'] ?? 'Unknown Specialist';

                // Date formatter
                final DateFormat dateTimeFormat =
                    DateFormat('yyyy-MM-dd HH:mm');

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticlesDetailsScreen(
                          articleId: articleId,
                          specialistName: specialistName,
                          specialistId: specialistId,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: Color.fromARGB(255, 221, 222, 226), width: 1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          imageUrl.isNotEmpty
                              ? Image.network(imageUrl,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover)
                              : const SizedBox(height: 150),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color.fromARGB(255, 90, 113, 243),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Dr. $specialistName",
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 90, 113, 243),
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Posted on: ${dateTimeFormat.format(postDate.toLocal())}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (lastUpdate != null)
                            Text(
                              'Last Updated: ${dateTimeFormat.format(lastUpdate.toLocal())}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          const SizedBox(height: 8),
                          // Display Like Count
                          Text(
                            'Likes: $likeCount',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          // Display Tags
                          if (tags.isNotEmpty)
                            Wrap(
                              spacing: 4.0,
                              runSpacing: 4.0,
                              children: tags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  backgroundColor:
                                      Color.fromARGB(255, 90, 113, 243)
                                          .withOpacity(0.1),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmationDialog(
                                    context, title, articleId);
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
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String? articleTitle, String articleId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Delete Article',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 90, 113, 243))),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 16, color: Colors.black), // General text style
              children: [
                const TextSpan(
                    text: 'Are you sure you want to remove the article:\n'),
                TextSpan(
                  text: articleTitle ?? "this article",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 90, 113,
                        243), // Specific color for the article title
                    fontWeight: FontWeight.bold, // Bold for emphasis
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
                // Delete the article from Firestore
                await FirebaseFirestore.instance
                    .collection('articles')
                    .doc(articleId)
                    .delete();
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Article removed successfully',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

