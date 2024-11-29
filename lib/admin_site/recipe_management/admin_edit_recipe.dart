import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditRecipeDetailsScreen extends StatefulWidget {
  final String recipeId;
  final String title;
  final String category;
  final int cookingTime;
  final int servings;
  final int calories;
  final String difficulty;
  final String? imageUrl;
  final String? youtubeLink;

  const EditRecipeDetailsScreen({
    super.key,
    required this.recipeId,
    required this.title,
    required this.category,
    required this.cookingTime,
    required this.servings,
    required this.calories,
    required this.difficulty,
    this.imageUrl,
    this.youtubeLink,
  });

  @override
  _EditRecipeDetailsScreenState createState() => _EditRecipeDetailsScreenState();
}

class _EditRecipeDetailsScreenState extends State<EditRecipeDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _category;
  int? _cookingTime;
  int? _servings;
  int? _calories;
  String? _difficulty;
  String? _imageUrl;
  String? _youtubeLink;
  File? _imageFile;
  List<TextEditingController> _ingredientControllers = [];
  List<TextEditingController> _stepControllers = [];
  List<TextEditingController> _nutritionalFactControllers = [];
  List<TextEditingController> _nutritionalValueControllers = [];
  List<Map<String, dynamic>> _ingredients = [];
  List<Map<String, dynamic>> _steps = [];
  List<Map<String, dynamic>> _nutritionalFacts = [];

  final List<String> _difficultyOptions = ['Easy', 'Medium', 'Hard'];
  final List<String> _categoryOptions = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  static const Color _primaryColor = Color.fromARGB(255, 90, 113, 243);
  static const Color _errorColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _category = widget.category;
    _cookingTime = widget.cookingTime;
    _servings = widget.servings;
    _calories = widget.calories;
    _difficulty = widget.difficulty;
    _imageUrl = widget.imageUrl;
    _youtubeLink = widget.youtubeLink;

    _loadIngredients();
    _loadSteps();
    _loadNutritionalFacts();
  }

  Future<void> _loadIngredients() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .collection('ingredients')
        .get();

    setState(() {
      _ingredients = snapshot.docs.map((doc) => {'name': doc['name']}).toList();
      _ingredientControllers = List.generate(
        _ingredients.length,
        (index) => TextEditingController(text: _ingredients[index]['name']),
      );
    });
  }

  Future<void> _loadSteps() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .collection('steps')
        .orderBy('number')
        .get();

    setState(() {
      _steps = snapshot.docs.map((doc) => {
        'description': doc['description'],
        'number': doc['number']
      }).toList();
      _stepControllers = List.generate(
        _steps.length,
        (index) => TextEditingController(text: _steps[index]['description']),
      );
    });
  }

  Future<void> _loadNutritionalFacts() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .collection('nutritionalFacts')
        .get();

    setState(() {
      _nutritionalFacts = snapshot.docs.map((doc) => {
        'label': doc['label'],
        'value': doc['value']
      }).toList();

      _nutritionalFactControllers = List.generate(
        _nutritionalFacts.length,
        (index) => TextEditingController(text: _nutritionalFacts[index]['label']),
      );

      _nutritionalValueControllers = List.generate(
        _nutritionalFacts.length,
        (index) => TextEditingController(text: _nutritionalFacts[index]['value'].toString()),
      );
    });
  }

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
        final storageRef = FirebaseStorage.instance.ref().child('recipe_images/${widget.recipeId}.jpg');
        await storageRef.putFile(_imageFile!);
        return await storageRef.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Image upload failed: $e'),
          backgroundColor: _errorColor,
        ));
        return null;
      }
    }
    return _imageUrl; // Return existing image URL if no new image is uploaded
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Save the form fields

      // Validate ingredients, steps, and nutritional facts
      if (!hasValidIngredients() || !hasValidSteps() || !hasValidNutritionalFacts()) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: _errorColor,
        ));
        return; // Prevent saving if invalid
      }

      String? newImageUrl = await _uploadImage();

      // Update the main recipe document
      await FirebaseFirestore.instance.collection('recipes').doc(widget.recipeId).update({
        'title': _title,
        'category': _category,
        'cookingTime': _cookingTime,
        'servings': _servings,
        'calories': _calories,
        'difficulty': _difficulty,
        'imageUrl': newImageUrl,
        'youtubeLink': _youtubeLink, // Ensure youtubeLink is saved
      });

      // Update subcollections
      await _updateSubcollections('ingredients', _getUpdatedIngredients());
      await _updateSubcollections('steps', _getUpdatedSteps());
      await _updateSubcollections('nutritionalFacts', _getUpdatedNutritionalFacts());

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Recipe updated successfully!'),
        backgroundColor: Colors.green,
      ));

      final updatedData = {
        'title': _title,
        'category': _category,
        'cookingTime': _cookingTime,
        'servings': _servings,
        'calories': _calories,
        'difficulty': _difficulty,
        'imageUrl': newImageUrl,
        'youtubeLink': _youtubeLink,
      };

      Navigator.pop(context, updatedData); // Pass back the updated data
    }
  }

  bool hasValidIngredients() {
    return _ingredientControllers.any((controller) => controller.text.isNotEmpty);
  }

  bool hasValidSteps() {
    return _stepControllers.any((controller) => controller.text.isNotEmpty);
  }

  bool hasValidNutritionalFacts() {
    return _nutritionalFactControllers.any((controller) => controller.text.isNotEmpty);
  }

  List<Map<String, dynamic>> _getUpdatedIngredients() {
    return _ingredientControllers.map((controller) => {'name': controller.text}).toList();
  }

  List<Map<String, dynamic>> _getUpdatedSteps() {
    return _stepControllers.asMap().entries.map((entry) => {
      'description': entry.value.text,
      'number': entry.key + 1,
    }).toList();
  }

  List<Map<String, dynamic>> _getUpdatedNutritionalFacts() {
    return _nutritionalFactControllers.asMap().entries.map((entry) => {
      'label': entry.value.text,
      'value': int.tryParse(_nutritionalValueControllers[entry.key].text) ?? 0,
    }).toList();
  }

  Future<void> _updateSubcollections(String collectionName, List<Map<String, dynamic>> items) async {
    final batch = FirebaseFirestore.instance.batch();

    // Clear existing documents
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .collection(collectionName)
        .get();

    for (QueryDocumentSnapshot doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    // Add new items
    for (var item in items) {
      DocumentReference ref = FirebaseFirestore.instance.collection('recipes').doc(widget.recipeId).collection(collectionName).doc();
      batch.set(ref, item);
    }

    await batch.commit();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add({'name': ''}); // Add an empty ingredient field
      _ingredientControllers.add(TextEditingController(text: ''));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index); // Remove ingredient
      _ingredientControllers[index].dispose(); // Dispose the controller
      _ingredientControllers.removeAt(index); // Remove the controller
    });
  }

  void _addStep() {
    setState(() {
      int newNumber = _steps.length + 1; // Assign the next number
      _steps.add({'description': '', 'number': newNumber}); // Add step
      _stepControllers.add(TextEditingController(text: '')); // Add new controller
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index); // Remove step
      _stepControllers[index].dispose(); // Dispose the controller
      _stepControllers.removeAt(index); // Remove the controller

      // Update the numbers for the remaining steps
      for (int i = index; i < _steps.length; i++) {
        _steps[i]['number'] = i + 1; // Reassign numerical values
      }
    });
  }

  void _addNutritionalFact() {
    setState(() {
      _nutritionalFacts.add({'label': '', 'value': 0}); // Add an empty nutritional fact
      _nutritionalFactControllers.add(TextEditingController(text: '')); // Add a controller
      _nutritionalValueControllers.add(TextEditingController(text: '')); // Add a controller for the value
    });
  }

  void _removeNutritionalFact(int index) {
    setState(() {
      _nutritionalFacts.removeAt(index); // Remove nutritional fact
      _nutritionalFactControllers[index].dispose(); // Dispose the controller
      _nutritionalFactControllers.removeAt(index); // Remove the controller
      _nutritionalValueControllers[index].dispose(); // Dispose the value controller
      _nutritionalValueControllers.removeAt(index); // Remove the controller
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
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeIngredient(index),
            ),
          ],
        );
      },
    );
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
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeStep(index),
            ),
          ],
        );
      },
    );
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
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeNutritionalFact(index),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Recipe Details", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _primaryColor),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 0.5, color: Colors.grey),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              
              children: [
                // Image Upload Card
                Card(
                  elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: Color.fromARGB(255, 221, 222, 226), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8.0),
                              image: _imageFile != null
                                  ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                                  : (_imageUrl != null && _imageUrl!.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover)
                                      : null),
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
                        const SizedBox(height: 16.0),
                        // Title Field
                        TextFormField(
                          initialValue: _title,
                          decoration: const InputDecoration(labelText: "Food Recipe Name"),
                          validator: (value) => value!.isEmpty ? 'Please enter a title.' : null,
                          onSaved: (value) => _title = value,
                        ),
                        const SizedBox(height: 16.0),

                        // Updated category dropdown
                        DropdownButtonFormField<String>(
                          value: _category,
                          decoration: const InputDecoration(labelText: "Category"),
                          items: _categoryOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _category = value;
                            });
                          },
                          validator: (value) => value == null ? 'Please select a category.' : null,
                        ),

                        const SizedBox(height: 16.0),
                        
                        // Cooking Time Field
                        TextFormField(
                          initialValue: _cookingTime?.toString(),
                          decoration: const InputDecoration(labelText: "Cooking Time (mins)"),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Please enter cooking time.' : null,
                          onSaved: (value) => _cookingTime = int.tryParse(value!),
                        ),
                        const SizedBox(height: 16.0),

                        // Servings Field
                        TextFormField(
                          initialValue: _servings?.toString(),
                          decoration: const InputDecoration(labelText: "Servings (person)"),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Please enter the number of servings.' : null,
                          onSaved: (value) => _servings = int.tryParse(value!),
                        ),
                        const SizedBox(height: 16.0),

                        // Calories Field
                        TextFormField(
                          initialValue: _calories?.toString(),
                          decoration: const InputDecoration(labelText: "Calories"),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Please enter calorie count.' : null,
                          onSaved: (value) => _calories = int.tryParse(value!),
                        ),
                        const SizedBox(height: 16.0),

                        // Difficulty Field as Dropdown
                        DropdownButtonFormField<String>(
                          value: _difficulty,
                          decoration: const InputDecoration(labelText: "Difficulty"),
                          items: _difficultyOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _difficulty = value;
                            });
                          },
                          validator: (value) => value == null ? 'Please select a difficulty.' : null,
                        ),
                        const SizedBox(height: 16.0),

                        // YouTube Link Field
                        TextFormField(
                          initialValue: _youtubeLink,
                          decoration: const InputDecoration(labelText: "YouTube Link (Optional)"),
                          keyboardType: TextInputType.url,
                          onSaved: (value) => _youtubeLink = value,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16.0),

                // Ingredients Card
                Card(
                  elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: Color.fromARGB(255, 221, 222, 226), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                            backgroundColor: _primaryColor,
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
                       elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: Color.fromARGB(255, 221, 222, 226), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                            backgroundColor: _primaryColor,
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
                       elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: Color.fromARGB(255, 221, 222, 226), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                            backgroundColor: _primaryColor,
                          ),
                          onPressed: _addNutritionalFact,
                          child: const Text("Add Nutritional Fact"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16.0),

                // Save Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    minimumSize: const Size(150, 50),
                  ),
                  onPressed: _saveRecipe,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Save", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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