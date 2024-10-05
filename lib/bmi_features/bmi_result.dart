import 'package:flutter/material.dart';

class BmiResultScreen extends StatelessWidget {
  final double bmi;
  final double height;
  final double weight;
  final int age;
  final bool isMale;

  const BmiResultScreen({
    super.key,
    required this.bmi,
    required this.height,
    required this.weight,
    required this.age,
    required this.isMale,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the BMI category and color based on the BMI value
    String bmiCategory;
    Color bmiColor;

    if (bmi < 18.5) {
      bmiCategory = 'Underweight';
      bmiColor = Colors.blue;
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      bmiCategory = 'Normal weight';
      bmiColor = Colors.green;
    } else if (bmi >= 25.0 && bmi <= 29.9) {
      bmiCategory = 'Pre-obesity';
      bmiColor = Colors.orange;
    } else if (bmi >= 30.0 && bmi <= 34.9) {
      bmiCategory = 'Obesity class I';
      bmiColor = Colors.red;
    } else if (bmi >= 35.0 && bmi <= 39.9) {
      bmiCategory = 'Obesity class II';
      bmiColor = Colors.red.shade700;
    } else {
      bmiCategory = 'Obesity class III';
      bmiColor = Colors.red.shade900;
    }

    // Calculate the ideal weight range (BMI between 18.5 to 24.9)
    double minHeightInMeters = height / 100;
    double minWeight = 18.5 * (minHeightInMeters * minHeightInMeters);
    double maxWeight = 24.9 * (minHeightInMeters * minHeightInMeters);

    // Get current date and time
    String formattedDate = DateTime.now().toLocal().toString().split(' ')[0];
    String formattedTime = TimeOfDay.now().format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BMI Result',
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85, // Make container wider
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 3,
                  blurRadius: 7,
                  offset: const Offset(0, 3), // Shadow position
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Your BMI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                // Display the calculated BMI value
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: bmiColor,
                  ),
                ),
                const SizedBox(height: 10),
                // Display additional details like gender, height, weight, and age
                Text(
                  '${isMale ? "Male" : "Female"} | ${height.toStringAsFixed(1)}CM | ${weight.toStringAsFixed(1)}KG | ${age}yr old',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                // Display the BMI category and description
                Text(
                  'You are $bmiCategory',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: bmiColor,
                  ),
                ),
                const SizedBox(height: 20),
                // Display the ideal weight range only if the BMI is not in the "Normal weight" category
                if (bmiCategory != 'Normal weight')
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        const TextSpan(text: 'Your ideal weight is '),
                        TextSpan(
                          text: '${minWeight.toStringAsFixed(1)} - ${maxWeight.toStringAsFixed(1)} KG',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                // Display the date and time of calculation
                Text(
                  '- $formattedDate | $formattedTime -',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                // Button to add the result to BMI Tracking
                ElevatedButton(
                  onPressed: () {
                    // Print BMI details to the console when the button is clicked
                    print(
                      'BMI: ${bmi.toStringAsFixed(1)}\n'
                      'Gender: ${isMale ? "Male" : "Female"}\n'
                      'Height (CM): ${height.toStringAsFixed(1)}\n'
                      'Weight (KG): ${weight.toStringAsFixed(1)}\n'
                      'Age (Years): $age\n'
                      'Classification: $bmiCategory\n'
                      'Ideal Weight (KG): ${minWeight.toStringAsFixed(1)} - ${maxWeight.toStringAsFixed(1)}\n'
                      'Date: $formattedDate\n'
                      'Time: $formattedTime'
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 24.0, // Increase horizontal padding
                    ),
                  ),
                  child: const Text(
                    'Add to BMI Tracking',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
