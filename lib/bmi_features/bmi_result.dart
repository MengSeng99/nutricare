import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'bmi_tracker.dart'; // Import the BmiTrackerScreen

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

  void _showBmiClassification(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BMI Classification',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color.fromARGB(255, 90, 113, 243),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              
              const Divider(thickness: 1, color: Colors.grey),
              
              // Make the DataTable scrollable
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Category',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'BMI Range',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                  rows: const [
                    DataRow(cells: [
                      DataCell(Text('Underweight')),
                      DataCell(Text('< 18.5')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Normal weight')),
                      DataCell(Text('18.5 - 22.9')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Pre-obesity')),
                      DataCell(Text('23.0 - 24.9')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Obesity class I')),
                      DataCell(Text('25.0 - 29.9')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Obesity class II')),
                      DataCell(Text('>= 30')),
                    ]),
                  ],
                  dataRowHeight: 50, // Adjust row height for better spacing`
                ),
              ),

              const SizedBox(height: 20),

              // Close Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    // Determine the BMI category and color based on the BMI value
    String bmiCategory;
    Color bmiColor;

    if (bmi < 18.5) {
      bmiCategory = 'Underweight';
      bmiColor = Colors.blue;
    } else if (bmi >= 18.5 && bmi <= 22.9) {
      bmiCategory = 'Normal weight';
      bmiColor = Colors.green;
    } else if (bmi >= 23.0 && bmi <= 24.9) {
      bmiCategory = 'Pre-obesity';
      bmiColor = Colors.orange;
    } else if (bmi >= 25.0 && bmi <= 29.9) {
      bmiCategory = 'Obesity class I';
      bmiColor = Colors.red;
    } else {
      bmiCategory = 'Obesity class II';
      bmiColor = Colors.red.shade700;
    } 

    // Calculate the ideal weight range (BMI between 18.5 to 22.9)
    double minHeightInMeters = height / 100;
    double minWeight = 18.5 * (minHeightInMeters * minHeightInMeters);
    double maxWeight = 22.9 * (minHeightInMeters * minHeightInMeters);

    // Get current date and time
    String formattedDate = DateTime.now().toLocal().toString().split(' ')[0];
    String formattedTime = TimeOfDay.now().format(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Your BMI Result",
          style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 90, 113, 243)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color.fromARGB(255, 90, 113, 243)),
            onPressed: () => _showBmiClassification(context), // Show classification on press
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 3,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: bmiColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${isMale ? "Male" : "Female"} | ${height.toStringAsFixed(1)}CM | ${weight.toStringAsFixed(1)}KG | ${age}yr old',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You are $bmiCategory',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: bmiColor,
                  ),
                ),
                const SizedBox(height: 20),
                if (bmiCategory != 'Normal weight')
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 18, color: Colors.black),
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
                Text(
                  '- $formattedDate | $formattedTime -',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    // Get the current user from Firebase Auth
                    User? user = FirebaseAuth.instance.currentUser;

                    if (user != null) {
                      String userId = user.uid;

                      try {
                        // Create a reference to the user's document in Firestore
                        DocumentReference userDocRef = FirebaseFirestore.instance
                            .collection('bmi-tracker')
                            .doc(userId);

                        // Add a new BMI record inside the bmi-records collection
                        await userDocRef.collection('bmi-records').add({
                          'bmi': bmi.toStringAsFixed(1),
                          'height': height.toStringAsFixed(1),
                          'weight': weight.toStringAsFixed(1),
                          'age': age,
                          'gender': isMale ? "Male" : "Female",
                          'bmiCategory': bmiCategory,
                          'idealWeightRange': '${minWeight.toStringAsFixed(1)} - ${maxWeight.toStringAsFixed(1)} KG',
                          'date': formattedDate,
                          'time': formattedTime,
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('BMI record added successfully!'),
                          backgroundColor: Colors.green,),
                        );

                        // Navigate to the BmiTrackerScreen and switch to History tab
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const BmiTrackerScreen()),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add BMI record: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No user is signed in')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 24.0,
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