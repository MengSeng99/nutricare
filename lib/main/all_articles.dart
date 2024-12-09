import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'articles.dart'; // Adjust the import based on your file structure

class AllArticlesScreen extends StatefulWidget {
  final String? selectedTag;

  const AllArticlesScreen({this.selectedTag, super.key});

  @override
  _AllArticlesScreenState createState() => _AllArticlesScreenState();
}

class _AllArticlesScreenState extends State<AllArticlesScreen> {
  List<Map<String, dynamic>> _allArticles = [];
  List<String> _tags = ['All']; 
  String? _selectedTag;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllArticles();
    _selectedTag = widget.selectedTag ?? 'All'; // Use the selected tag from constructor
  }

  Future<void> _fetchAllArticles() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('articles').get();
      List<Map<String, dynamic>> articles = [];
      Set<String> uniqueTags = {}; 
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> articleData = doc.data() as Map<String, dynamic>;
        articleData['articleId'] = doc.id; 
        
        if (articleData['tags'] != null) {
          for (var tag in (articleData['tags'] as List)) {
            uniqueTags.add(tag);
          }
        }
        
        articles.add(articleData);
      }

      // Sort articles by post date descending
      articles.sort((a, b) {
        Timestamp dateA = a['postDate'];
        Timestamp dateB = b['postDate'];
        return dateB.compareTo(dateA); 
      });

      setState(() {
        _allArticles = articles;
        _tags = ['All'] + uniqueTags.toList(); 
        _isLoading = false;
      });
    } catch (e) {
       setState(() {
        _isLoading = false; // Set to false even if there's an error
      });
    }
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    String title = article['title'] ?? 'No Title';
    String subtitle = article['subtitle'] ?? '';
    String imageUrl = article['imageUrl'] ?? '';
    Timestamp postDate = article['postDate'] ?? Timestamp.now(); 

    List<dynamic> tags = article['tags'] ?? [];
    List displayedTags = tags.length > 3 ? tags.sublist(0, 3) : tags;
    bool hasMoreTags = tags.length > 3;

    return GestureDetector(
      onTap: () {
        String articleId = article['articleId'] as String; 
        String specialistId = article['specialistId'] as String; 
        
        if (specialistId.isNotEmpty && articleId.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ArticleScreen(
                title: title,
                imageUrl: imageUrl,
                postDate: postDate,
                specialistId: specialistId,
                articleId: articleId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Article data is missing')),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Posted on: ${_formatTimestamp(postDate)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6.0,
                        children: List<Widget>.from(displayedTags.map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 90, 113, 243),
                                  fontSize: 12),
                            ),
                            backgroundColor: Colors.white,
                          );
                        })),
                      ),
                      if (hasMoreTags)
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('More Tags'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: tags.map((tag) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Text(tag,
                                              style: const TextStyle(color: Colors.black)),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text(
                            'See more',
                            style: TextStyle(
                              color: Colors.blue,
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    if (DateTime.now().difference(dateTime).inDays > 0) {
      return DateFormat('dd MMM yyyy').format(dateTime);
    } else {
      return '${DateTime.now().difference(dateTime).inHours}h ago';
    }
  }

  void _filterArticles(String? selectedTag) {
    setState(() {
      _selectedTag = selectedTag;
    });
  }

  Widget _buildArticleList() {
    final articlesToShow = _selectedTag == null || _selectedTag == 'All'
        ? _allArticles
        : _allArticles.where((article) => (article['tags'] as List).contains(_selectedTag)).toList();

    return ListView.builder(
      itemCount: articlesToShow.length,
      itemBuilder: (context, index) {
        return _buildArticleCard(articlesToShow[index]);
      },
    );
  }

  Widget _buildTagFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tags.map((tag) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
            child: ChoiceChip(
              label: Text(tag),
              selected: _selectedTag == tag,
              onSelected: (isSelected) {
                _filterArticles(isSelected ? tag : null);
              },
              selectedColor: const Color.fromARGB(255, 90, 113, 243),
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: _selectedTag == tag
                    ? Colors.white
                    : const Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: const BorderSide(
                  color: Colors.transparent, // Remove the black border
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "All Articles",
          style: const TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 90, 113, 243)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
      ),
    body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Loading indicator
          : Column(
              children: [
                _buildTagFilters(),
                Expanded(
                  child: _buildArticleList(),
                ),
              ],
            ),
    );
  }
}