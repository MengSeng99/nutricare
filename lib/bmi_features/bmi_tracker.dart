import 'package:flutter/material.dart';
import 'bmi_calculator.dart';
import 'bmi_history.dart';

class BmiTrackerScreen extends StatefulWidget {
  const BmiTrackerScreen({super.key});

  @override
  _BmiTrackerScreenState createState() => _BmiTrackerScreenState();
}

class _BmiTrackerScreenState extends State<BmiTrackerScreen> {
  bool _isCalculatorTab = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'BMI Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243), // AppBar color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Back navigation
          },
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton('Calculator', isSelected: _isCalculatorTab, onTap: () {
                setState(() {
                  _isCalculatorTab = true;
                });
              }),
              _buildTabButton('History', isSelected: !_isCalculatorTab, onTap: () {
                setState(() {
                  _isCalculatorTab = false;
                });
              }),
            ],
          ),
          Expanded(
            child: _isCalculatorTab
                ? const BmiCalculatorScreen() // Show Calculator
                : const BmiHistoryScreen(),   // Show History
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Column(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color.fromARGB(255, 90, 113, 243) : Colors.grey,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 0.0),
                height: 2.0,
                width: text.length * 8.0,
                color: const Color.fromARGB(255, 90, 113, 243),
              ),
          ],
        ),
      ),
    );
  }
}
