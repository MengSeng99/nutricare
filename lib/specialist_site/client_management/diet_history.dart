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
        List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

        for (String mealType in mealTypes) {
          var mealInfo = mealData[mealType] as Map<String, dynamic>?;
          if (mealInfo != null) {
            meals.add(MealHistory(
              mealType: mealType,
              name: mealInfo['name'] ?? 'Unnamed Meal',
              calories: mealInfo['Calories'] ?? 0,
              protein: mealInfo['Proteins'] ?? 0,
              carbs: mealInfo['Carbohydrates'] ?? 0,
              fat: mealInfo['Fats'] ?? 0,
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
    int totalCalories =
        history.meals.fold(0, (sum, meal) => sum + meal.calories);
    int totalProteins =
        history.meals.fold(0, (sum, meal) => sum + meal.protein);
    int totalCarbs = history.meals.fold(0, (sum, meal) => sum + meal.carbs);
    int totalFats = history.meals.fold(0, (sum, meal) => sum + meal.fat);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Internal padding
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800]),
                ),
                Icon(Icons.calendar_today, color: primaryColor, size: 24),
              ],
            ),
            const SizedBox(height: 16),

            // Summary Section with Icons
            if (history.meals.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNutrientInfo(Icons.local_fire_department,
                          "Calories", "$totalCalories kcal"),
                      _buildNutrientInfo(
                          Icons.fitness_center, "Protein", "$totalProteins g"),
                      _buildNutrientInfo(Icons.grain, "Carbs", "$totalCarbs g"),
                      _buildNutrientInfo(
                          Icons.bubble_chart, "Fat", "$totalFats g"),
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
    );
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

  MealHistory({
    required this.mealType,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}
