import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calories_calculator.dart';
import 'meal_selection.dart'; // Import your CaloriesCalculatorScreen

class DietsScreen extends StatefulWidget {
  const DietsScreen({super.key});

  @override
  _DietsScreenState createState() => _DietsScreenState();
}

class _DietsScreenState extends State<DietsScreen> {
  DateTime _selectedDate = DateTime.now();
  int dailyCalorieGoal = 999; // Initialize with a value that indicates no goal
  int consumedCalories = 0; // Will be retrieved from Firestore
  int totalCarbs = 0; // Will be retrieved from Firestore
  int totalProtein = 0; // Will be retrieved from Firestore
  int totalFat = 0; // Will be retrieved from Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance

  // A list to hold the meal data
  List<Meal> meals = [];

  @override
  void initState() {
    super.initState();
    _loadDietData();
  }

  Future<void> _loadDietData() async {
    User? user = _auth.currentUser; // Get current user
    if (user == null) {
      // print("User is not logged in");
      return; // Handle user not logged in
    }

    String userId = user.uid; // Use current user's ID
    String dateKey =
        '${_selectedDate.year}${_selectedDate.month.toString().padLeft(2, '0')}${_selectedDate.day.toString().padLeft(2, '0')}';

    // Fetch user's diet history document
    DocumentSnapshot dietSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('dietHistory')
        .doc(dateKey)
        .get();

    // Load user's profile document to get daily calorie goal
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    // Variables to hold new meals and initial totals
    List<Meal> newMeals = [];
    int newConsumedCalories = 0;
    int newTotalCarbs = 0;
    int newTotalProtein = 0;
    int newTotalFat = 0;

    // Initialize dailyCalorieGoal to 0
    dailyCalorieGoal = 0; // Default to 0

    // Check if user document exists and handle accordingly
    if (userSnapshot.exists) {
      // Check if the calorieGoal field exists
      if (userSnapshot.data() != null &&
          (userSnapshot.data() as Map<String, dynamic>)
              .containsKey('calorieGoal')) {
        dailyCalorieGoal = userSnapshot['calorieGoal'] ?? 0; // Set to 0 if null
        // print("Daily calorie goal: $dailyCalorieGoal");
      } else {
        // print("Field 'calorieGoal' does not exist. Defaulting to 0.");
        dailyCalorieGoal = 0; // Explicitly set to 0
      }
    } else {
      // print("User snapshot does not exist");
      dailyCalorieGoal = 0; // Set to 0 if user does not exist
    }

    // If no diet document exists for the selected date
    if (!dietSnapshot.exists) {
      // Default meals if nothing exists
      newMeals = List.generate(
        4,
        (index) => Meal(
          mealType: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other'][index],
          name: 'No Meal Logged Yet',
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
        ),
      );
    } else {
      // Load meal details if diet document exists
      List<String> mealTypes = [
        'Breakfast',
        'Lunch',
        'Dinner',
        'Snack',
        'Other'
      ];
      for (String mealType in mealTypes) {
        var dietData = dietSnapshot.data() as Map<String, dynamic>?;
        var mealData = dietData?[mealType] as Map<String, dynamic>?;

        if (mealData != null) {
          Meal meal = Meal(
            mealType: mealType,
            name: mealData['name'] ?? 'No Meal Logged Yet',
            calories: mealData['Calories'] ?? 0,
            protein: mealData['Protein'] ?? 0,
            carbs: mealData['Carbohydrate'] ?? 0,
            fat: mealData['Fat'] ?? 0,
          );

          newMeals.add(meal);

          // Accumulate totals
          newConsumedCalories += meal.calories;
          newTotalProtein += meal.protein;
          newTotalCarbs += meal.carbs;
          newTotalFat += meal.fat;
        } else {
          newMeals.add(Meal(
            mealType: mealType,
            name: 'No Meal Logged Yet',
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
          ));
        }
      }
    }

    // Call setState to update the UI
    setState(() {
      consumedCalories = newConsumedCalories;
      totalCarbs = newTotalCarbs;
      totalProtein = newTotalProtein;
      totalFat = newTotalFat;
      meals = newMeals; // Update the meals list
    });

    // Show dialog if dailyCalorieGoal is 0
    if (dailyCalorieGoal == 0) {
      _showCalorieGoalDialog();
    }
  }

  void _showCalorieGoalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 4.0,
          backgroundColor: Colors.white,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              // Main dialog content
              Padding(
                padding: const EdgeInsets.only(
                    top: 30, right: 30, left: 16, bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Set Your Calorie Goal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 90, 113, 243),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You haven\'t set a daily calorie goal. '
                      'Please tap the calculator icon in the top right corner to set it.',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 90, 113, 243),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Okay',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.of(context).pop(); // Just close the dialog
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Diet Tracker',
          style: TextStyle(
            color: Color.fromARGB(255, 90, 113, 243),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CaloriesCalculatorScreen()),
                );
                if (result != null) {
                  setState(() {
                    dailyCalorieGoal = result; // Update the caloric goal
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calculate_outlined,
                        color: Color.fromARGB(255, 90, 113, 243),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Set Up Calorie Goal',
                        style: TextStyle(
                          color: Color.fromARGB(255, 90, 113, 243),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.width * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.fromARGB(255, 241, 242, 248).withOpacity(0.6),
                      Colors.white,
                    ],
                    center: Alignment(-0.5, -0.5),
                    radius: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10.0,
                      spreadRadius: 5.0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: MediaQuery.of(context).size.width * 0.4,
                      child: CircularProgressIndicator(
                        value: consumedCalories /
                            (dailyCalorieGoal <= 0 ? 1 : dailyCalorieGoal),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          consumedCalories > dailyCalorieGoal
                              ? Colors.red
                              : Color.fromARGB(255, 90, 113, 243),
                        ),
                        strokeWidth: 14,
                      ),
                    ),
                    Positioned(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$consumedCalories',
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                              color: consumedCalories > dailyCalorieGoal
                                  ? Colors.red
                                  : Color.fromARGB(255, 90, 113, 243),
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Column(
                        children: [
                          Text(
                            '/ ${dailyCalorieGoal > 0 ? dailyCalorieGoal : "0"}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (consumedCalories > dailyCalorieGoal)
                            Text(
                              '+${consumedCalories - dailyCalorieGoal} kcal',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nutrient Breakdown Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NutrientCard(label: 'Carbs', value: '$totalCarbs g'),
                    _NutrientCard(label: 'Protein', value: '$totalProtein g'),
                    _NutrientCard(label: 'Fat', value: '$totalFat g'),
                  ],
                ),
              ),
            ),

            // Date Navigator
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left,
                        color: Color.fromARGB(255, 90, 113, 243)),
                    onPressed: () {
                      setState(() {
                        _selectedDate =
                            _selectedDate.subtract(const Duration(days: 1));
                        _loadDietData(); // Load data for the new date
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.date_range,
                        color: Color.fromARGB(255, 90, 113, 243)),
                    onPressed: () => _selectDate(context),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedDate.toLocal()}'.split(' ')[0],
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 90, 113, 243)),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.arrow_right,
                        color: Color.fromARGB(255, 90, 113, 243)),
                    onPressed: _selectedDate.isBefore(DateTime.now())
                        ? () {
                            setState(() {
                              _selectedDate =
                                  _selectedDate.add(const Duration(days: 1));
                              _loadDietData(); // Load data for the new date
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
            // List of tracked meals for the day
            Expanded(
              child: ListView.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  Meal meal = meals[index];
                  return _buildMealCard(meal.mealType, meal.name, meal.calories,
                      meal.protein, meal.carbs, meal.fat);
                },
              ),
            ),
            // Add this just before the Expanded widget
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 90, 113, 243),
                  // padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _showManualFoodLogDialog,
                child: Text(
                  'Log Food Manually',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(String mealType, String description, int calories,
      int protein, int carbs, int fat) {
    String imagePath = 'images/food_category/${mealType.toLowerCase()}.png';

    // Determine which icon to use based on whether the meal has been logged
    IconData iconData = description != 'No Meal Logged Yet' &&
            description.isNotEmpty
        ? Icons.edit_outlined // Use edit icon if meal has data
        : Icons
            .add_circle_outline_rounded; // Use add icon if meal is not logged

    return Card(
      elevation: 3,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.only(left: 16, right: 16, top: 2, bottom: 2),
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
            title: Text(
              mealType,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 5),
                Text(description, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                Text('$calories kcal',
                    style: const TextStyle(color: Colors.grey)),
                Text('Protein: $protein g',
                    style: const TextStyle(color: Colors.grey)),
                Text('Carbs: $carbs g',
                    style: const TextStyle(color: Colors.grey)),
                Text('Fat: $fat g', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            trailing: IconButton(
              icon: Icon(iconData,
                  color: const Color.fromARGB(255, 90, 113, 243)),
              iconSize: 40,
              onPressed: () {
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MealSelectionScreen(
                      mealType: mealType,
                      selectedDate:
                          _selectedDate, // Pass the selected date here
                      calorieGoal: dailyCalorieGoal,
                    ),
                  ),
                ).then((shouldRefresh) {
                  if (shouldRefresh == true) {
                    _loadDietData(); // Refresh the diet data when coming back
                  }
                });
              },
            ),
          ),
          // Remove button (only show if meal is logged)
          if (description != 'No Meal Logged Yet' && description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text('Remove Meal',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  _showRemoveMealConfirmationDialog(mealType);
                },
              ),
            ),
        ],
      ),
    );
  }

// New method to show confirmation dialog before removing meal
  void _showRemoveMealConfirmationDialog(String mealType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text('Remove Meal',
              style: TextStyle(
                  color: Color.fromARGB(255, 90, 113, 243),
                  fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to remove the $mealType meal?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Remove', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
                _removeMeal(mealType); // Call method to remove the meal
              },
            ),
          ],
        );
      },
    );
  }

Future<void> _removeMeal(String mealType) async {
  User? user = _auth.currentUser;
  if (user == null) return;

  String dateKey =
      '${_selectedDate.year}${_selectedDate.month.toString().padLeft(2, '0')}${_selectedDate.day.toString().padLeft(2, '0')}';

  try {
    // Reference to the diet history document
    DocumentReference dietDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dietHistory')
        .doc(dateKey);

    // Remove the specific meal type
    await dietDocRef.update({
      mealType: FieldValue.delete(),
    });

    // Check if the document still has any meal types
    DocumentSnapshot updatedDietSnapshot = await dietDocRef.get();
    Map<String, dynamic>? updatedDietData = updatedDietSnapshot.data() as Map<String, dynamic>?;

    bool hasMeals = updatedDietData != null &&
        updatedDietData.keys.any((key) => ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other'].contains(key));

    if (!hasMeals) {
      // If there are no meal types left, delete the document and refresh the state
      await dietDocRef.delete(); // Delete the document if no meals left.


    } else {
      // Reload diet data to reflect the changes
      _loadDietData();
    }

    // Call setState to refresh the UI
    setState(() {
      // Clear the local meals list if deleting the last meal
      if (!hasMeals) {
        consumedCalories = 0; // Reset the calorie count
        totalCarbs = 0; // Reset total carbs
        totalProtein = 0; // Reset total protein
        totalFat = 0; // Reset total fat

        _loadDietData();
      }
    });

    // Show a success snackbar for removing the meal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$mealType meal removed successfully'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    // Show an error snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to remove $mealType meal'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  // Function to select a date using the DatePicker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadDietData(); // Load data for the new date
      });
    }
  }

 void _showManualFoodLogDialog() {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController fatController = TextEditingController();
  String selectedMealType = 'Breakfast'; // Default meal type
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView( // Prevent overflow
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Log Food Manually',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 90, 113, 243),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Meal Type Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedMealType,
                        decoration: InputDecoration(
                          labelText: 'Meal Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMealType = value!;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      // Meal Name
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Meal Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a meal name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      // Calories
                      TextFormField(
                        controller: caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Calories (kcal)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter calories';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (int.parse(value) < 0) {
                            return 'Calories cannot be negative';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      // Protein
                      TextFormField(
                        controller: proteinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Protein (g)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter protein amount';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (int.parse(value) < 0) {
                            return 'Protein cannot be negative';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      // Carbs
                      TextFormField(
                        controller: carbsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Carbohydrates (g)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter carbohydrate amount';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (int.parse(value) < 0) {
                            return 'Carbohydrates cannot be negative';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      // Fat
                      TextFormField(
                        controller: fatController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Fat (g)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter fat amount';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (int.parse(value) < 0) {
                            return 'Fat cannot be negative';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel',
                                style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 90, 113, 243),
                            ),
                            onPressed: () {
                              // Validate the form
                              if (formKey.currentState!.validate()) {
                                _saveManualFoodLog(
                                  selectedMealType,
                                  nameController.text,
                                  int.parse(caloriesController.text),
                                  int.parse(proteinController.text),
                                  int.parse(carbsController.text),
                                  int.parse(fatController.text),
                                );
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text('Add',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _saveManualFoodLog(
  String mealType,
  String name,
  int calories,
  int protein,
  int carbs,
  int fat,
) async {
  User? user = _auth.currentUser;
  if (user == null) return;

  String dateKey =
      '${_selectedDate.year}${_selectedDate.month.toString().padLeft(2, '0')}${_selectedDate.day.toString().padLeft(2, '0')}';

  try {
    // Reference to the diet history document
    DocumentReference dietDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dietHistory')
        .doc(dateKey);

    // Get the current document data
    DocumentSnapshot dietSnapshot = await dietDocRef.get();

    // Prepare the meal data
    Map<String, dynamic> mealData = {
      'name': name,
      'Calories': calories,
      'Protein': protein,
      'Carbohydrate': carbs,
      'Fat': fat,
    };

    // If document doesn't exist, create it with the meal data and calorie goal
    if (!dietSnapshot.exists) {
      await dietDocRef.set({
        'calorieGoal': dailyCalorieGoal, // Save daily calorie goal
        mealType: mealData, // Save meal data
      });
    } else {
      // Update the specific meal type without overwriting the calorie goal
      await dietDocRef.update({
        mealType: mealData,
      });
    }

    // Reload diet data to reflect the changes
    _loadDietData();

    // Show success scaffold for adding meal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Food logged successfully!'),
      backgroundColor: Colors.green,),
    );
  } catch (e) {
    // Show an error snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save meal. Please try again.')),
    );
  }
}
}

class Meal {
  final String mealType; // Type of the meal: Breakfast, Lunch, Dinner, Snack
  final String name; // Name of the meal
  final int calories; // Total calories in the meal
  final int protein; // Total protein in the meal
  final int carbs; // Total carbohydrates in the meal
  final int fat; // Total fat in the meal

  Meal({
    required this.mealType,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

// NutrientCard widget
class _NutrientCard extends StatelessWidget {
  final String label;
  final String value;

  const _NutrientCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
