// create_recipe_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  _CreateRecipeScreenState createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _category;
  int? _cookingTime;
  int? _servings;
  int? _calories;
  String? _difficulty;
  File? _imageFile;
  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _stepControllers = [];
  final List<TextEditingController> _nutritionalFactControllers = [];
  final List<TextEditingController> _nutritionalValueControllers = [];
  final List<Map<String, dynamic>> _ingredients = [];
  final List<Map<String, dynamic>> _steps = [];
  final List<Map<String, dynamic>> _nutritionalFacts = [];

  final List<String> _difficultyOptions = ['Easy', 'Medium', 'Hard'];

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile != null) {
      try {
        final storageRef = FirebaseStorage.instance.ref().child('recipe_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_imageFile!);
        String downloadUrl = await storageRef.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        print(e);
        return null;
      }
    }
    return null; // Return null if no image is uploaded
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Save form fields

      String? imageUrl = await _uploadImage();
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image upload failed"),backgroundColor: Colors.red,));
        return;
      }

      // Create the main recipe document
      DocumentReference recipeRef = await FirebaseFirestore.instance.collection('recipes').add({
        'title': _title,
        'category': _category,
        'cookingTime': _cookingTime,
        'servings': _servings,
        'calories': _calories,
        'difficulty': _difficulty,
        'imageUrl': imageUrl,
      });

      // Add ingredients, steps, and nutritional facts into respective subcollections
      await _addSubcollectionItems(recipeRef, 'ingredients', _ingredients, _ingredientControllers);
      await _addSubcollectionItems(recipeRef, 'steps', _steps, _stepControllers);
      await _addSubcollectionItems(recipeRef, 'nutritionalFacts', _nutritionalFacts, _nutritionalFactControllers, _nutritionalValueControllers);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe created successfully!'),backgroundColor: Colors.green,));
      Navigator.pop(context); // Navigate back to previous screen
    }
  }

  Future<void> _addSubcollectionItems(DocumentReference recipeRef, String collectionName,
      List<Map<String, dynamic>> items, List<TextEditingController> controllers, [List<TextEditingController>? valueControllers]) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < items.length; i++) {
      Map<String, dynamic> item = items[i];
      item['name'] = controllers[i].text;
      if (valueControllers != null) {
        item['value'] = int.tryParse(valueControllers[i].text) ?? 0;
      }
      batch.set(recipeRef.collection(collectionName).doc(), item);
    }
    await batch.commit();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add({'name': ''});
      _ingredientControllers.add(TextEditingController(text: ''));
    });
  }

  void _addStep() {
    setState(() {
      int stepNumber = _steps.length + 1;
      _steps.add({'description': '', 'number': stepNumber});
      _stepControllers.add(TextEditingController(text: ''));
    });
  }

  void _addNutritionalFact() {
    setState(() {
      _nutritionalFacts.add({'label': '', 'value': 0});
      _nutritionalFactControllers.add(TextEditingController(text: ''));
      _nutritionalValueControllers.add(TextEditingController(text: ''));
    });
  }

  Widget _buildIngredientInputFields() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _ingredientControllers.length,
      itemBuilder: (context, index) {
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ingredientControllers[index],
                decoration: InputDecoration(labelText: "Ingredient ${index + 1}"),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeIngredient(index),
            ),
          ],
        );
      },
    );
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
      _ingredients.removeAt(index);
    });
  }

  Widget _buildStepInputFields() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _stepControllers.length,
      itemBuilder: (context, index) {
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stepControllers[index],
                decoration: InputDecoration(labelText: "Step ${index + 1}"),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeStep(index),
            ),
          ],
        );
      },
    );
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
      _steps.removeAt(index);
    });
  }

  Widget _buildNutritionalFactInputFields() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _nutritionalFactControllers.length,
      itemBuilder: (context, index) {
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nutritionalFactControllers[index],
                decoration: InputDecoration(labelText: "Nutritional Fact ${index + 1}"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _nutritionalValueControllers[index],
                decoration: InputDecoration(labelText: "Value (g)"),
                keyboardType: TextInputType.number,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeNutritionalFact(index),
            ),
          ],
        );
      },
    );
  }

  void _removeNutritionalFact(int index) {
    setState(() {
      _nutritionalFactControllers[index].dispose();
      _nutritionalFactControllers.removeAt(index);
      _nutritionalValueControllers[index].dispose();
      _nutritionalValueControllers.removeAt(index);
      _nutritionalFacts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Recipe",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 90, 113, 243)),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 0.5, color: Color.fromARGB(255, 220, 220, 241)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Image Upload Section in a Card
                Card(
                  elevation: 4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8.0),
                        image: _imageFile != null
                            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: _imageFile == null
                          ? const Text(
                              'Tap to upload an image',
                              style: TextStyle(color: Colors.black54),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Card for Recipe Details
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Food Recipe Name"),
                          validator: (value) => value!.isEmpty ? 'Please enter a title.' : null,
                          onSaved: (value) => _title = value,
                        ),
                        const SizedBox(height: 16.0),

                        TextFormField(
                          decoration: const InputDecoration(labelText: "Category"),
                          onSaved: (value) => _category = value,
                        ),
                        const SizedBox(height: 16.0),

                        TextFormField(
                          decoration: const InputDecoration(labelText: "Cooking Time (mins)"),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Please enter cooking time.' : null,
                          onSaved: (value) => _cookingTime = int.tryParse(value!),
                        ),
                        const SizedBox(height: 16.0),

                        TextFormField(
                          decoration: const InputDecoration(labelText: "Servings (person)"),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Please enter the number of servings.' : null,
                          onSaved: (value) => _servings = int.tryParse(value!),
                        ),
                        const SizedBox(height: 16.0),

                        TextFormField(
                          decoration: const InputDecoration(labelText: "Calories"),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Please enter calorie count.' : null,
                          onSaved: (value) => _calories = int.tryParse(value!),
                        ),
                        const SizedBox(height: 16.0),

                        DropdownButtonFormField<String>(
                          value: _difficulty,
                          decoration: const InputDecoration(labelText: "Difficulty"),
                          items: _difficultyOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() {
                            _difficulty = value;
                          }),
                          validator: (value) => value == null ? 'Please select a difficulty.' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Ingredients Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text("Ingredients", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 8.0),
                        _buildIngredientInputFields(),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color.fromARGB(255, 90, 113, 243), // Text color
                          ),
                          onPressed: _addIngredient,
                          child: const Text("Add Ingredient"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16.0),

                // Steps Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text("Steps", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 8.0),
                        _buildStepInputFields(),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color.fromARGB(255, 90, 113, 243), // Text color
                          ),
                          onPressed: _addStep,
                          child: const Text("Add Step"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16.0),

                // Nutritional Facts Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text("Nutritional Facts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 8.0),
                        _buildNutritionalFactInputFields(),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color.fromARGB(255, 90, 113, 243), // Text color
                          ),
                          onPressed: _addNutritionalFact,
                          child: const Text("Add Nutritional Fact"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16.0),

                // Save Recipe Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color.fromARGB(255, 90, 113, 243),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      minimumSize: const Size(150, 50),
                    ),
                  onPressed: _saveRecipe,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Add Recipe", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}