import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealSelectionScreen extends StatefulWidget {
  final String mealType;

  const MealSelectionScreen({super.key, required this.mealType});

  @override
  _MealSelectionScreenState createState() => _MealSelectionScreenState();
}

class _MealSelectionScreenState extends State<MealSelectionScreen> {
  String searchQuery = "";
  List<String> categories = [];
  String? selectedCategory;
  Set<String> favoriteRecipeIds = <String>{}; // To track favorite recipes

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _loadFavoriteRecipes(); // Load favorites on init
  }

  Future<void> _fetchCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('recipes').get();
    Set<String> uniqueCategories = {};

    for (var doc in snapshot.docs) {
      var data = doc.data();
      if (data.containsKey('category')) {
        uniqueCategories.add(data['category']);
      }
    }

    setState(() {
      categories = uniqueCategories.toList();
    });
  }

  Future<void> _loadFavoriteRecipes() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favRecipesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorite_recipes_lists')
          .get();

      setState(() {
        favoriteRecipeIds =
            favRecipesSnapshot.docs.map((doc) => doc.id).toSet();
      });
    }
  }

  Future<void> _toggleFavoriteStatus(String recipeId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRecipesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorite_recipes_lists')
        .doc(recipeId);

    if (favoriteRecipeIds.contains(recipeId)) {
      await favRecipesRef.delete();
      setState(() {
        favoriteRecipeIds.remove(recipeId);
      });
    } else {
      await favRecipesRef.set({});
      setState(() {
        favoriteRecipeIds.add(recipeId);
      });
    }
  }

  void _showRecipeDialog(BuildContext context, String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width *
                0.9, // Set to 90% of screen width
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    // Full-size image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15.0)),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        height: 300,
                        width: double.infinity,
                      ),
                    ),
                    // Close button
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
                            onPressed: () =>
                                Navigator.of(context).pop(), // Close on press
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                // Recipe title
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    color: Color.fromARGB(255, 90, 113, 243),
                  ),
                ),
                const SizedBox(height: 16),
                // Add to Log button
                ElevatedButton(
                  onPressed: () {
                    addToLog(
                        title); // Call your function to handle adding to log
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Add to Log',style: TextStyle(color: Colors.white),),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void addToLog(String title) {
    // Implement your logic for adding to the log here.
    print('$title added to log.'); // Log action (for debugging)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.mealType,
          style: const TextStyle(
            color: Color.fromARGB(255, 90, 113, 243),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 90, 113, 243)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 245, 245, 255)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search any recipe",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 90, 113, 243),
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
              // Category Chips Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Favorites category chip
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ChoiceChip(
                          label: const Text('Favorites'),
                          selected: selectedCategory == 'Favorites',
                          onSelected: (isSelected) {
                            setState(() {
                              if (isSelected) {
                                selectedCategory = 'Favorites';
                                _loadFavoriteRecipes(); // Load favorites when selected
                              } else {
                                selectedCategory = null; // Deselect
                              }
                            });
                          },
                          selectedColor:
                              const Color.fromARGB(255, 90, 113, 243),
                          backgroundColor:
                              Colors.grey[200], // Light gray background
                          labelStyle: TextStyle(
                            color: selectedCategory == 'Favorites'
                                ? Colors.white
                                : const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      // Regular category chips
                      ...categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: selectedCategory == category,
                            onSelected: (isSelected) {
                              setState(() {
                                selectedCategory = isSelected ? category : null;
                              });
                            },
                            selectedColor:
                                const Color.fromARGB(255, 90, 113, 243),
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: selectedCategory == category
                                  ? Colors.white
                                  : const Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Fetch and Display Recipes
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Error fetching recipes.'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No recipes available.'));
                  }

                  // Filter the recipes based on selected category, favorite status, and search query
                  final recipes = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    bool matchesSearchQuery = data['title']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery);
                    bool matchesCategory = selectedCategory == null ||
                        (selectedCategory == 'Favorites'
                            ? favoriteRecipeIds.contains(doc.id)
                            : data['category'] == selectedCategory);

                    return matchesSearchQuery && matchesCategory;
                  }).toList();

                  // Display found recipes
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: recipes.map((recipeDoc) {
                        var recipeData =
                            recipeDoc.data() as Map<String, dynamic>;
                        String recipeId = recipeDoc.id;
                        return _buildRecipeCard(context, recipeData, recipeId);
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(
      BuildContext context, Map<String, dynamic> recipe, String recipeId) {
    bool isFavorite = favoriteRecipeIds.contains(recipeId);

    return GestureDetector(
      onTap: () {
        _showRecipeDialog(context, recipe['title'], recipe['imageUrl']);
      },
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 4.0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image with bookmark button
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.network(
                      recipe['imageUrl'],
                      fit: BoxFit.cover,
                      height: 180,
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.bookmark : Icons.bookmark_border,
                          color: isFavorite
                              ? const Color.fromARGB(255, 90, 113, 243)
                              : Colors.grey,
                        ),
                        onPressed: () {
                          _toggleFavoriteStatus(
                              recipeId); // Toggle favorite status
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  color: Color.fromARGB(255, 90, 113, 243),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nutritional Facts:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              // Nutritional facts retrieval
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .doc(recipeId)
                    .collection('nutritionalFacts')
                    .snapshots(),
                builder: (context, factsSnapshot) {
                  if (factsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Text('Loading nutritional facts...');
                  }

                  if (factsSnapshot.hasError || !factsSnapshot.hasData) {
                    return const Text('Error fetching nutritional facts.');
                  }

                  var nutritionalDocuments = factsSnapshot.data!.docs;
                  if (nutritionalDocuments.isEmpty) {
                    return const Text('No nutritional facts available.');
                  }

                  // Map to hold the values in a predefined order
                  Map<String, String> nutritionalValues = {
                    'Calories': '0',
                    'Proteins': '0',
                    'Carbohydrates': '0',
                    'Fats': '0',
                  };

                  // Populate the map with values from Firestore
                  for (var doc in nutritionalDocuments) {
                    var data = doc.data() as Map<String, dynamic>;
                    nutritionalValues[data['label']] = data['value'].toString();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calories: ${nutritionalValues['Calories']} kcal',
                          style: const TextStyle(fontSize: 14)),
                      Text('Proteins: ${nutritionalValues['Proteins']} g',
                          style: const TextStyle(fontSize: 14)),
                      Text(
                          'Carbohydrates: ${nutritionalValues['Carbohydrates']} g',
                          style: const TextStyle(fontSize: 14)),
                      Text('Fats: ${nutritionalValues['Fats']} g',
                          style: const TextStyle(fontSize: 14)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
