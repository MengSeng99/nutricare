import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:nutricare/diets.dart';
import 'package:nutricare/food_recipe.dart';
import 'virtual_consultation.dart';
import 'specialist_lists.dart';
import 'bmi_features/bmi_tracker.dart';
import 'health_record.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Determine greeting based on the current time
  String _getGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    return greeting;
  }

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return userData['name'];
    }
    return 'Guest';
  }

  Future<String> _getGreetingWithUserName() async {
    final greeting = _getGreeting();
    final userName = await _getUserName();
    return '$greeting, $userName';
  }

  // List of services with icons and descriptions
  final List<Map<String, dynamic>> _services = const [
    {'icon': Icons.fastfood, 'label': 'Food Recipe'},
    // {'icon': Icons.restaurant_menu, 'label': 'Meal Tracking'},
    {'icon': Icons.calendar_today, 'label': 'Book an Appointment'},
    {'icon': Icons.monitor_weight_outlined, 'label': 'BMI Tracker'},
    {'icon': Icons.book, 'label': 'Health Records'},
  ];

  // List of consultation options with images and descriptions
  final List<Map<String, dynamic>> _consultations = const [
    {
      'image': 'images/dietitian.png',
      'title': 'Dietitian',
      'description': 'Get advice from certified dietitians on meal plans and dietary needs.',
    },
    {
      'image': 'images/nutritionist-2.png',
      'title': 'Nutritionist',
      'description': 'Consult with professional nutritionists for personalized diet guidance.',
    },
  ];

  // Build the horizontal services list
  Widget _buildServicesBar(BuildContext context) {
    return SizedBox(
      height: 113,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _services.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              if (_services[index]['label'] == 'Book an Appointment') {
              // Navigate to Virtual Consultation page when "Book an Appointment" is clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VirtualConsultationScreen()),
              );
              } else if (_services[index]['label'] == 'BMI Tracker') {
              // Navigate to BMI Tracker page when "BMI Tracker" is clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BmiTrackerScreen()),
              );
              } else if (_services[index]['label'] == 'Food Recipe') {
              // Navigate to BMI Tracker page when "Food Recipe" is clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FoodRecipeScreen()),
              );
              // } else if (_services[index]['label'] == 'Meal Tracking') {
              // // Navigate to BMI Tracker page when "Meal Tracking" is clicked
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const DietsScreen()),
              // );
              } else if (_services[index]['label'] == 'Health Records') {
              // Navigate to Health Records page when "Health Records" is clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HealthRecordScreen()),
              );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                children: [
                  // Icon container with a modern card-like design
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255), // Blue background
                      borderRadius: BorderRadius.circular(15), // Rounded corners for a modern look
                      border: Border.all(color: Colors.grey[300]!), // Light grey border
                    ),
                    child: Icon(
                      _services[index]['icon'],
                      color: const Color.fromARGB(255, 90, 113, 243), // White icon color
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 10), // Space between icon and text
                  // Label with modern style and text wrapping
                  SizedBox(
                    width: 80, // Ensure text wraps within the container
                    child: Text(
                      _services[index]['label'],
                      textAlign: TextAlign.center, // Center text
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      maxLines: 3, // Wrap text to max 2 lines
                      overflow: TextOverflow.ellipsis, // Show ellipsis if the text is too long
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Build the horizontal virtual consultation section
  Widget _buildConsultationBar(BuildContext context) {
    return SizedBox(
      height: 240, // Adjust height to fit the consultation boxes
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _consultations.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Navigate to BookingAppointmentScreen with the selected consultation title
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingAppointmentScreen(
                    title: _consultations[index]['title'],
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildConsultationBox(
                _consultations[index]['image'],
                _consultations[index]['title'],
                _consultations[index]['description'],
              ),
            ),
          );
        },
      ),
    );
  }

  // Function to create individual consultation boxes
  Widget _buildConsultationBox(String imagePath, String title, String description) {
    return Container(
      width: 230, // Adjust width of each consultation box
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!), // Light grey border for a clean look
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image
          Image.asset(
            imagePath,
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 10), // Space between image and title
          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6), // Space between title and description
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            maxLines: 3, // Ensure text wraps up to 3 lines
            overflow: TextOverflow.ellipsis, // Show ellipsis if text overflows
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _getGreetingWithUserName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                'Loading...',
                style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
              );
            } else if (snapshot.hasError) {
              return const Text(
                'Error',
                style: TextStyle(color: Color.fromARGB(255, 243, 90, 90), fontWeight: FontWeight.bold),
              );
            } else {
              return Text(
                snapshot.data ?? 'Hello',
                style: const TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
              );
            }
          },
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add the services bar to the top of the body
              _buildServicesBar(context),
              const SizedBox(height: 20), // Add some space between sections
              // Virtual Consultation Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Virtual Consultation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                    // Right arrow button to navigate to Virtual Consultation screen
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Color.fromARGB(255, 90, 113, 243)),
                      onPressed: () {
                        // Navigate to Virtual Consultation screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VirtualConsultationScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10), // Space between header and consultation list
              _buildConsultationBar(context), // Add the horizontal consultation bar
            ],
          ),
        ),
      ),
    );
  }
}
