import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl package
import 'edit_articles.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  final String title;
  final String subtitle;
  final String description;
  final String content;
  final String imageUrl;
  final DateTime postDate;
  final DateTime? lastUpdate;
  final int likeCount;

  const ArticleDetailScreen({
    super.key,
    required this.articleId,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.content,
    required this.imageUrl,
    required this.postDate,
    required this.likeCount,
    this.lastUpdate,
  });

  @override
  _ArticleDetailScreenState createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late String title;
  late String subtitle;
  late String description;
  late String content;
  late String imageUrl;
  late DateTime? lastUpdate;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    title = widget.title;
    subtitle = widget.subtitle;
    description = widget.description;
    content = widget.content;
    imageUrl = widget.imageUrl;
    lastUpdate = widget.lastUpdate;
    likeCount = widget.likeCount;
  }

  @override
  Widget build(BuildContext context) {
    // Create a DateFormat instance to format DateTimes
    final DateFormat dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Article Details',
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
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        actions: [
          IconButton(
  icon: const Icon(Icons.edit),
  color: const Color.fromARGB(255, 90, 113, 243),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditArticleScreen(
          articleId: widget.articleId,
          title: title,
          subtitle: subtitle,
          description: description,
          content: content,
          imageUrl: imageUrl,
        ),
      ),
    ).then((_) {
      _refreshArticle(); // Call to refresh the article details
    });
  },
),
        ],
      ),
      body: SingleChildScrollView(
        // Wrap contents with this widget
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                  color: Color.fromARGB(255, 221, 222, 226), width: 1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Color.fromARGB(255, 90, 113, 243)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Description:\n$description',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Content:\n$content',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    // Post Date with formatted time
                    Text(
                      'Posted on: ${dateTimeFormat.format(widget.postDate)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    // Last Updated date with formatted time
                    Text(
                      'Last Updated: ${lastUpdate != null ? dateTimeFormat.format(lastUpdate!) : 'Never Updated'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    // Like Count
                    Text('Likes: $likeCount',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Future<void> _refreshArticle() async {
  // Fetch the article data again from your source (e.g., Firestore)
  // This is a placeholder for your data fetching logic
  final updatedArticle = await FirebaseFirestore.instance
      .collection('articles')
      .doc(widget.articleId)
      .get();

  if (updatedArticle.exists) {
    setState(() {
      title = updatedArticle['title'];
      subtitle = updatedArticle['subtitle'];
      description = updatedArticle['description'];
      content = updatedArticle['content'];
      imageUrl = updatedArticle['imageUrl'];
      lastUpdate = (updatedArticle['lastUpdate'] as Timestamp).toDate();
      likeCount = updatedArticle['likeCount'];
    });
  }
}
}
