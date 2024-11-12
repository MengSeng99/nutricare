import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MealSelectionScreen extends StatefulWidget {
  final String mealType;
  final DateTime selectedDate; // Add selectedDate here

  const MealSelectionScreen({
    super.key,
    required this.mealType,
    required this.selectedDate, // Make it required in constructor
  });

  @override
  _MealSelectionScreenState createState() => _MealSelectionScreenState();
}

class _MealSelectionScreenState extends State<MealSelectionScreen> {
  String searchQuery = "";
  List<String> categories = [];
  String? selectedCategory = 'All';
  Set<String> favoriteRecipeIds = <String>{};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _loadFavoriteRecipes(); // Load favorites on init
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _showRecipeDialog(
      BuildContext context, String title, String imageUrl, String recipeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('recipes')
              .doc(recipeId)
              .collection('nutritionalFacts')
              .get(), // Get nutritional facts
          builder: (context, factsSnapshot) {
            if (factsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (factsSnapshot.hasError || !factsSnapshot.hasData) {
              return AlertDialog(
                title: Text('Error'),
                content: Text('No nutritional facts available.'),
                actions: [
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            }

            var nutritionalDocuments = factsSnapshot.data!.docs;
            Map<String, String> nutritionalValues = {
              'Calories': '0',
              'Proteins': '0',
              'Carbohydrates': '0',
              'Fats': '0',
            };

            for (var doc in nutritionalDocuments) {
              var data = doc.data() as Map<String, dynamic>;
              nutritionalValues[data['label']] = data['value'].toString();
            }

            int calories = int.parse(nutritionalValues['Calories'] ?? '0');
            int proteins = int.parse(nutritionalValues['Proteins'] ?? '0');
            int carbohydrates =
                int.parse(nutritionalValues['Carbohydrates'] ?? '0');
            int fats = int.parse(nutritionalValues['Fats'] ?? '0');

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
                            fit: BoxFit.contain,
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
                              icon: Icon(Icons.close,
                                  color: Colors.white, size: 30),
                              onPressed: () =>
                                  Navigator.of(context).pop(), // Close on press
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                          title, // Pass the food name
                          calories, // Pass the calories
                          proteins, // Pass the proteins
                          carbohydrates, // Pass the carbohydrates
                          fats, // Pass the fats
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 90, 113, 243),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Add to Log',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void addToLog(
      String title, int calories, int protein, int carbs, int fat) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;
    String mealType =
        widget.mealType; // e.g., "Breakfast", "Lunch", or "Dinner"
    String dateKey = DateFormat('yyyyMMdd').format(widget.selectedDate);

    // Prepare the data to store
    Map<String, dynamic> mealData = {
      'name': title,
      'Calories': calories,
      'Proteins': protein,
      'Carbohydrates': carbs,
      'Fats': fat,
    };

    try {
      // Create or update the corresponding meal type field in the dietHistory document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('dietHistory')
          .doc(dateKey)
          .set({
        // Use set() with merge to avoid overwriting existing fields
        mealType: mealData,
      }, SetOptions(merge: true)); // This merges the new meal type

      // Show a successful message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title added to log!'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        ),
      );

      // Go back to the previous screen and indicate success
      Navigator.pop(context, true); // Pop with a return value of true
    } catch (e) {
      // Handle any errors that may occur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error adding to log.'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      print(e); // Print errors for debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    // You can access selectedDate here
    DateTime currentSelectedDate = widget.selectedDate;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '${widget.mealType} on ${DateFormat('yyyy-MM-dd').format(currentSelectedDate)}', // Format the date
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
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search any recipe",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear(); // Clear the text field
                        setState(() {
                          searchQuery = ""; // Reset the search query
                        });
                      },
                    ),
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
                      // All category chip
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: selectedCategory == 'All',
                          onSelected: (isSelected) {
                            setState(() {
                              selectedCategory = isSelected ? 'All' : null;
                            });
                          },
                          selectedColor:
                              const Color.fromARGB(255, 90, 113, 243),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: selectedCategory == 'All'
                                ? Colors.white
                                : const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                            side: BorderSide(
                              color: selectedCategory == 'All'
                                  ? const Color.fromARGB(255, 90, 113, 243)
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
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
                                selectedCategory =
                                    'All'; // Switch back to All when deselected
                              }
                            });
                          },
                          selectedColor:
                              const Color.fromARGB(255, 90, 113, 243),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: selectedCategory == 'Favorites'
                                ? Colors.white
                                : const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                            side: BorderSide(
                              color: selectedCategory == 'Favorites'
                                  ? const Color.fromARGB(255, 90, 113, 243)
                                  : Colors.transparent,
                              width: 2.0,
                            ),
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
                                selectedCategory = isSelected
                                    ? category
                                    : 'All'; // Deselect to 'All'
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
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(
                                color: selectedCategory == category
                                    ? const Color.fromARGB(255, 90, 113, 243)
                                    : Colors.transparent,
                                width: 2.0,
                              ),
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
                        .startsWith(searchQuery);

                    bool matchesCategory;
                    if (selectedCategory == 'All') {
                      // If 'All' is selected, don't filter by category
                      matchesCategory = true;
                    } else {
                      // Apply category and favorites filtering
                      matchesCategory = (selectedCategory == 'Favorites'
                          ? favoriteRecipeIds.contains(doc.id)
                          : data['category'] == selectedCategory);
                    }

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
        _showRecipeDialog(
            context, recipe['title'], recipe['imageUrl'], recipeId);
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
                      height: MediaQuery.of(context).size.width * 0.5,
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
