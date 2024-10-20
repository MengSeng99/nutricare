import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_details.dart'; // Import the details page

class FoodRecipeScreen extends StatefulWidget {
  const FoodRecipeScreen({super.key});

  @override
  _FoodRecipeScreenState createState() => _FoodRecipeScreenState();
}

class _FoodRecipeScreenState extends State<FoodRecipeScreen> {
  String? selectedCategory; // To track the selected category
  TextEditingController searchController = TextEditingController(); // Search text controller
  String searchQuery = ""; // To track search query

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recipes",
          style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
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
                    searchQuery = value.toLowerCase(); // Update search query when input changes
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search any recipe",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 250, 250, 250).withOpacity(0.5),
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
                              searchController.clear(); // Clear the search field
                              searchQuery = ""; // Clear the search query
                            });
                          },
                        )
                      : null,
                ),
                style: const TextStyle(color: Color.fromARGB(255, 74, 60, 137)),
              ),
            ),
            // Fetch categories and build category chips
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching data.'));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No recipes available.'));
                }

                // Extract distinct categories from the recipes
                List<String> categories = _getAvailableCategories(snapshot.data!);

                return Column(
                  children: [
                    // Category Chips Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((category) {
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
                                selectedColor: const Color.fromARGB(255, 90, 113, 243),
                                backgroundColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: selectedCategory == category
                                      ? Colors.white
                                      : const Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100), // Rounded corners
                                  side: BorderSide(
                                    color: selectedCategory == category
                                        ? const Color.fromARGB(255, 90, 113, 243)
                                        : Colors.transparent,
                                    width: 2.0,
                                  ),
                                ),
                                labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                                elevation: selectedCategory == category ? 2 : 1, // Slight elevation when selected
                                pressElevation: 2, // More elevation on press
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    // Show recipes based on selected category and search query
                    _buildRecipeCards(context),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Method to extract unique categories from recipes
  List<String> _getAvailableCategories(QuerySnapshot snapshot) {
    List<String> categories = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('category') && !categories.contains(data['category'])) {
        categories.add(data['category']);
      }
    }
    return categories;
  }

  // Method to build the recipe cards based on the selected category and search query
  Widget _buildRecipeCards(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: selectedCategory != null
          ? FirebaseFirestore.instance
              .collection('recipes')
              .where('category', isEqualTo: selectedCategory)
              .snapshots()
          : FirebaseFirestore.instance.collection('recipes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error fetching recipes.'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No recipes available.'));
        }

        // Filter recipes by search query
        final recipes = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['title'].toString().toLowerCase().contains(searchQuery);
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Display 2 items per row
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

  // Method to build a modern food card with overlay and rounded corners (with real recipe data)
  Widget _buildModernRecipeCard(BuildContext context, Map<String, dynamic> recipe, String recipeId) {
    return GestureDetector(
      onTap: () {
        // Navigate to food details page when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodDetailsScreen(recipeId: recipeId),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 5.0, // Elevation for shadow
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              // Image with rounded corners
              ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.network(
                  recipe['imageUrl'], // Get image URL from Firestore
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
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15.0)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe['title'], // Get title from Firestore
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
                            recipe['category'], // Get category from Firestore
                            style: const TextStyle(color: Colors.white70, fontSize: 14.0),
                          ),
                          // Add time icon and duration
                          Row(
                            children: [
                              const Icon(Icons.timer, size: 14.0, color: Colors.white70),
                              const SizedBox(width: 5.0),
                              Text(
                                "${recipe['cookingTime']} min", // Get duration from Firestore
                                style: const TextStyle(color: Colors.white70, fontSize: 14.0),
                              ),
                            ],
                          ),
                        ],
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
}
