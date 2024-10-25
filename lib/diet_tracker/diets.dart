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
  int dailyCalorieGoal = -1; // Initialize with a value that indicates no goal
  int consumedCalories = 0;  // Will be retrieved from Firestore
  int totalCarbs = 0;        // Will be retrieved from Firestore
  int totalProtein = 0;      // Will be retrieved from Firestore
  int totalFat = 0;          // Will be retrieved from Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance

  // A list to hold the meal data
  List<Meal> meals = []; 

  @override
  void initState() {
    super.initState();
    _loadDietData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          'Diet Tracker',
          style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: Color.fromARGB(255, 90, 113, 243)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CaloriesCalculatorScreen()),
              );
              if (result != null) {
                setState(() {
                  dailyCalorieGoal = result; // Update the caloric goal
                });
              }
            },
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
                width: 140,
                height: 140,
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
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: consumedCalories / (dailyCalorieGoal <= 0 ? 1 : dailyCalorieGoal), // Avoid division by zero
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 90, 113, 243)),
                        strokeWidth: 14,
                      ),
                    ),
                    Positioned(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$consumedCalories',
                            style: const TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 90, 113, 243),
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
                      child: Text(
                        '/ ${dailyCalorieGoal >= 0 ? dailyCalorieGoal : "Null"}', // Display 'Null' if no goal
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
                    icon: const Icon(Icons.arrow_left, color: Color.fromARGB(255, 90, 113, 243)),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        _loadDietData(); // Load data for the new date
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.date_range, color: Color.fromARGB(255, 90, 113, 243)),
                    onPressed: () => _selectDate(context),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedDate.toLocal()}'.split(' ')[0],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 90, 113, 243)),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.arrow_right, color: Color.fromARGB(255, 90, 113, 243)),
                    onPressed: _selectedDate.isBefore(DateTime.now()) 
                        ? () {
                            setState(() {
                              _selectedDate = _selectedDate.add(const Duration(days: 1));
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
                  return _buildMealCard(meal.mealType, meal.name, meal.calories);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _loadDietData() async {
  User? user = _auth.currentUser; // Get current user
  if (user == null) {
    return; // Handle user not logged in
  }

  String userId = user.uid; // Use current user's ID
  String dateKey = '${_selectedDate.year}${_selectedDate.month.toString().padLeft(2, '0')}${_selectedDate.day.toString().padLeft(2, '0')}';

  DocumentSnapshot dietSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('dietHistory')
      .doc(dateKey)
      .get();
  
  DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  // Variables to hold new state data
  int newConsumedCalories = 0;
  int newTotalCarbs = 0;
  int newTotalProtein = 0;
  int newTotalFat = 0;
  List<Meal> newMeals = [];

  if (userSnapshot.exists) {
    dailyCalorieGoal = userSnapshot['calorieGoal'] ?? -1; // Set daily calorie goal
  }

  if (dietSnapshot.exists) {
    newConsumedCalories = dietSnapshot['totalKcal'] ?? 0;
    newTotalCarbs = dietSnapshot['totalCarbs'] ?? 0;
    newTotalProtein = dietSnapshot['totalProtein'] ?? 0;
    newTotalFat = dietSnapshot['totalFat'] ?? 0;

    // Load meal details
    List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    for (String mealType in mealTypes) {
      DocumentSnapshot mealDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('dietHistory')
          .doc(dateKey)
          .collection('dietTracker')
          .doc(mealType)
          .get();

      // Adding meal information to the meals list
      if (mealDoc.exists) {
        var mealData = mealDoc.data() as Map<String, dynamic>;
        newMeals.add(Meal(
          mealType: mealType,
          name: mealData['name'] ?? 'Unnamed Meal', // Fallback for name if not found
          calories: mealData['Calories'] ?? 0, // Fallback for calories if not found
        ));
      } else {
        newMeals.add(Meal(
          mealType: mealType,
          name: 'Unnamed Meal', // Fallback for name if not found
          calories: 0, // Fallback for calories if not found
        ));
      }
    }
  } else {
    newConsumedCalories = 0;
    newTotalCarbs = 0;
    newTotalProtein = 0;
    newTotalFat = 0;
    newMeals = List.generate(4, (index) => Meal(
      mealType: ['Breakfast', 'Lunch', 'Dinner', 'Snack'][index],
      name: 'No Meal Logged Yet',
      calories: 0,
    )); // Show empty meals cards if no snapshot
  }

  // Call setState to update the UI now that we have all data
  setState(() {
    consumedCalories = newConsumedCalories;
    totalCarbs = newTotalCarbs;
    totalProtein = newTotalProtein;
    totalFat = newTotalFat;
    meals = newMeals; // Update the meals list
  });
}

  // Function to build individual meal cards
  Widget _buildMealCard(String mealType, String description, int calories) {
    String imagePath = 'images/food_category/${mealType.toLowerCase()}.png'; // Image based on meal type
    return Card(
      elevation: 3,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 2, bottom: 2),
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
            Text('$calories kcal', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, color: Color.fromARGB(255, 90, 113, 243)),
          iconSize: 40,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MealSelectionScreen(mealType: mealType),
              ),
            );
          },
        ),
      ),
    );
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
}

// Meal model class
class Meal {
  final String mealType; // Type of the meal: Breakfast, Lunch, Dinner, Snack
  final String name; // Name of the meal
  final int calories; // Total calories in the meal

  Meal({required this.mealType, required this.name, required this.calories});
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
          style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}