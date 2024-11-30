import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MealSelectionScreen extends StatefulWidget {
  final String mealType;
  final DateTime selectedDate;

  const MealSelectionScreen({
    Key? key,
    required this.mealType,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _MealSelectionScreenState createState() => _MealSelectionScreenState();
}

class _MealSelectionScreenState extends State<MealSelectionScreen> {
  String searchQuery = "";
  List<String> categories = [];
  String? selectedCategory = 'All';
  Set<String> favoriteRecipeIds = <String>{};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _loadFavoriteRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('recipes').get();
    Set<String> uniqueCategories = {};

    for (var doc in snapshot.docs) {
      var data = doc.data();
      if (data.containsKey('category')) {
        uniqueCategories.add(data['category']);
      }
    }

    setState(() {
      categories = uniqueCategories.toList();
    });
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

  Future<void> _toggleFavoriteStatus(String recipeId) async {
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
    } else {
      await favRecipesRef.set({});
      setState(() {
        favoriteRecipeIds.add(recipeId);
      });
    }
  }

  int _parseStringToInt(dynamic value) {
    if (value is String) {
      return int.tryParse(value) ?? 0;
    } else if (value is int) {
      return value;
    } else if (value is double) {
      return value.toInt();
    }
    return 0;
  }

  void _showRecipeDialog(
      BuildContext context, String title, String imageUrl, String recipeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RecipeDialog(
          title: title,
          imageUrl: imageUrl,
          recipeId: recipeId,
          defaultServings: 1,
          addToLog:
              (String title, int calories, int protein, int carbs, int fat) {
            addToLog(title, calories, protein, carbs, fat);
          },
        );
      },
    );
  }

  void addToLog(
      String title, int calories, int protein, int carbs, int fat) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;
    String mealType = widget.mealType;
    String dateKey = DateFormat('yyyyMMdd').format(widget.selectedDate);

    Map<String, dynamic> mealData = {
      'name': title,
      'Calories': calories,
      'Protein': protein,
      'Carbohydrate': carbs,
      'Fat': fat,
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('dietHistory')
          .doc(dateKey)
          .set({
        mealType: mealData,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('$title added to log! You may view it in the Diet History.'),
          duration: const Duration(seconds: 4),
          backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error adding to log.'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime currentSelectedDate = widget.selectedDate;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '${widget.mealType} on ${DateFormat('yyyy-MM-dd').format(currentSelectedDate)}',
          style: const TextStyle(
            color: Color.fromARGB(255, 90, 113, 243),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 90, 113, 243)),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 245, 245, 255)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search any recipe",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 90, 113, 243),
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: selectedCategory == 'All',
                          onSelected: (isSelected) {
                            setState(() {
                              selectedCategory = isSelected ? 'All' : null;
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
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ChoiceChip(
                          label: const Text('Favorites'),
                          selected: selectedCategory == 'Favorites',
                          onSelected: (isSelected) {
                            setState(() {
                              if (isSelected) {
                                selectedCategory = 'Favorites';
                                _loadFavoriteRecipes();
                              } else {
                                selectedCategory = 'All';
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
                      ...categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: selectedCategory == category,
                            onSelected: (isSelected) {
                              setState(() {
                                selectedCategory =
                                    isSelected ? category : 'All';
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
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Error fetching recipes.'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No recipes available.'));
                  }

                  final recipes = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    bool matchesSearchQuery = data['title']
                        .toString()
                        .toLowerCase()
                        .startsWith(searchQuery);

                    bool matchesCategory;
                    if (selectedCategory == 'All') {
                      matchesCategory = true;
                    } else {
                      matchesCategory = (selectedCategory == 'Favorites'
                          ? favoriteRecipeIds.contains(doc.id)
                          : data['category'] == selectedCategory);
                    }

                    return matchesSearchQuery && matchesCategory;
                  }).toList();

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: recipes.map((recipeDoc) {
                        var recipeData =
                            recipeDoc.data() as Map<String, dynamic>;
                        String recipeId = recipeDoc.id;
                        return _buildRecipeCard(context, recipeData, recipeId);
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(
      BuildContext context, Map<String, dynamic> recipe, String recipeId) {
    bool isFavorite = favoriteRecipeIds.contains(recipeId);

    return GestureDetector(
      onTap: () {
        _showRecipeDialog(
            context, recipe['title'], recipe['imageUrl'], recipeId);
      },
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 4.0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.network(
                      recipe['imageUrl'],
                      fit: BoxFit.cover,
                      height: MediaQuery.of(context).size.width * 0.5,
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.bookmark : Icons.bookmark_border,
                          color: isFavorite
                              ? const Color.fromARGB(255, 90, 113, 243)
                              : Colors.grey,
                        ),
                        onPressed: () {
                          _toggleFavoriteStatus(recipeId);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  color: Color.fromARGB(255, 90, 113, 243),
                ),
              ),
              const SizedBox(height: 8),
              // Display servings here
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .doc(recipeId)
                    .snapshots(),
                builder: (context, servingsSnapshot) {
                  if (servingsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Text('Loading servings...');
                  }
                  if (servingsSnapshot.hasError || !servingsSnapshot.hasData) {
                    return const Text('Error fetching servings.');
                  }
                  var servingsData =
                      servingsSnapshot.data!.data() as Map<String, dynamic>;
                  int servings = servingsData['servings'] ?? 1;
                  return Text('Servings: $servings',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500));
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Nutritional Facts:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .doc(recipeId)
                    .collection('nutritionalFacts')
                    .snapshots(),
                builder: (context, factsSnapshot) {
                  if (factsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Text('Loading nutritional facts...');
                  }

                  if (factsSnapshot.hasError || !factsSnapshot.hasData) {
                    return const Text('Error fetching nutritional facts.');
                  }

                  var nutritionalDocuments = factsSnapshot.data!.docs;
                  if (nutritionalDocuments.isEmpty) {
                    return const Text('No nutritional facts available.');
                  }

                  Map<String, String> nutritionalValues = {
                    'Calories': '0',
                    'Protein': '0',
                    'Carbohydrate': '0',
                    'Fat': '0',
                  };

                  for (var doc in nutritionalDocuments) {
                    var data = doc.data() as Map<String, dynamic>;
                    nutritionalValues[data['label']] = data['value'].toString();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calories: ${nutritionalValues['Calories']} kcal',
                          style: const TextStyle(fontSize: 14)),
                      Text('Protein: ${nutritionalValues['Protein']} g',
                          style: const TextStyle(fontSize: 14)),
                      Text(
                          'Carbohydrate: ${nutritionalValues['Carbohydrate']} g',
                          style: const TextStyle(fontSize: 14)),
                      Text('Fat: ${nutritionalValues['Fat']} g',
                          style: const TextStyle(fontSize: 14)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeDialog extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String recipeId;
  final int defaultServings;
  final Function(String, int, int, int, int) addToLog; // Callback for addToLog

  const RecipeDialog({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.recipeId,
    this.defaultServings = 1,
    required this.addToLog, // Accept the callback in constructor
  });

  @override
  _RecipeDialogState createState() => _RecipeDialogState();
}

class _RecipeDialogState extends State<RecipeDialog> {
  final ValueNotifier<int> selectedServingCountNotifier =
      ValueNotifier<int>(1); // Initialize ValueNotifier
  int totalServings = 1; // To hold the total servings from Firestore
  int caloriesPerServing = 0;
  int proteinPerServing = 0;
  int carbohydratePerServing = 0;
  int fatPerServing = 0;

  @override
  void dispose() {
    selectedServingCountNotifier.dispose(); // Dispose notifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .get(),
      builder: (context, recipeSnapshot) {
        if (recipeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (recipeSnapshot.hasError || !recipeSnapshot.hasData) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Recipe not found.'),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        }

        var recipeData = recipeSnapshot.data!.data() as Map<String, dynamic>;
        totalServings =
            recipeData['servings'] ?? 1; // Get total servings from Firestore

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('recipes')
              .doc(widget.recipeId)
              .collection('nutritionalFacts')
              .get(),
          builder: (context, factsSnapshot) {
            if (factsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (factsSnapshot.hasError || !factsSnapshot.hasData) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('Nutritional facts not available.'),
                actions: [
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            }

            for (var doc in factsSnapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              String label = data['label'];

              switch (label) {
                case 'Calories':
                  caloriesPerServing = _parseStringToInt(data['value']) ~/
                      totalServings; // Divide by total servings
                  break;
                case 'Protein':
                  proteinPerServing = _parseStringToInt(data['value']) ~/
                      totalServings; // Divide by total servings
                  break;
                case 'Carbohydrate':
                  carbohydratePerServing = _parseStringToInt(data['value']) ~/
                      totalServings; // Divide by total servings
                  break;
                case 'Fat':
                  fatPerServing = _parseStringToInt(data['value']) ~/
                      totalServings; // Divide by total servings
                  break;
              }
            }

            return AlertDialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15.0),
  ),
  contentPadding: const EdgeInsets.all(0),
  content: SizedBox(
    width: MediaQuery.of(context).size.width * 0.9,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
              color: Color.fromARGB(255, 90, 113, 243),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Select Servings:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using a Card to wrap the serving counter with an elevated interface
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Color.fromARGB(255, 90, 113, 243)),
                      onPressed: () {
                        if (selectedServingCountNotifier.value > 1) {
                          selectedServingCountNotifier.value--;
                        }
                      },
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: selectedServingCountNotifier,
                      builder: (context, count, child) {
                        return Text(
                          '$count',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ); // Updated text style
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Color.fromARGB(255, 90, 113, 243)),
                      onPressed: () {
                        selectedServingCountNotifier.value++;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Calculate nutritional values based on current selected servings
            widget.addToLog(
              widget.title,
              (caloriesPerServing * selectedServingCountNotifier.value),
              (proteinPerServing * selectedServingCountNotifier.value),
              (carbohydratePerServing * selectedServingCountNotifier.value),
              (fatPerServing * selectedServingCountNotifier.value),
            );
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 90, 113, 243),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Add to Log', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 16),
      ],
    ),
  ),
);
          },
        );
      },
    );
  }

  int _parseStringToInt(dynamic value) {
    if (value is String) {
      return int.tryParse(value) ?? 0;
    } else if (value is int) {
      return value;
    } else if (value is double) {
      return value.toInt();
    }
    return 0;
  }
}
