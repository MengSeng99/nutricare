import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_details.dart';
import 'more_recipe.dart'; // Import the details page

class FoodRecipeScreen extends StatefulWidget {
  const FoodRecipeScreen({super.key});

  @override
  _FoodRecipeScreenState createState() => _FoodRecipeScreenState();
}

class _FoodRecipeScreenState extends State<FoodRecipeScreen> {
  String? selectedCategory; // To track the selected category
  TextEditingController searchController =
      TextEditingController(); // Search text controller
  String searchQuery = ""; // To track search query
  Set<String> favoriteRecipeIds = <String>{};

  @override
  void initState() {
    super.initState();
    selectedCategory = 'All';
    _loadFavoriteRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text(
    "Recipes",
    style: TextStyle(
        color: Color.fromARGB(255, 90, 113, 243),
        fontWeight: FontWeight.bold),
  ),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          // Navigate to More Recipes Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MoreRecipesScreen(),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_rounded,
                  color: Color.fromARGB(255, 90, 113, 243),
                ),
                SizedBox(width: 8),
                Text(
                  'More Recipes',
                  style: TextStyle(
                    color: Color.fromARGB(255, 90, 113, 243),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ],
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(1),
    child: Divider(
      height: 0.5,
      color: Color.fromARGB(255, 220, 220, 241),
    ),
  ),
  backgroundColor: Colors.white,
  elevation: 0,
  iconTheme:
      const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value
                        .toLowerCase(); // Update search query when input changes
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search any recipe",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor:
                      const Color.fromARGB(255, 250, 250, 250).withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 221, 222, 226),
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 221, 222, 226),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 90, 113, 243),
                      width: 2.0,
                    ),
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              searchController
                                  .clear(); // Clear the search field
                              searchQuery = ""; // Clear the search query
                            });
                          },
                        )
                      : null,
                ),
                style: const TextStyle(color: Color.fromARGB(255, 74, 60, 137)),
              ),
            ),
            // Category Chips Row
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('recipes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching data.'));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No recipes available.'));
                }

                // Extract distinct categories from the recipes
                List<String> categories =
                    _getAvailableCategories(snapshot.data!);

                return Padding(
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
                                selectedCategory ??= 'All';
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
                                selectedCategory =
                                    isSelected ? 'Favorites' : 'All';
                                if (isSelected) {
                                  _loadFavoriteRecipes(); // Load favorites when selected
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
                        // Dynamic category chips
                        ...categories.map((category) {
                          final isSelected = selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (isSelected) {
                                setState(() {
                                  selectedCategory =
                                      isSelected ? category : selectedCategory;
                                });
                              },
                              selectedColor:
                                  const Color.fromARGB(255, 90, 113, 243),
                              backgroundColor: Colors.grey[200],
                              labelStyle: TextStyle(
                                color: isSelected
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
                );
              },
            ),
            // Show recipes based on selected category and search query
            _buildRecipeCards(context),
          ],
        ),
      ),
    );
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

  Future<void> _toggleFavoriteStatus(String recipeId, String recipeTitle) async {
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
    // Show SnackBar for removed recipe
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$recipeTitle removed from favorites'),
        backgroundColor: Colors.red, // Red background for removed
        duration: Duration(seconds: 2),
      ),
    );
  } else {
    await favRecipesRef.set({});
    setState(() {
      favoriteRecipeIds.add(recipeId);
    });
    // Show SnackBar for added recipe
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$recipeTitle added to favorites'),
        backgroundColor: Colors.green, // Green background for added
        duration: Duration(seconds: 2),
      ),
    );
  }
}

  List<String> _getAvailableCategories(QuerySnapshot snapshot) {
    List<String> categories = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('category') &&
          !categories.contains(data['category'])) {
        categories.add(data['category']);
      }
    }
    return categories;
  }

  Widget _buildRecipeCards(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: (selectedCategory == 'All')
          ? FirebaseFirestore.instance.collection('recipes').snapshots()
          : (selectedCategory == 'Favorites' && favoriteRecipeIds.isNotEmpty)
              ? FirebaseFirestore.instance
                  .collection('recipes')
                  .where(FieldPath.documentId,
                      whereIn: favoriteRecipeIds.toList())
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('recipes')
                  .where('category', isEqualTo: selectedCategory)
                  .snapshots(),
      builder: (context, snapshot) {
        // Check connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle snapshot error
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching recipes.'));
        }

        // Check if there's data in the snapshot
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text(
                  "No any recipe found in your favourite list.",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                )
              ]));
        }

        // Extract recipes
        final recipes = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['title'].toString().toLowerCase().startsWith(searchQuery);
        }).toList();

        // Return the grid view of recipes
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.8,
            ),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              var recipe = recipes[index].data() as Map<String, dynamic>;
              return _buildModernRecipeCard(context, recipe, recipes[index].id);
            },
          ),
        );
      },
    );
  }

 Widget _buildModernRecipeCard(
    BuildContext context, Map<String, dynamic> recipe, String recipeId) {
  bool isFavorite = favoriteRecipeIds.contains(recipeId);

  return GestureDetector(
    onTap: () async {
      final updatedBookmarkStatus = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodDetailsScreen(
            recipeId: recipeId,
            isBookmarked: isFavorite,
          ),
        ),
      );

      if (updatedBookmarkStatus != null) {
        setState(() {
          isFavorite = updatedBookmarkStatus;
          if (updatedBookmarkStatus) {
            favoriteRecipeIds.add(recipeId);
          } else {
            favoriteRecipeIds.remove(recipeId);
          }
        });
      }
    },
    child: Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5.0,
      child: Stack(
        children: [
          // Recipe Image
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.network(
              recipe['imageUrl'],
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          // Text overlay with gradient background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(15.0)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        recipe['category'],
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14.0),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.timer,
                              size: 14.0, color: Colors.white70),
                          const SizedBox(width: 5.0),
                          Text(
                            "${recipe['cookingTime']} min",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14.0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bookmark Icon
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? Colors.red
                      : Colors.grey,
                ),
                onPressed: () {
                  _toggleFavoriteStatus(recipeId, recipe['title']); // Pass the recipe title
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
