import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_edit_recipe.dart';

class AdminRecipeDetailsScreen extends StatefulWidget {
  final String recipeId;

  const AdminRecipeDetailsScreen({super.key, required this.recipeId});

  @override
  _AdminRecipeDetailsScreenState createState() => _AdminRecipeDetailsScreenState();
}

class _AdminRecipeDetailsScreenState extends State<AdminRecipeDetailsScreen> {
  late Future<Map<String, dynamic>> _recipeFuture;

  @override
  void initState() {
    super.initState();
    _recipeFuture = _getRecipeData();
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
      final factData = doc.data() as Map<String, dynamic>;
      return {'label': factData['label'], 'value': factData['value']?.toDouble() ?? 0.0};
    }).toList();
  }

  void _editRecipe(Map<String, dynamic> recipe) async {
    final updatedRecipe = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecipeDetailsScreen(
          recipeId: widget.recipeId,
          title: recipe['title'] ?? '',
          category: recipe['category'] ?? '',
          cookingTime: recipe['cookingTime'] ?? 0,
          servings: recipe['servings'] ?? 0,
          calories: recipe['calories'] ?? 0,
          difficulty: recipe['difficulty'] ?? '',
          imageUrl: recipe['imageUrl'] ?? '',
        ),
      ),
    );

    if (updatedRecipe != null) {
      setState(() {
        _recipeFuture = Future.value(updatedRecipe);
      });
    }
  }

  Future<void> _deleteRecipe(String recipeName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Confirm Deletion',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 90, 113, 243)),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black), // General text style
            children: [
             const TextSpan(text: 'Are you sure you want to remove\n'),
              TextSpan(
                text: recipeName,
                style: const TextStyle(
                  color: Color.fromARGB(255, 90, 113, 243), // Specific color for the name
                  fontWeight: FontWeight.bold, // Bold for emphasis
                ),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true), 
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('recipes').doc(widget.recipeId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Recipe deleted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting recipe: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Recipe Details",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 90, 113, 243)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 0.5, color: Color.fromARGB(255, 220, 220, 241)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            color: const Color.fromARGB(255, 90, 113, 243),
            onPressed: () async {
              final recipe = await _recipeFuture; // Fetch current recipe data
              _editRecipe(recipe);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            color:  Colors.red,
            onPressed: () async {
              final recipe = await _recipeFuture; // Fetch current recipe data
              String recipeName = recipe['title'] ?? 'this recipe'; // Use recipe title or a default message
              _deleteRecipe(recipeName);
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _recipeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data found.'));
          }

          final recipe = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Image and Info Card
                  Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Color.fromARGB(255, 221, 222, 226), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              recipe['imageUrl'] ?? '',
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // Recipe Title
                          Text(
                            recipe['title'] ?? 'No Title',
                            style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),

                          // Recipe Category
                          Text('Category: ${recipe['category'] ?? 'Uncategorized'}', style: const TextStyle(fontSize: 16.0)),
                          const SizedBox(height: 8.0),

                          // Recipe Details in a Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _infoCard(Icons.access_time, 'Cooking Time', '${recipe['cookingTime']} mins'),
                              _infoCard(Icons.group, 'Servings', '${recipe['servings']}'),
                              _infoCard(Icons.local_fire_department, 'Calories', '${recipe['calories']} Cal'),
                              _infoCard(Icons.star, 'Difficulty', recipe['difficulty'] ?? 'N/A'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Ingredients Section in a Card
                  _buildExpandableCard(
                    title: "Ingredients",
                    futureBuilder: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getIngredients(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No ingredients found.'),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            var ingredient = snapshot.data![index]['name'] ?? 'Unnamed Ingredient';
                            return ListTile(
                              leading: const Icon(Icons.check_circle, color: Color(0xFF5A71F3)),
                              title: Text(ingredient),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Steps Section in a Card
                  _buildExpandableCard(
                    title: "Steps",
                    futureBuilder: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getSteps(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No steps found.'),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            var step = snapshot.data![index]['description'] ?? 'Unnamed Step';
                            var stepNumber = snapshot.data![index]['number'] ?? 0;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF5A71F3),
                                child: Text('$stepNumber', style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(step),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // Nutritional Facts Section in a Card
                  _buildExpandableCard(
                    title: "Nutritional Facts",
                    futureBuilder: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getNutritionalFacts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No nutritional facts found.'),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            var fact = snapshot.data![index]['label'] ?? 'Unnamed Fact';
                            var value = snapshot.data![index]['value']?.toString() ?? 'N/A';
                            return ListTile(
                              title: Text('$fact: $value g'),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to build expandable cards
  Widget _buildExpandableCard({required String title, required FutureBuilder<List<Map<String, dynamic>>> futureBuilder}) {
    return Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Color.fromARGB(255, 221, 222, 226), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: futureBuilder,
          )
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Card(
         elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Color.fromARGB(255, 221, 222, 226), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF5A71F3),
              child: Icon(icon, color: Colors.white, size: 25),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 18)),
          ],
        ),
    ));
  }
}