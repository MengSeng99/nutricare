import 'package:flutter/material.dart';

class FoodDetailsScreen extends StatefulWidget {
  const FoodDetailsScreen({super.key});

  @override
  _FoodDetailsScreenState createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  // Track the state of the bookmark
  bool isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recipe Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Bookmark button with feedback
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isBookmarked = !isBookmarked;
              });
              // Show feedback to the user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isBookmarked
                      ? 'Added to Bookmarks'
                      : 'Removed from Bookmarks'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            Container(
              height: 250.0,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/recipe_image.jpg'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Title
                  const Text(
                    "Crepes with Orange and Honey",
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    "Western",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16.0),

                  // Info Cards - Wrapped in a scrollable widget
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // Make the cards scrollable horizontally
                    child: Row(
                      children: [
                        _buildInfoCard("35 mins", Icons.timer),
                        _buildInfoCard("03 Servings", Icons.people),
                        _buildInfoCard("103 Cal", Icons.local_fire_department),
                        _buildInfoCard("Easy", Icons.emoji_emotions),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Ingredients Section
                  const Text(
                    "Ingredients",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    "• 2 Eggs\n"
                    "• 1 Cup All-purpose flour\n"
                    "• 1/2 Cup Whole milk\n"
                    "• 1/2 Cup Water\n"
                    "• 1/4 tsp Salt\n"
                    "• 2 tbsp Butter (melted)\n",
                    style: TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 16.0),

                  // Steps Section
                  const Text(
                    "Steps to Cook",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    "1. In a large mixing bowl, whisk together the eggs, milk, water, and salt.\n"
                    "2. Gradually add in the flour, whisking continuously to avoid lumps.\n"
                    "3. Stir in the melted butter and continue to whisk until the batter is smooth.\n"
                    "4. Heat a non-stick pan over medium heat and lightly grease with butter.\n"
                    "5. Pour about 1/4 cup of batter into the pan and tilt to spread evenly.\n"
                    "6. Cook until the edges begin to lift and the surface is set, about 1-2 minutes.\n"
                    "7. Flip the crepe and cook for another 1-2 minutes until golden brown.\n"
                    "8. Remove from pan and repeat with remaining batter. Serve warm with honey or your choice of toppings.\n",
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for creating info cards
  Widget _buildInfoCard(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0), // Space between cards
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color.fromARGB(255, 225, 225, 225)), // Grey border
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24.0,
            backgroundColor: const Color.fromARGB(255, 90, 113, 243),
            child: Icon(icon, color: Colors.white, size: 28.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }
}
