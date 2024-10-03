import 'package:flutter/material.dart';
import 'food_details.dart'; // Import the details page

class FoodRecipeScreen extends StatefulWidget {
  const FoodRecipeScreen({super.key});

  @override
  _FoodRecipeScreenState createState() => _FoodRecipeScreenState();
}

class _FoodRecipeScreenState extends State<FoodRecipeScreen> {
  // Keep track of selected categories
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recipes",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white, // Set the background color to white
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Make your own food, stay healthy!",
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search any recipe",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
            ),
            // Category Chips
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip("Popular", Icons.local_fire_department),
                    _buildCategoryChip("Western", Icons.fastfood),
                    _buildCategoryChip("Drinks", Icons.local_drink),
                    _buildCategoryChip("Local", Icons.ramen_dining),
                    _buildCategoryChip("Dessert", Icons.icecream),
                  ],
                ),
              ),
            ),
            // Recipe Cards
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Popular Recipes",
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 0.8,
              ),
              padding: const EdgeInsets.all(16.0),
              itemCount: 4, // Number of recipes
              itemBuilder: (context, index) {
                return _buildRecipeCard(context, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final bool isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = isSelected ? null : label;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Chip(
          avatar: isSelected ? const Icon(Icons.check, color: Colors.white) : Icon(icon, color: const Color.fromARGB(255, 90, 113, 243)),
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color.fromARGB(255, 90, 113, 243),
              fontSize: 16.0, // Make the font size larger
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: isSelected ? const Color.fromARGB(255, 90, 113, 243) : Colors.white,
          shape: StadiumBorder(
            side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Increase the padding for a bigger chip size
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
        // Navigate to food details page when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FoodDetailsScreen(),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
                child: Image.asset(
                  // 'images/recipe_${index + 1}.jpg', // Placeholder image for each recipe
                  'images/recipe_image.jpg', // Placeholder image
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Recipe Name $index",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Category",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
