import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final List<String> tags;
  final String? youtubeLink;

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
    required this.tags,
    this.youtubeLink,
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
  late List<String> tags;
  late String? youtubeLink;

  @override
  void initState() {
    super.initState();
    // Initialize the local variables with the passed parameters
    _initializeFields();
  }

  void _initializeFields() {
    title = widget.title;
    subtitle = widget.subtitle;
    description = widget.description;
    content = widget.content;
    imageUrl = widget.imageUrl;
    lastUpdate = widget.lastUpdate;
    likeCount = widget.likeCount;
    tags = widget.tags;
    youtubeLink = widget.youtubeLink;
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
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 90, 113, 243),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
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
                    tags: tags,
                    youtubeLink: youtubeLink,
                    onArticleUpdated: _refreshArticle,
                  ),
                ),
              ).then((updated) {
                if (updated == true) {
                  _refreshArticle(); // Refresh the article details on edit success
                }
              });
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 0.5, color: Color.fromARGB(255, 220, 220, 241)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
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
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Description:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Content:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  // Show Tags
                  Text(
                    'Tags:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Color.fromARGB(255, 90, 113, 243).withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  // Post Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Posted on: ${dateTimeFormat.format(widget.postDate)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text('Likes: $likeCount',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Last Updated
                  Text(
                    lastUpdate != null ? 'Last Updated: ${dateTimeFormat.format(lastUpdate!)}' : 'Never Updated',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  // YouTube Link Thumbnail
                  if (youtubeLink != null && youtubeLink!.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        if (await canLaunch(youtubeLink!)) {
                          await launch(youtubeLink!);
                        } else {
                          throw 'Could not launch $youtubeLink';
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Watch on YouTube",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _getYoutubeThumbnail(youtubeLink!),
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getYoutubeThumbnail(String url) {
    final RegExp regExp = RegExp(
        r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})');

    final match = regExp.firstMatch(url);
    if (match != null) {
      String videoId = match.group(1)!;
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    }
    return '';
  }

  Future<void> _refreshArticle() async {
  final updatedArticle = await FirebaseFirestore.instance
      .collection('articles')
      .doc(widget.articleId)
      .get();

  if (updatedArticle.exists) {
    // Use a safe check for likeCount
    int newLikeCount = updatedArticle.data()?['likeCount'] ?? 0; // Default to 0 if not present

    setState(() {
      title = updatedArticle['title'];
      subtitle = updatedArticle['subtitle'];
      description = updatedArticle['description'];
      content = updatedArticle['content'];
      imageUrl = updatedArticle['imageUrl'];
      lastUpdate = (updatedArticle['lastUpdate'] as Timestamp).toDate();
      likeCount = newLikeCount; // Safely set likeCount
      tags = List<String>.from(updatedArticle['tags'] ?? []);
      youtubeLink = updatedArticle['youtubeLink'];
    });
  }
}
}