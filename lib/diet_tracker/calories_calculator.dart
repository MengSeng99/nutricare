import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CaloriesCalculatorScreen extends StatefulWidget {
  const CaloriesCalculatorScreen({super.key});

  @override
  _CaloriesCalculatorScreenState createState() =>
      _CaloriesCalculatorScreenState();
}

class _CaloriesCalculatorScreenState extends State<CaloriesCalculatorScreen> {
  int age = 25;
  double weight = 70; // kg
  double height = 175; // cm
  String gender = 'Male';
  double caloricGoal = 0.0;
  bool isCalculated = false;
  String activityLevel = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> activityLevels = [
    'Sedentary (little or no exercise)',
    'Lightly active (light exercise/sports 1-3 days/week)',
    'Moderately active (moderate exercise/sports 3-5 days/week)',
    'Very active (hard exercise/sports 6-7 days a week)',
    'Super active (very hard exercise, physical job or training twice a day)',
  ];

  final Map<String, String> activityDescriptions = {
    'Sedentary (little or no exercise)':
        'You do not engage in any regular physical activity.',
    'Lightly active (light exercise/sports 1-3 days/week)':
        'You engage in light exercise or sports 1-3 times a week.',
    'Moderately active (moderate exercise/sports 3-5 days/week)':
        'You engage in moderate exercise or sports 3-5 times a week.',
    'Very active (hard exercise/sports 6-7 days a week)':
        'You engage in hard exercise or sports most days of the week.',
    'Super active (very hard exercise, physical job or training twice a day)':
        'You engage in very hard exercise, have a physical job, or train twice a day.',
  };

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _weightController.text = weight.toStringAsFixed(2);
    _ageController.text = age.toString();
    _heightController.text = height.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Calories Calculator',
            style: TextStyle(
                color: Color.fromARGB(255, 90, 113, 243),
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 90, 113, 243)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline,
                color: Color.fromARGB(255, 90, 113, 243)),
            onPressed: _showCalculationInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeightInputBox(),
              const SizedBox(height: 12),
              _buildWeightInputBox(),
              const SizedBox(height: 12),
              _buildAgeInputBox(),
              const SizedBox(height: 12),

              Text(
                'Activity Level',
                style: TextStyle(
                    fontSize: 18,
                    color: Color.fromARGB(255, 90, 113, 243),
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Activity Level Dropdown
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: activityLevel.isEmpty ? null : activityLevel,
                  items: activityLevels.map((String level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      activityLevel = value!;
                    });
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  isExpanded: true,
                ),
              ),
              const SizedBox(height: 10),

              if (activityLevel.isNotEmpty) ...[
                Text(
                  activityDescriptions[activityLevel] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _calculateCaloricGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  'Calculate',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeightInputBox() {
    return _buildInputBox(
      title: 'Height (cm)',
      controller: _heightController,
      value: height,
      onIncrease: () {
        if (height < 250) {
          setState(() {
            height++;
            _heightController.text = height.toStringAsFixed(1);
          });
        }
      },
      onDecrease: () {
        if (height > 50) {
          setState(() {
            height--;
            _heightController.text = height.toStringAsFixed(1);
          });
        }
      },
    );
  }

  Widget _buildWeightInputBox() {
    return _buildInputBox(
      title: 'Weight (kg)',
      controller: _weightController,
      value: weight,
      onIncrease: () {
        setState(() {
          weight++;
          _weightController.text = weight.toStringAsFixed(1);
        });
      },
      onDecrease: () {
        if (weight > 1) {
          setState(() {
            weight--;
            _weightController.text = weight.toStringAsFixed(1);
          });
        }
      },
    );
  }

  Widget _buildAgeInputBox() {
    return _buildInputBox(
      title: 'Age (years)',
      controller: _ageController,
      value: age.toDouble(),
      onIncrease: () {
        if (age < 120) {
          setState(() {
            age++;
            _ageController.text = age.toString();
          });
        }
      },
      onDecrease: () {
        if (age > 1) {
          setState(() {
            age--;
            _ageController.text = age.toString();
          });
        }
      },
    );
  }

  Widget _buildInputBox({
    required String title,
    required TextEditingController controller,
    required double value,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: onDecrease,
              ),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,3}(\.\d{0,1})?')),
                  ],
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.0',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: onIncrease,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _calculateCaloricGoal() {
    if (age > 0 && weight > 0 && height > 0 && activityLevel.isNotEmpty) {
      double bmr = (10 * weight) +
          (6.25 * height) -
          (5 * age) +
          (gender == 'Male' ? 5 : -161);

      double activityMultiplier = 1.2;

      switch (activityLevel) {
        case 'Lightly active (light exercise/sports 1-3 days/week)':
          activityMultiplier = 1.375;
          break;
        case 'Moderately active (moderate exercise/sports 3-5 days/week)':
          activityMultiplier = 1.55;
          break;
        case 'Very active (hard exercise/sports 6-7 days a week)':
          activityMultiplier = 1.725;
          break;
        case 'Super active (very hard exercise, physical job or training twice a day)':
          activityMultiplier = 1.9;
          break;
      }

      setState(() {
        caloricGoal = (bmr * activityMultiplier)
            .round()
            .toDouble(); // Calculate caloricGoal and round it correctly
        isCalculated = true;
      });

      _showCaloricGoalDialog();
    } else {
      _showIncompleteDataDialog();
    }
  }

  void _showCaloricGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Caloric Goal',
            style: TextStyle(
                color: Color.fromARGB(255, 90, 113, 243),
                fontWeight: FontWeight.bold)),
        content: Text(
          'Your Daily Caloric Goal: ${caloricGoal.toStringAsFixed(0)} kcal',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 90, 113, 243),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Set as Calorie Goal',
                style: TextStyle(color: Colors.white)),
            onPressed: () async {
              await _setCalorieGoal();
              Navigator.pop(context, caloricGoal.toInt()); // Pass the goal back
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Close',
                style: TextStyle(color: Color.fromARGB(255, 90, 113, 243))),
            onPressed: () {
              Navigator.of(context).pop(); // Just close the dialog
            },
          ),
        ],
      ),
    );
  }

  Future<void> _setCalorieGoal() async {
    User? user = _auth.currentUser; // Get the current user

    if (user != null) {
      String userId = user.uid; // Get the user ID

      await _firestore.collection('users').doc(userId).set({
        'calorieGoal': caloricGoal
            .toInt(), // Store rounded/calculated value without decimals
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Caloric Goal set successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently logged in.')),
      );
    }
  }

  void _showIncompleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Incomplete Data',
            style: TextStyle(
                color: Color.fromARGB(255, 90, 113, 243),
                fontWeight: FontWeight.bold)),
        content: const Text(
            'Please fill out all fields before calculating your caloric goal.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 90, 113, 243),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
            child: const Text(
              "Understood",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalculationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('How to Calculate Calories',
            style: TextStyle(
                color: Color.fromARGB(255, 90, 113, 243),
                fontWeight: FontWeight.bold)),
        content: const Text(
          'The Mifflin-St Jeor equation is used to calculate your Basal Metabolic Rate (BMR). '
          'Then, depending on your activity level, a multiplier is applied to estimate your daily caloric needs:\n\n'
          '1. Calculate BMR:\n'
          '   - For Men: BMR = (10 × weight) + (6.25 × height) - (5 × age) + 5\n'
          '   - For Women: BMR = (10 × weight) + (6.25 × height) - (5 × age) - 161\n\n'
          '2. Multiply BMR by the activity factor:\n'
          '   - Sedentary: BMR × 1.2\n'
          '   - Lightly active: BMR × 1.375\n'
          '   - Moderately active: BMR × 1.55\n'
          '   - Very active: BMR × 1.725\n'
          '   - Super active: BMR × 1.9',
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
              Navigator.of(context).pop(); // Dismiss the dialog
            },
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
