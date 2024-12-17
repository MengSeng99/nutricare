import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'all_articles.dart';

class ArticleScreen extends StatefulWidget {
  final String title;
  final String imageUrl;
  final Timestamp postDate;
  final String specialistId;
  final String articleId;
  final Function(bool) onLikeToggle;

  const ArticleScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.postDate,
    required this.specialistId,
    required this.articleId,
    required this.onLikeToggle,
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
  List<String> tags = [];
  String youtubeLink = ''; 
  Timestamp? lastUpdate; 

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
          isLiked = (doc['likedBy'] ?? [])
              .contains(FirebaseAuth.instance.currentUser?.uid);
        });
      }
    // ignore: empty_catches
    } catch (e) {}  
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
              FieldValue.arrayRemove([FirebaseAuth.instance.currentUser?.uid]),
        });
      } else {
        likeCount += 1;
        await articleRef.update({
          'likeCount': likeCount,
          'likedBy':
              FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.uid]),
        });
      }
      setState(() {
        isLiked = !isLiked;
      });

      widget.onLikeToggle(isLiked);
    } catch (e) {}
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
    } catch (e) {}
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
          tags = (doc['tags'] != null)
              ? List<String>.from(doc['tags'].map((tag) => tag.toString()))
              : [];
          youtubeLink =
              (doc.data() as Map<String, dynamic>).containsKey('youtubeLink')
                  ? doc['youtubeLink'] ?? ''
                  : ''; 
          lastUpdate =
              (doc.data() as Map<String, dynamic>).containsKey('lastUpdate')
                  ? doc['lastUpdate'] as Timestamp
                  : null;
        });
      }
    } catch (e) {
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

  String _getYoutubeThumbnail(String videoUrl) {
    final RegExp regex = RegExp(
        r'^(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^&\n]{11})');
    final match = regex.firstMatch(videoUrl);
    if (match != null) {
      String videoId = match.group(1)!;
      return 'https://img.youtube.com/vi/$videoId/0.jpg'; 
    }
    return ''; 
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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

              // Display Tags at the Top
              if (tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: tags.map((tag) {
                      return GestureDetector(
                        onTap: () {
                          // Navigate to AllArticlesScreen and pass the selected tag
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AllArticlesScreen(selectedTag: tag),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Color.fromARGB(255, 90, 113, 243)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 90, 113, 243),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 8),

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

              const SizedBox(height: 8),

              if (lastUpdate != null)
                Text(
                  'Last updated: ${_formatTimestamp(lastUpdate!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                padding: const EdgeInsets.only(bottom: 8.0),
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
                padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                child: Text(
                  content.isNotEmpty ? content : 'No subtitle or content found',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ),

              // Display YouTube Thumbnail if YouTube link is available
              if (youtubeLink.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YouTube Video:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _launchURL(youtubeLink), 
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _getYoutubeThumbnail(youtubeLink),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),

              // Divider below content
              const Divider(color: Colors.grey),

              // Copyright Notice
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
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
            const SizedBox(width: 8),
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