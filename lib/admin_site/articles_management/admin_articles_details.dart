import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../specialist_site/articles_management/edit_articles.dart';
import '../specialist_management/admin_specialist_details.dart';

class ArticlesDetailsScreen extends StatefulWidget {
  final String articleId;
  final String specialistId;
  final String specialistName;

  const ArticlesDetailsScreen({
    super.key,
    required this.articleId,
    required this.specialistId,
    required this.specialistName,
  });

  @override
  _ArticlesDetailsScreenState createState() => _ArticlesDetailsScreenState();
}

class _ArticlesDetailsScreenState extends State<ArticlesDetailsScreen> {
  late Map<String, dynamic> articleData; // Local variable to hold article data
  bool isLoading = true; // Loading state indicator

  @override
  void initState() {
    super.initState();
    _fetchArticleDetails(); // Fetch article details on init
  }

  Future<void> _fetchArticleDetails() async {
    setState(() {
      isLoading = true; // Start loading
    });
    
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId)
          .get();

      if (snapshot.exists) {
        articleData = snapshot.data() as Map<String, dynamic>;
      } else {
        articleData = {};
      }
    } catch (e) {
      // Handle error
      articleData = {};
    } finally {
      setState(() {
        isLoading = false; // End loading
      });
    }
  }

  void _navigateToEditArticle(BuildContext context) {
    FirebaseFirestore.instance
        .collection('articles')
        .doc(widget.articleId)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        final articleData = snapshot.data() as Map<String, dynamic>;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditArticleScreen(
              articleId: widget.articleId,
              title: articleData['title'],
              subtitle: articleData['subtitle'],
              description: articleData['description'],
              content: articleData['content'],
              imageUrl: articleData['imageUrl'],
              tags: List<String>.from(articleData['tags'] ?? []),
              youtubeLink: articleData['youtubeLink'],
              onArticleUpdated: _fetchArticleDetails, // Pass the refresh method
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Article Details',
          style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(
            color: Color.fromARGB(255, 90, 113, 243)), // Back button color
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            color: const Color.fromARGB(255, 90, 113, 243),
            onPressed: () {
              _navigateToEditArticle(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminSpecialistsDetailsScreen(
                                  specialistId: widget.specialistId),
                            ),
                          );
                        },
                        child: Text(
                          'Dr. ${widget.specialistName}',
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
                        'Posted on: ${dateTimeFormat.format((articleData['postDate'] as Timestamp).toDate().toLocal())}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (articleData.containsKey('lastUpdate') &&
                          articleData['lastUpdate'] != null)
                        Text(
                          'Last Updated: ${dateTimeFormat.format((articleData['lastUpdate'] as Timestamp).toDate().toLocal())}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 16),
                      // Article Image
                      articleData['imageUrl'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(articleData['imageUrl'],
                                  fit: BoxFit.cover),
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
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        articleData['content'] ?? 'No Content',
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      // Display Tags
                      if (articleData['tags'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tags:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: List<String>.from(articleData['tags']).map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  backgroundColor: Color.fromARGB(255, 90, 113, 243)
                                      .withOpacity(0.1),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      // Attractive Like Count Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 90, 113, 243),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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
                      const SizedBox(height: 16),
                      // YouTube Link Thumbnail
                      if (articleData['youtubeLink'] != null &&
                          articleData['youtubeLink'].isNotEmpty)
                        GestureDetector(
                          onTap: () async {
                            final youtubeLink = articleData['youtubeLink'];
                            if (await canLaunch(youtubeLink)) {
                              await launch(youtubeLink);
                            } else {
                              throw 'Could not launch $youtubeLink';
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Watch on YouTube',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _getYoutubeThumbnail(articleData['youtubeLink']),
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _getYoutubeThumbnail(String? url) {
    if (url == null || url.isEmpty) {
      return ''; // Return an empty string if the link is null
    }
    final RegExp regExp = RegExp(
        r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})');

    final match = regExp.firstMatch(url);
    if (match != null) {
      String videoId = match.group(1)!;
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    }
    return ''; // Return empty string if no match found
  }
}