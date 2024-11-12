import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_create_recipe.dart';
import 'admin_recipe_details.dart';

class AdminRecipeScreen extends StatefulWidget {
  const AdminRecipeScreen({super.key});

  @override
  _AdminRecipeScreenState createState() => _AdminRecipeScreenState();
}

class _AdminRecipeScreenState extends State<AdminRecipeScreen> {
  String? selectedCategory; // To track the selected category
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    selectedCategory = 'All'; // Set default selected category to 'All'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Food Recipes',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243))),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: Color.fromARGB(255, 90, 113, 243),
            onPressed: () {
              // Navigate to the Create Recipe screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateRecipeScreen(),
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
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
                    searchQuery = value.toLowerCase();
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
                              searchController.clear();
                              searchQuery = "";
                            });
                          },
                        )
                      : null,
                ),
                style: const TextStyle(color: Colors.black),
              ),
            ),
            // Fetch categories and build category chips
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

                List<String> categories =
                    _getAvailableCategories(snapshot.data!);

                return Column(
                  children: [
                    // Category Chips Row
// Category Chips Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // 'All' Category Chip
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: ChoiceChip(
                                label: const Text('All'),
                                selected: selectedCategory == 'All',
                                onSelected: (isSelected) {
                                  setState(() {
                                    selectedCategory =
                                        isSelected ? 'All' : null;
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
                                  borderRadius: BorderRadius.circular(
                                      100), // Fully rounded corners
                                  side: BorderSide(
                                    color: selectedCategory == 'All'
                                        ? const Color.fromARGB(
                                            255, 90, 113, 243)
                                        : Colors.transparent,
                                    width: 2.0,
                                  ),
                                ),
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                elevation: selectedCategory == 'All'
                                    ? 2
                                    : 1, // Elevated when selected
                              ),
                            ),
                            // Dynamically display selected category chip if one is selected
                            if (selectedCategory != null &&
                                selectedCategory != 'All')
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: ChoiceChip(
                                  label: Text(selectedCategory!),
                                  selected: true,
                                  onSelected: (_) {
                                    setState(() {
                                      selectedCategory =
                                          'All'; // Change to All if selected
                                    });
                                  },
                                  selectedColor:
                                      const Color.fromARGB(255, 90, 113, 243),
                                  backgroundColor: Colors.grey[200],
                                  labelStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        100), // Fully rounded corners
                                  ),
                                ),
                              ),
                            // Display other category chips
                            ...categories
                                .where(
                                    (category) => category != selectedCategory)
                                .map((category) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: ChoiceChip(
                                  label: Text(category),
                                  selected: selectedCategory == category,
                                  onSelected: (isSelected) {
                                    setState(() {
                                      selectedCategory =
                                          isSelected ? category : null;
                                      selectedCategory ??= 'All';
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
                                    borderRadius: BorderRadius.circular(
                                        100), // Fully rounded corners
                                    side: BorderSide(
                                      color: selectedCategory == category
                                          ? const Color.fromARGB(
                                              255, 90, 113, 243)
                                          : Colors.transparent,
                                      width: 2.0,
                                    ),
                                  ),
                                  labelPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          8.0), // Padding around the text
                                  elevation: selectedCategory == category
                                      ? 2
                                      : 1, // Slight elevation when selected
                                  pressElevation: 2, // More elevation on press
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    // Show recipes based on selected category and search query
                    _buildRecipeList(context, snapshot.data!),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getAvailableCategories(QuerySnapshot snapshot) {
    Set<String> categories = {};
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('category')) {
        categories.add(data['category']);
      }
    }
    return categories.toList();
  }

  Widget _buildRecipeList(BuildContext context, QuerySnapshot snapshot) {
    final recipes = snapshot.docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      bool matchesSearchQuery =
          data['title'].toString().toLowerCase().startsWith(searchQuery);
      bool matchesCategory = selectedCategory == null ||
          selectedCategory == 'All' ||
          data['category'] == selectedCategory;
      return matchesSearchQuery && matchesCategory;
    }).toList();

    if (recipes.isEmpty) {
      return const Center(child: Text('No recipes found.'));
    }

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
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminRecipeDetailsScreen(
                    recipeId: recipes[index].id, // Pass the recipe ID
                  ),
                ),
              );
            },
            child: _buildRecipeCard(context, recipe),
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Map<String, dynamic> recipe) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5.0,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.network(
              recipe['imageUrl'],
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(15.0)),
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
                        fontSize: 16.0),
                  ),
                  Text(
                    recipe['category'], // Display the category
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14.0),
                  ),
                  Text(
                    "${recipe['cookingTime']} min",
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
