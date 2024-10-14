import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bmi_result.dart'; // Import the BMI result screen

class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  _BmiCalculatorScreenState createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen> {
  double _height = 170.0;
  double _weight = 60.0;
  int _age = 25;
  bool _isMaleSelected = true; // Gender selection

  // Controllers for height, weight, and age input fields
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _weightController.text = _weight.toStringAsFixed(2); // Initialize weight controller
    _ageController.text = _age.toString(); // Initialize age controller
    _heightController.text = _height.toStringAsFixed(1); // Initialize height controller
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    _weightController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 0),
              // Gender Selection Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGenderButton('Male', Icons.male, _isMaleSelected, () {
                    setState(() {
                      _isMaleSelected = true;
                    });
                  }),
                  const SizedBox(width: 20), // Adjust this value to control space
                  _buildGenderButton('Female', Icons.female, !_isMaleSelected, () {
                    setState(() {
                      _isMaleSelected = false;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 10),

              // Height Input Box with Slider
              _buildHeightInputBox(),
              const SizedBox(height: 10),

              // Weight and Age Input Sections
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildWeightInputBox()), // Updated weight box
                  const SizedBox(width: 16), // Add space between the two boxes
                  Expanded(child: _buildAgeInputBox()),
                ],
              ),
              const SizedBox(height: 10),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  // Calculate BMI
                  double heightInMeters = _height / 100;
                  double bmi = _weight / (heightInMeters * heightInMeters);
                  
                  // Navigate to BmiResultScreen with calculated values
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BmiResultScreen(
                        bmi: bmi,
                        height: _height,
                        weight: _weight,
                        age: _age,
                        isMale: _isMaleSelected,
                      ),
                    ),
                  );
                },
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

  // Helper method to create gender selection buttons
  Widget _buildGenderButton(String gender, IconData icon, bool isSelected, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 170,
        height: 140,
        decoration: BoxDecoration(
          color: isSelected ? const Color.fromARGB(255, 240, 240, 255) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color.fromARGB(255, 90, 113, 243) : Colors.grey,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSelected ? 70 : 60, // Scale icon if selected
              color: isSelected ? (gender == 'Female' ? Colors.pink : Colors.blue) : Colors.grey,
            ),
            const SizedBox(height: 5),
            Text(
              gender,
              style: TextStyle(
                fontSize: isSelected ? 20 : 18, // Scale text if selected
                fontWeight: FontWeight.bold,
                color: isSelected ? (gender == 'Female' ? Colors.pink : Colors.blue) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create the height input box with a slider and text field
  Widget _buildHeightInputBox() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Height',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 1),
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?')),
            ],
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0.0',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            onSubmitted: (text) {
              setState(() {
                _height = double.tryParse(text) ?? _height;
                _heightController.text = _height.toStringAsFixed(1);
              });
            },
          ),
          const Text('CM', style: TextStyle(fontSize: 16, color: Colors.grey)),
          Slider(
            value: _height,
            min: 50.0,
            max: 250.0,
            divisions: 200,
            label: _height.toStringAsFixed(1),
            onChanged: (newValue) {
              setState(() {
                _height = newValue;
                _heightController.text = _height.toStringAsFixed(1); // Update text field with slider value
              });
            },
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.grey,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    if (_height > 50) {
                      _height--;
                      _heightController.text = _height.toStringAsFixed(1);
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    if (_height < 250) {
                      _height++;
                      _heightController.text = _height.toStringAsFixed(1);
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to create the weight input box with buttons
  Widget _buildWeightInputBox() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Weight',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 1),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?')),
            ],
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0.0',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            onSubmitted: (text) {
              setState(() {
                _weight = double.tryParse(text) ?? _weight;
                _weightController.text = _weight.toStringAsFixed(1);
              });
            },
          ),
          const Text('KG', style: TextStyle(fontSize: 16, color: Colors.grey)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    if (_weight > 1) {
                      _weight--;
                      _weightController.text = _weight.toStringAsFixed(1);
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _weight++;
                    _weightController.text = _weight.toStringAsFixed(1);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to create the age input box with buttons
  Widget _buildAgeInputBox() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Age',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 1),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}')),
            ],
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            onSubmitted: (text) {
              setState(() {
                _age = int.tryParse(text) ?? _age;
                _ageController.text = _age.toString();
              });
            },
          ),
          const Text('Years Old', style: TextStyle(fontSize: 16, color: Colors.grey)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    if (_age > 1) {
                      _age--;
                      _ageController.text = _age.toString();
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _age++;
                    _ageController.text = _age.toString();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
