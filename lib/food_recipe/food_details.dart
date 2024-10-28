import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  bool showIngredients = false;
  bool showSteps = false;
  bool showNutritionalFacts = false;

  // State to hold fetched data for lazy loading
  List<Map<String, dynamic>>? ingredients;
  List<Map<String, dynamic>>? steps;
  List<Map<String, dynamic>>? nutritionalFacts;

  @override
  void initState() {
    super.initState();
    isBookmarked = widget.isBookmarked; // Initialize the bookmark status
  }

  // Method to toggle favorite status of a recipe
  Future<void> _toggleFavoriteStatus(String recipeId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Ensure the user is authenticated

    final favRecipesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorite_recipes_lists')
        .doc(recipeId);

    // First check if the document exists
    DocumentSnapshot docSnapshot = await favRecipesRef.get();

    if (docSnapshot.exists) {
      // If it exists, remove (unbookmark) the recipe
      await favRecipesRef.delete().then((_) {
        setState(() {
          isBookmarked = false; // Update the local state to reflect the change
        });
      }).catchError((error) {
        // Error handling: you can log it or show a message
        print("Failed to remove bookmark: $error");
      });
    } else {
      // If it does not exist, add the recipe to Firestore
      await favRecipesRef.set({'isBookmarked': true}).then((_) {
        setState(() {
          isBookmarked = true; // Update the local state to reflect the change
        });
      }).catchError((error) {
        // Error handling: you can log it or show a message
        print("Failed to add bookmark: $error");
      });
    }
  }

  // Fetch basic recipe data
  Future<Map<String, dynamic>> _getRecipeData() async {
    try {
      DocumentSnapshot recipeSnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .get();

      return {'recipe': recipeSnapshot.data()};
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
        .orderBy('number', descending: false) // Order the steps by number
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
        'value': _toDouble(factData['value']), // Ensure proper type conversion
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getRecipeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data found.'));
          }

          Map<String, dynamic> recipe = snapshot.data!['recipe'];

          return Stack(
            children: [
              // Image at the top
              Positioned(
                top: 0, // Fix the image at the top of the page
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
                              borderRadius:
                                  BorderRadius.circular(30), // Rounded corners
                              image: DecorationImage(
                                image: NetworkImage(recipe['imageUrl']),
                                fit: BoxFit.contain, // Adjust as needed
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  30), // Ensure the image respects the border radius
                              child: Stack(
                                children: [
                                  // Image background can be set here if needed
                                  // Adding a GestureDetector to detect taps
                                  GestureDetector(
                                    onTap: () => Navigator.of(context)
                                        .pop(), // Closing on tap
                                    child: Container(
                                      child: Image.network(
                                        recipe['imageUrl'],
                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                  ),
                                  // Close button
                                  Positioned(
                                      top: 16,
                                      right: 16,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(255, 34, 42, 92)
                                              .withOpacity(
                                                  0.4),
                                          borderRadius: BorderRadius.circular(
                                              30), 
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                          onPressed: () => Navigator.of(context)
                                              .pop(), // Close on press
                                        ),
                                      )),
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
                        image: NetworkImage(recipe['imageUrl']),
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
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20.0)),
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
                        // Gray bar at the top
                        Container(
                          height: 4.0, // Height of the bar
                          width: 40.0, // Width of the bar
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400, // Gray color
                            borderRadius:
                                BorderRadius.circular(2.0), // Rounded edges
                          ),
                        ),
                        const SizedBox(
                            height: 0.0), // Space between the bar and content
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: [
                              // Recipe Title
                              Text(
                                recipe['title'],
                                style: const TextStyle(
                                  fontSize: 26.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                recipe['category'],
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 5.0),

                              // Info Cards
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildInfoCard(
                                        "${recipe['cookingTime']} mins",
                                        Icons.timer),
                                    _buildInfoCard(
                                        "${recipe['servings']} Servings",
                                        Icons.people),
                                    _buildInfoCard("${recipe['calories']} Cal",
                                        Icons.local_fire_department),
                                    _buildInfoCard(recipe['difficulty'],
                                        Icons.emoji_emotions),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5.0),

                              // Ingredients Section (Lazy Load)
                              _buildCollapsibleSection(
                                "Ingredients",
                                showIngredients,
                                () {
                                  setState(() {
                                    showIngredients = !showIngredients;
                                    if (showIngredients &&
                                        ingredients == null) {
                                      _getIngredients().then((data) {
                                        setState(() {
                                          ingredients = data;
                                        });
                                      });
                                    }
                                  });
                                },
                                showIngredients
                                    ? ingredients == null
                                        ? const CircularProgressIndicator()
                                        : Column(
                                            children: ingredients!
                                                .map((ingredient) =>
                                                    _buildIngredientItem(
                                                        ingredient['name']))
                                                .toList(),
                                          )
                                    : null,
                              ),

                              const SizedBox(height: 5.0),

                              // Steps Section (Lazy Load)
                              _buildCollapsibleSection(
                                "Steps to Cook",
                                showSteps,
                                () {
                                  setState(() {
                                    showSteps = !showSteps;
                                    if (showSteps && steps == null) {
                                      _getSteps().then((data) {
                                        setState(() {
                                          steps = data;
                                        });
                                      });
                                    }
                                  });
                                },
                                showSteps
                                    ? steps == null
                                        ? const CircularProgressIndicator()
                                        : Column(
                                            children: steps!
                                                .map((step) => _buildStepCard(
                                                    step['number'],
                                                    step['description']))
                                                .toList(),
                                          )
                                    : null,
                              ),

                              const SizedBox(height: 5.0),

                              // Nutritional Facts Section (Lazy Load)
                              _buildCollapsibleSection(
                                "Nutritional Facts",
                                showNutritionalFacts,
                                () {
                                  setState(() {
                                    showNutritionalFacts =
                                        !showNutritionalFacts;
                                    if (showNutritionalFacts &&
                                        nutritionalFacts == null) {
                                      _getNutritionalFacts().then((data) {
                                        setState(() {
                                          nutritionalFacts = data;
                                        });
                                      });
                                    }
                                  });
                                },
                                showNutritionalFacts
                                    ? nutritionalFacts == null
                                        ? const CircularProgressIndicator()
                                        : Column(
                                            children: nutritionalFacts!
                                                .map((fact) =>
                                                    _buildNutritionalFact(
                                                        fact['label'],
                                                        fact['value']))
                                                .toList(),
                                          )
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
                    child:
                        const Icon(Icons.arrow_back, color: Color(0xFF5A71F3)),
                  ),
                ),
              ),
              Positioned(
                top: 40.0,
                right: 16.0,
                child: GestureDetector(
                  onTap: () async {
                    await _toggleFavoriteStatus(
                        widget.recipeId); // Call toggle method
                    setState(
                        () {}); // This will force a refresh after the async call.

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
          );
        },
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
              trailing:
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            ),
            if (isExpanded && content != null) content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.all( 12.0),
      elevation: 0, // Remove shadow
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
              radius: 28, // Increased size of the circle
              child: Icon(
                icon,
                color: Color.fromARGB(255, 255, 255, 255),
                size: 28, // Larger icon size
              ),
            ),
            const SizedBox(height: 10.0), // Increased spacing
            Text(
              title,
              style: const TextStyle(
                fontSize: 18.0, // Slightly larger text
                fontWeight: FontWeight.w600, // Semi-bold text
                color: Colors.black87, // Darker text color for contrast
              ),
              textAlign: TextAlign.center, // Centered text
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
        elevation: 0, // Slight shadow for depth
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: const Color.fromARGB(255, 218, 218, 218), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(
            Icons.check_circle, // Icon to indicate inclusion
            color: Color(0xFF5A71F3), // Custom color
          ),
          title: Text(
            ingredient,
            style: const TextStyle(
              fontSize: 16.0, // Larger font size for better readability
              fontWeight: FontWeight.w500, // Medium weight for the text
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
        elevation: 0, // No shadow
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: const Color.fromARGB(255, 218, 218, 218),
              width: 1), // Grey border
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(0xFF5A71F3),
            child: Text(
              "$stepNumber",
              style: const TextStyle(
                color: Colors.white, // Change text color for contrast
                fontWeight: FontWeight.bold, // Bold text for emphasis
              ),
            ), // Custom background color
          ),
          title: Text(
            description,
            style: const TextStyle(
              fontSize: 16.0, // Font size for readability
              fontWeight: FontWeight.w500, // Medium weight for text
            ),
          ),
          contentPadding: const EdgeInsets.only(
              left: 16.0, top: 4, bottom: 4), // Padding for space
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
          style: const TextStyle(fontSize: 16.0)),
    );
  }
}
