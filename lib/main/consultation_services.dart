import 'package:flutter/material.dart';
import '../specialist/specialist_lists.dart';

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

  // Show info dialog about the differences
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Nutritionist vs Dietitian',
          style: TextStyle(
            color: Color.fromARGB(255, 90, 113, 243),
            fontWeight: FontWeight.bold,
          ),
        ),
          content: const Text(
            '''Nutritionist: Generally, a nutritionist is a broader term that refers to someone who provides advice on food and nutrition. They may have varying levels of education and certification.
             
Dietitian: A dietitian is a trained healthcare professional who specializes in dietetics. They are usually required to obtain a degree in nutrition and dietetics, complete a supervised practice program, and pass a national examination. They are qualified to provide medical nutrition therapy and work in clinical settings to treat specific health conditions.''',
          ),
          actions: [
            ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 90, 113, 243),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

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
          'Consultation Services',
          style: TextStyle(color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color.fromARGB(255, 90, 113, 243)),
            onPressed: () => _showInfoDialog(context), // Show dialog on button press
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: _buildConsultationList(context),
      ),
    );
  }
}