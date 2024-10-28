import 'package:flutter/material.dart';
import 'bmi_calculator.dart';
import 'bmi_history.dart';

class BmiTrackerScreen extends StatelessWidget {
  const BmiTrackerScreen({super.key});

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
        ),
        body: const TabBarView(
          children: [
            BmiCalculatorScreen(), // Show Calculator
            BmiHistoryScreen(),     // Show History
          ],
        ),
      ),
    );
  }
}