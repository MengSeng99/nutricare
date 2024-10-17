import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipePage extends StatelessWidget {
  const RecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Firestore Recipe"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            saveSampleRecipeToFirestore();
          },
          child: Text('Save Recipe to Firestore'),
        ),
      ),
    );
  }
}

Future<void> saveSampleRecipeToFirestore() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, dynamic> recipeData = {
    'title': "Mango Smoothie Bowl",
    'category': "Breakfast",
    'cookingTime': 10,
    'servings': 1,
    'difficulty': "Easy",
    'imageUrl': "https://www.nutritiousdeliciousness.com/wp-content/uploads/2023/08/Mango-Smoothie-Bowl1-1.jpg",
    'calories': 250,
  };

  List<Map<String, dynamic>> ingredients = [
    {'name': "1 Cup Frozen Mango"},
    {'name': "1/2 Banana"},
    {'name': "1/2 Cup Coconut Milk"},
    {'name': "1 tbsp Chia Seeds"},
    {'name': "1 tbsp Granola (for topping)"},
    {'name': "1 tbsp Shredded Coconut (for topping)"},
    {'name': "Fresh Berries (for topping)"},
  ];

  List<Map<String, dynamic>> steps = [
    {'number': 1, 'description': "In a blender, combine frozen mango, banana, and coconut milk. Blend until smooth."},
    {'number': 2, 'description': "Pour the smoothie into a bowl."},
    {'number': 3, 'description': "Top with chia seeds, granola, shredded coconut, and fresh berries."},
    {'number': 4, 'description': "Serve immediately and enjoy."},
  ];

  List<Map<String, dynamic>> nutritionalFacts = [
    {'label': "Calories", 'value': 250},
    {'label': "Proteins", 'value': 5},
    {'label': "Carbohydrates", 'value': 45},
    {'label': "Fats", 'value': 8},
  ];

  try {
    DocumentReference recipeRef = await firestore.collection('recipes').add(recipeData);

    for (var ingredient in ingredients) {
      await recipeRef.collection('ingredients').add(ingredient);
    }

    for (var step in steps) {
      await recipeRef.collection('steps').add(step);
    }

    for (var fact in nutritionalFacts) {
      await recipeRef.collection('nutritionalFacts').add(fact);
    }

    print('Recipe added successfully with ID: ${recipeRef.id}');
  } catch (e) {
    print('Error saving recipe: $e');
  }
}
