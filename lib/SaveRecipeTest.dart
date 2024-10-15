import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipePage extends StatelessWidget {
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
    'title': "Crepes with Orange and Honey",
    'category': "Western",
    'cookingTime': 35,
    'servings': 3,
    'difficulty': "Easy",
    'imageUrl': "https://firebasestorage.googleapis.com/v0/b/nutricare-2bb9e.appspot.com/o/recipe_images%2Fpinch-of-yum-workshop-19.jpg?alt=media&token=0ccc4038-1cfa-4fd4-9cc9-46e6ea483854",
    'calories': 103,
  };

  List<Map<String, dynamic>> ingredients = [
    {'name': "2 Eggs"},
    {'name': "1 Cup All-purpose flour"},
    {'name': "1/2 Cup Whole milk"},
    {'name': "1/2 Cup Water"},
    {'name': "1/4 tsp Salt"},
    {'name': "2 tbsp Butter (melted)"},
  ];

  List<Map<String, dynamic>> steps = [
    {'number': 1, 'description': "Whisk together the eggs, milk, water, and salt."},
    {'number': 2, 'description': "Gradually add in the flour."},
    {'number': 3, 'description': "Stir in melted butter."},
  ];

  List<Map<String, dynamic>> nutritionalFacts = [
    {'label': "Calories", 'value': 103},
    {'label': "Proteins", 'value': 5},
    {'label': "Carbohydrates", 'value': 10},
    {'label': "Fats", 'value': 3},
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
