import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DietHistoryWidget extends StatefulWidget {
  final String clientId; // Client ID to fetch diet history

  const DietHistoryWidget({super.key, required this.clientId});

  @override
  _DietHistoryWidgetState createState() => _DietHistoryWidgetState();
}

class _DietHistoryWidgetState extends State<DietHistoryWidget> {
  List<DietHistory> dietHistories = []; // List to hold all diet history
  List<DietHistory> filteredHistories =
      []; // List to hold filtered diet history
  DateTime? startDate; // Start date for range
  DateTime? endDate; // End date for range
  bool isLoading = true; // Loading state

  int calorieGoal = 0; // Calorie goal for the user

  final Color primaryColor = Color.fromARGB(255, 90, 113, 243); // Primary color

  // Initialize the widget state
  @override
  void initState() {
    super.initState();
    _loadDietHistory(); // Load diet history on initialization
  }

 Future<void> _loadDietHistory() async {
  setState(() {
    isLoading = true; // Set loading state to true
  });

  // Retrieve calorie goal from user's document
  DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.clientId)
      .get();

  // Check if the user document exists
  if (userDoc.exists && userDoc.data() != null) {
    calorieGoal = userDoc['calorieGoal'] ?? 0; // Assuming this exists
  }

  QuerySnapshot dietSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.clientId)
      .collection('dietHistory')
      .get();

  if (dietSnapshot.docs.isEmpty) {
    setState(() {
      dietHistories = [];
      filteredHistories = [];
      isLoading = false;
    });
    return;
  }

  List<DietHistory> newHistories = [];

  for (var doc in dietSnapshot.docs) {
    var mealData = doc.data() as Map<String, dynamic>?;

    if (mealData != null) {
      DateTime.parse(doc.id);
      List<MealHistory> meals = [];
      List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Other'];

      for (String mealType in mealTypes) {
        var mealInfo = mealData[mealType] as Map<String, dynamic>?;
        if (mealInfo != null) {
          meals.add(MealHistory(
            mealType: mealType,
            name: mealInfo['name'] ?? 'Unnamed Meal',
            calories: mealInfo['Calories'] ?? 0,
            protein: mealInfo['Protein'] ?? 0,
            carbs: mealInfo['Carbohydrate'] ?? 0,
            fat: mealInfo['Fat'] ?? 0,
            calorieGoal: mealInfo['CalorieGoal'] ?? 0, // Assuming it's here, before we populate meals
          ));
        }
      }
      newHistories.add(DietHistory(date: doc.id, meals: meals));
    }
  }

  setState(() {
    dietHistories = newHistories;
    filteredHistories = newHistories;
    isLoading = false;
  });
}

  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedRange != null) {
      setState(() {
        startDate = pickedRange.start;
        endDate = pickedRange.end;

        // Filter the diet histories by the selected date range
        filteredHistories = dietHistories.where((history) {
          DateTime docDate = DateTime.parse(history.date);
          return docDate.isAfter(startDate!.subtract(Duration(days: 1))) &&
              docDate.isBefore(endDate!.add(Duration(days: 1)));
        }).toList();
      });
    }
  }

  void _resetDateRange() {
    setState(() {
      startDate = null;
      endDate = null;
      filteredHistories = dietHistories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isLoading)
              Center(child: CircularProgressIndicator(color: primaryColor))
            else if (dietHistories.isEmpty)
              Expanded(child: _buildNoDietHistoryWidget())
            else ...[
              // Row for Date Range Button and Reset Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _selectDateRange,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            startDate != null && endDate != null
                                ? 'Selected: ${startDate!.month}/${startDate!.day} - ${endDate!.month}/${endDate!.day}'
                                : 'Select Date Range',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _resetDateRange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Check if filteredHistories is empty
            if (filteredHistories.isEmpty &&
                startDate != null &&
                endDate != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1),
                      Icon(Icons.info_outline, size: 100, color: primaryColor),
                      SizedBox(height: 16),
                      Text(
                        'No diet records available for the selected date range!',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try selecting a different date range.',
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (filteredHistories.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: filteredHistories.length,
                  itemBuilder: (context, index) {
                    DietHistory history = filteredHistories[index];
                    return _buildHistoryCard(history);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDietHistoryWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 100,
              color: primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'No Diet History Available Yet!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'The current user has not logged any diet history yet.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

Widget _buildHistoryCard(DietHistory history) {
  int totalProteins =
      history.meals.fold(0, (sum, meal) => sum + meal.protein);
  int totalCarbs = history.meals.fold(0, (sum, meal) => sum + meal.carbs);
  int totalFats = history.meals.fold(0, (sum, meal) => sum + meal.fat);

  int totalCalories =
      history.meals.fold(0, (sum, meal) => sum + meal.calories);
  
  // Determine the status of the calorie goal
  String caloricFeedback;
  Color feedbackColor;
  int excessCalories = totalCalories > calorieGoal ? totalCalories - calorieGoal : 0;

  if (excessCalories > 0) {
    caloricFeedback = 'Exceeds by $excessCalories kcal';
    feedbackColor = Colors.red;
  } else {
    caloricFeedback = 'Remaining: ${calorieGoal - totalCalories} kcal to reach goal';
    feedbackColor = Colors.green;
  }
  
  return Dismissible(
    key: Key(history.date), 
    background: Container(
      color: Colors.red, 
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white), 
    ),
    direction: DismissDirection.endToStart,
    confirmDismiss: (direction) async {
      final confirmation = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: RichText(
              text: TextSpan(
                text: 'Delete Diet History',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            content: RichText(
              text: TextSpan(
                text: 'Are you sure you want to delete this diet history on ',
                style: TextStyle(color: Colors.black), 
                children: <TextSpan>[
                  TextSpan(
                    text: history.date, 
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: '?'), 
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false); 
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Delete', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop(true); 
                },
              ),
            ],
          );
        },
      );

      return confirmation ?? false; 
    },
    onDismissed: (direction) async {
      bool isDeleted = await _deleteDietHistory(history.date);
      
      if (isDeleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted diet history for ${history.date}'),
          backgroundColor: Colors.red,),
        );
      } else {
        setState(() {
          filteredHistories.add(history); // Reinsert if not deleted
        });
      }
    },
    child: Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${history.date}',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
                Icon(Icons.calendar_today, color: primaryColor, size: 24),
              ],
            ),
            const SizedBox(height: 16),

            // Calorie Goal and Progress Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calorie Goal: $calorieGoal kcal',
                        style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Total Calories Consumed: $totalCalories kcal',
                        style: TextStyle(fontSize: 18, color: feedbackColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        caloricFeedback,
                        style: TextStyle(fontSize: 16, color: feedbackColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Optional: Progress Circle (Add a circular progress indicator)
                CircularProgressIndicator(
                  value: totalCalories / calorieGoal,
                  backgroundColor: Colors.grey[300],
                  color: feedbackColor,
                  strokeWidth: 7,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary Section with Icons
            if (history.meals.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNutrientInfo(Icons.local_fire_department, "Calories", "$totalCalories kcal"),
                      _buildNutrientInfo(Icons.fitness_center, "Protein", "$totalProteins g"),
                      _buildNutrientInfo(Icons.grain, "Carbs", "$totalCarbs g"),
                      _buildNutrientInfo(Icons.bubble_chart, "Fat", "$totalFats g"),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            // Meals Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: history.meals.isEmpty
                  ? [
                      Text(
                        'No Meals Logged',
                        style: TextStyle(color: Colors.redAccent, fontSize: 16),
                      )
                    ]
                  : history.meals.map((meal) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMealCard(meal),
                          const Divider(thickness: 1, color: Colors.grey),
                        ],
                      );
                    }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> _deleteDietHistory(String date) async {
  try {
    // Delete the document from Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.clientId)
        .collection('dietHistory')
        .doc(date) // Assuming the `date` is the document ID
        .delete();

    // Update the local state to reflect the deletion
    setState(() {
      dietHistories.removeWhere((history) => history.date == date);
      filteredHistories.removeWhere((history) => history.date == date);
    });
    
    return true; // Return true if deletion was successful
  } catch (e) {
    // Handle error if necessary
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete history: $e')),
    );
    return false; // Return false if an error occurred
  }
}

// Helper widget for displaying each nutrient with an icon
  Widget _buildNutrientInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.black87)),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildMealCard(MealHistory meal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                meal.mealType,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                meal.name,
                style: const TextStyle(color: Colors.grey),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${meal.calories} kcal',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Protein: ${meal.protein} g\nCarbs: ${meal.carbs} g\nFat: ${meal.fat} g',
              style: const TextStyle(color: Colors.grey),
            ),
          ]),
        ],
      ),
    );
  }
}

class DietHistory {
  final String date;
  final List<MealHistory> meals;

  DietHistory({
    required this.date,
    required this.meals,
  });
}

class MealHistory {
  final String mealType;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int calorieGoal;

  MealHistory({
    required this.mealType,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat, 
    required this.calorieGoal,
  });
}
