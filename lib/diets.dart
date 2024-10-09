import 'package:flutter/material.dart';

class DietsScreen extends StatelessWidget {
  const DietsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove the back arrow button
        title: const Text(
          'Diet Tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // // Header section
            // const Text(
            //   'Track Your Diet Routine',
            //   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 10),
            // const Text(
            //   'Log your meals and monitor your daily calorie intake to achieve your nutrition goals.',
            //   style: TextStyle(fontSize: 16, color: Colors.grey),
            // ),
            // const SizedBox(height: 20),

            // List of tracked meals for the day
            Expanded(
              child: ListView(
                children: [
                  _buildMealCard('Breakfast', '8:00 AM', 'Oatmeal with fruits', 250),
                  _buildMealCard('Lunch', '12:30 PM', 'Grilled chicken salad', 400),
                  _buildMealCard('Dinner', '7:00 PM', 'Steamed fish with vegetables', 350),
                  _buildMealCard('Snack', '4:00 PM', 'Greek yogurt with honey', 150),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Buttons to add a new meal or set a reminder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to a screen or show a dialog for adding a new meal
                    _showAddMealDialog(context);
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Meal', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle meal reminder setting
                    _showSetReminderDialog(context);
                  },
                  icon: const Icon(Icons.alarm, color: Colors.white),
                  label: const Text('Set Reminder', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to build individual meal cards
  Widget _buildMealCard(String mealType, String time, String description, int calories) {
    String imagePath = 'images/food_category/${mealType.toLowerCase()}.png';
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 5),
            Text(time, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text(description, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            Text('Calories: $calories', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Color.fromARGB(255, 90, 113, 243)),
          onPressed: () {
            // Handle meal edit
          },
        ),
      ),
    );
  }

  // Function to show a dialog for adding a new meal
  void _showAddMealDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Meal'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Meal Type (e.g., Breakfast)'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Time (e.g., 8:00 AM)'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Description (e.g., Oatmeal with fruits)'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Calories (e.g., 250)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle adding a new meal to the diet tracker
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Function to show a dialog for setting meal reminders
  void _showSetReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Meal Reminder')
          ,
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Meal Type (e.g., Breakfast)'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Time (e.g., 8:00 AM)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle setting a meal reminder
                Navigator.pop(context);
              },
              child: const Text('Set Reminder'),
            ),
          ],
        );
      },
    );
  }
}
