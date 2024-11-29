// ignore_for_file: avoid_unnecessary_containers

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FoodDetailsScreen extends StatefulWidget {
  final String recipeId;
  final bool isBookmarked;

  const FoodDetailsScreen({
    super.key,
    required this.recipeId,
    required this.isBookmarked,
  });

  @override
  _FoodDetailsScreenState createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  bool isBookmarked = false;

  // State to hold fetched data
  Map<String, dynamic>? recipe;
  List<Map<String, dynamic>> ingredients = [];
  List<Map<String, dynamic>> steps = [];
  List<Map<String, dynamic>> nutritionalFacts = [];

  // State to track visibility of sections
  bool showIngredients = false;
  bool showSteps = false;
  bool showNutritionalFacts = false;
  bool showYTThumbnail = false; // New state for YouTube thumbnail

  @override
  void initState() {
    super.initState();
    isBookmarked = widget.isBookmarked;
    _fetchData(); // Fetch all data when the screen initializes
  }

  Future<void> _fetchData() async {
    try {
      // Fetch recipe data
      recipe = await _getRecipeData();
      // Fetch ingredients, steps, and nutritional facts
      ingredients = await _getIngredients();
      steps = await _getSteps();
      nutritionalFacts = await _getNutritionalFacts();
    } catch (e) {
      // Handle error appropriately
    }
    setState(() {}); // Refresh the UI after data is fetched
  }

  Future<void> _toggleFavoriteStatus(String recipeId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRecipesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorite_recipes_lists')
        .doc(recipeId);

    DocumentSnapshot docSnapshot = await favRecipesRef.get();

    if (docSnapshot.exists) {
      await favRecipesRef.delete().then((_) {
        setState(() {
          isBookmarked = false;
        });
      });
    } else {
      await favRecipesRef.set({'isBookmarked': true}).then((_) {
        setState(() {
          isBookmarked = true;
        });
      });
    }
  }

  Future<Map<String, dynamic>> _getRecipeData() async {
    try {
      DocumentSnapshot recipeSnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .get();

      return recipeSnapshot.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception("Error fetching recipe data: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _getIngredients() async {
    QuerySnapshot ingredientsSnapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .collection('ingredients')
        .get();

    return ingredientsSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getSteps() async {
    QuerySnapshot stepsSnapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .collection('steps')
        .orderBy('number', descending: false)
        .get();

    return stepsSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getNutritionalFacts() async {
    QuerySnapshot nutritionalFactsSnapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .collection('nutritionalFacts')
        .get();

    return nutritionalFactsSnapshot.docs.map((doc) {
      Map<String, dynamic> factData = doc.data() as Map<String, dynamic>;
      return {
        'label': factData['label'],
        'value': _toDouble(factData['value']),
      };
    }).toList();
  }

  double _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      throw Exception('Unsupported value type');
    }
  }

  // Add this method to build the YouTube thumbnail
  Widget _buildYouTubeThumbnail(String? youtubeLink) {
    if (youtubeLink == null || youtubeLink.isEmpty) {
      return const SizedBox(); // Don't show anything if the link is not valid
    }

    final videoId = YoutubePlayer.convertUrlToId(youtubeLink);
    if (videoId == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Invalid video URL'),
      );
    }

    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';

    return GestureDetector(
      onTap: () {
        launch(youtubeLink); // Open YouTube link
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            thumbnailUrl,
            height: 200, // Set a fixed height
            width: double.infinity, // Make it responsive
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: recipe == null // Check if data is already fetched
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator while data is being fetched
          : Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                image: DecorationImage(
                                  image: NetworkImage(recipe!['imageUrl']),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        child: Image.network(
                                          recipe!['imageUrl'],
                                          fit: BoxFit.fitWidth,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 16,
                                      right: 16,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(255, 34, 42, 92)
                                              .withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
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
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(recipe!['imageUrl']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                DraggableScrollableSheet(
                  initialChildSize: 0.67,
                  minChildSize: 0.5,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 4.0,
                            width: 40.0,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                          ),
                          const SizedBox(height: 0.0),
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              children: [
                                // Recipe Title
                                Text(
                                  recipe!['title'],
                                  style: const TextStyle(
                                    fontSize: 26.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  recipe!['category'],
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 5.0),

                                // Info Cards
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildInfoCard(
                                          "${recipe!['cookingTime']} mins",
                                          Icons.timer),
                                      _buildInfoCard(
                                          "${recipe!['servings']} Servings",
                                          Icons.people),
                                      _buildInfoCard("${recipe!['calories']} Cal",
                                          Icons.local_fire_department),
                                      _buildInfoCard(recipe!['difficulty'],
                                          Icons.emoji_emotions),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5.0),

                                // Ingredients Section
                                _buildCollapsibleSection(
                                  "Ingredients",
                                  showIngredients,
                                  () {
                                    setState(() {
                                      showIngredients = !showIngredients; // toggle the state
                                    });
                                  },
                                  showIngredients
                                      ? Column(
                                          children: ingredients
                                              .map((ingredient) =>
                                                  _buildIngredientItem(ingredient['name']))
                                              .toList(),
                                        )
                                      : null,
                                ),

                                const SizedBox(height: 5.0),

                                // Steps Section
                                _buildCollapsibleSection(
                                  "Steps to Cook",
                                  showSteps,
                                  () {
                                    setState(() {
                                      showSteps = !showSteps; // toggle the state
                                    });
                                  },
                                  showSteps
                                      ? Column(
                                          children: steps
                                              .map((step) => _buildStepCard(
                                                  step['number'],
                                                  step['description']))
                                              .toList(),
                                        )
                                      : null,
                                ),

                                const SizedBox(height: 5.0),

                                // Nutritional Facts Section
                                _buildCollapsibleSection(
                                  "Nutritional Facts (g)",
                                  showNutritionalFacts,
                                  () {
                                    setState(() {
                                      showNutritionalFacts = !showNutritionalFacts; // toggle the state
                                    });
                                  },
                                  showNutritionalFacts
                                      ? Column(
                                          children: nutritionalFacts
                                              .map((fact) =>
                                                  _buildNutritionalFact(fact['label'], fact['value']))
                                              .toList(),
                                        )
                                      : null,
                                ),

                                const SizedBox(height: 5.0),

                                // YouTube Thumbnail Section - Only build if a valid link exists
                                if (recipe?['youtubeLink'] != null && recipe!['youtubeLink'].isNotEmpty)
                                  _buildCollapsibleSection(
                                    "Tutorial Video",
                                    showYTThumbnail,
                                    () {
                                      setState(() {
                                        showYTThumbnail = !showYTThumbnail; // toggle the state
                                      });
                                    },
                                    showYTThumbnail
                                        ? _buildYouTubeThumbnail(recipe!['youtubeLink'])
                                        : null,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Back and Bookmark Buttons
                Positioned(
                  top: 40.0,
                  left: 16.0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(isBookmarked),
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF5A71F3)),
                    ),
                  ),
                ),
                Positioned(
                  top: 40.0,
                  right: 16.0,
                  child: GestureDetector(
                    onTap: () async {
                      await _toggleFavoriteStatus(widget.recipeId);
                      setState(() {});

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBookmarked
                                ? 'Added to Bookmarks'
                                : 'Removed from Bookmarks',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: const Color(0xFF5A71F3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCollapsibleSection(
      String title, bool isExpanded, VoidCallback onTap, Widget? content) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.5)),
          ),
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(title,
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.bold)),
              trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            ),
            if (isExpanded) content ?? const SizedBox(), // Show content only if expanded
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: const Color.fromARGB(255, 218, 218, 218), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF5A71F3),
              radius: 28,
              child: Icon(
                icon,
                color: Color.fromARGB(255, 255, 255, 255),
                size: 28,
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(String ingredient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 2.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: const Color.fromARGB(255, 218, 218, 218), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(
            Icons.check_circle,
            color: Color(0xFF5A71F3),
          ),
          title: Text(
            ingredient,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          contentPadding: const EdgeInsets.only(left: 16.0, top: 4, bottom: 4),
        ),
      ),
    );
  }

  Widget _buildStepCard(int stepNumber, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 2.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: const Color.fromARGB(255, 218, 218, 218), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(0xFF5A71F3),
            child: Text(
              "$stepNumber",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            description,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          contentPadding: const EdgeInsets.only(left: 16.0, top: 4, bottom: 4),
        ),
      ),
    );
  }

  Widget _buildNutritionalFact(String label, double value) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16.0,
        ),
      ),
      trailing: Text(value.toStringAsFixed(2),
          style: const TextStyle(fontSize: 16.0)));
  }
}