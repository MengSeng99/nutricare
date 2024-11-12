import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ArticleScreen extends StatefulWidget {
  final String title;
  final String imageUrl;
  final Timestamp postDate;
  final String specialistId;
  final String articleId;

  const ArticleScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.postDate,
    required this.specialistId,
    required this.articleId,
  });

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  String specialistName = 'Loading...';
  String specialistProfileUrl = '';
  int likeCount = 0;
  bool isLiked = false;
  String subtitle = '';
  String content = '';

  @override
  void initState() {
    super.initState();
    _fetchSpecialistInfo();
    _fetchLikeCount();
    _fetchArticleContent();
  }

  Future<void> _fetchLikeCount() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId)
          .get();
      if (doc.exists) {
        setState(() {
          likeCount = doc['likeCount'] ?? 0;
          isLiked = (doc['likedBy'] ?? []).contains(FirebaseAuth
              .instance.currentUser?.uid); // Check if liked by current user
        });
      }
    } catch (e) {
      print("Error fetching like count: $e");
    }
  }

  Future<void> _toggleLike() async {
    try {
      DocumentReference articleRef = FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId);

      if (isLiked) {
        likeCount -= 1;
        await articleRef.update({
          'likeCount': likeCount,
          'likedBy':
              FieldValue.arrayRemove([FirebaseAuth.instance.currentUser?.uid])
        });
      } else {
        likeCount += 1;
        await articleRef.update({
          'likeCount': likeCount,
          'likedBy':
              FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.uid])
        });
      }
      setState(() {
        isLiked = !isLiked;
      });
    } catch (e) {
      print("Error updating like count: $e");
    }
  }

  Future<void> _fetchSpecialistInfo() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('specialists')
          .doc(widget.specialistId)
          .get();
      if (doc.exists) {
        setState(() {
          specialistName = doc['name'] ?? 'Unknown Specialist';
          specialistProfileUrl = doc['profile_picture_url'] ?? '';
        });
      }
    } catch (e) {
      print("Error fetching specialist info: $e");
    }
  }

  Future<void> _fetchArticleContent() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId)
          .get();
      if (doc.exists) {
        setState(() {
          subtitle = doc['subtitle'] ?? 'No subtitle found';
          content = doc['content'] ?? 'No content found';
        });
      } else {
        setState(() {
          subtitle = 'No subtitle or content found';
          content = '';
        });
      }
    } catch (e) {
      print("Error fetching article content: $e");
      setState(() {
        subtitle = 'Error fetching subtitle or content';
        content = '';
      });
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    Duration diff = DateTime.now().difference(dateTime);

    if (diff.inDays > 0) {
      return DateFormat('dd MMM yyyy \'at\' hh:mm a').format(dateTime);
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    bool isImageUrlValid = (widget.imageUrl.isNotEmpty &&
        (widget.imageUrl.startsWith('http://') ||
            widget.imageUrl.startsWith('https://')));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 90, 113, 243)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article Title
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),

              // Specialist Info and Formatted Timestamp
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: specialistProfileUrl.isNotEmpty
                        ? NetworkImage(specialistProfileUrl)
                        : null,
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dr. $specialistName',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(widget.postDate),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Article Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: isImageUrlValid
                    ? Image.network(
                        widget.imageUrl,
                        height: MediaQuery.of(context).size.height * 0.5,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Center(child: Text("No Image Available")),
                      ),
              ),

              const SizedBox(height: 16),

              // Article Subtitle
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 8.0), // Padding for subtitle
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Divider below subtitle
              const Divider(color: Colors.grey),

              // Article Content
              Padding(
                padding: const EdgeInsets.only(
                    top: 8.0, bottom: 20.0), // Padding for content
                child: Text(
                  content.isNotEmpty ? content : 'No subtitle or content found',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ),

              // Divider below content
              const Divider(color: Colors.grey),

              // Copyright Notice
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0), // Padding for copyright
                  child: const Text(
                    '© NutriCare',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleLike,
        label: Row(
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              '$likeCount',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.red,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
