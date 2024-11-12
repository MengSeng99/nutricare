import 'package:flutter/material.dart';
import 'bmi_calculator.dart';
import 'bmi_history.dart';

class BmiTrackerScreen extends StatelessWidget {
  const BmiTrackerScreen({super.key});

void _showInfoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'How BMI is Calculated',
          style: TextStyle(
            color: Color.fromARGB(255, 90, 113, 243),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Ensure dialog height wraps around content
          children: [
            const Text(
              'BMI (Body Mass Index) is calculated using the formula:\n',
            ),
            Text.rich(
              TextSpan(
                children: [
                  const 
                  TextSpan(
                    text: 'BMI = weight (kg) / (height (m) * height (m))',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 90, 113, 243),
                      fontSize: 18, // Larger font size
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10), // Spacing for readability
            const Text(
              'Where:\n'
              '- Weight is measured in kilograms.\n'
              '- Height is measured in meters.\n\n'
              'To calculate your BMI:\n'
              '1. Measure your height in centimeters and convert it to meters.\n'
              '2. Divide your weight in kilograms by the square of your height in meters.\n\n'
              'For example:\n'
              'If your height is 170 cm (1.7 m) and your weight is 70 kg:\n'
              'BMI = 70 / (1.7 * 1.7) ≈ 24.22',
            ),
          ],
        ),
        actions: [
           ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 90, 113, 243),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'BMI Tracker',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 90, 113, 243),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Color.fromARGB(255, 90, 113, 243),
            labelColor: Color.fromARGB(255, 90, 113, 243),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Calculator'),
              Tab(text: 'History'),
            ],
          ),
          backgroundColor: Colors.white, // AppBar color
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 90, 113, 243)),
            onPressed: () {
              Navigator.pop(context); // Back navigation
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Color.fromARGB(255, 90, 113, 243)),
              onPressed: () => _showInfoDialog(context), // Show info dialog
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            BmiCalculatorScreen(), // Show Calculator
            BmiHistoryScreen(), // Show History
          ],
        ),
      ),
    );
  }
}