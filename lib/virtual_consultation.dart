import 'package:flutter/material.dart';
import 'specialist_lists.dart';

class VirtualConsultationScreen extends StatelessWidget {
  const VirtualConsultationScreen({super.key});

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

  // Build the consultation boxes in a vertical list
  Widget _buildConsultationList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _consultations.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Navigate to booking appointment screen with the selected title
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
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildConsultationBox(
              _consultations[index]['image'],
              _consultations[index]['title'],
              _consultations[index]['description'],
            ),
          ),
        );
      },
    );
  }

  // Function to create individual consultation boxes
  Widget _buildConsultationBox(String imagePath, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // Shadow position
          ),
        ],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 10), // Space between image and title
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6), // Space between title and description
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
      appBar: AppBar(
        title: const Text(
          'Virtual Consultation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.white,
        child: _buildConsultationList(context),
      ),
    );
  }
}
