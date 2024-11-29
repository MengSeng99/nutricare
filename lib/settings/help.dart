import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Help and FAQs',
          style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 240, 240, 250)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 90, 113, 243)),
              ),
              const SizedBox(height: 15),
              _buildFaqItem('How can I update my personal details?',
                  'Navigate to Personal Details in the Settings menu.'),
              const SizedBox(height: 10),
              _buildFaqItem('How do I add a new payment method?',
                  'Go to Payment Methods in the Settings menu.'),
              const SizedBox(height: 30),
              const Text(
                'Contact Us',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 90, 113, 243)),
              ),
              const SizedBox(height: 10),
              const Text(
                'For further assistance, please reach out to our support team:',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              _buildContactInfo('Email', 'support@nutricareapp.com'),
              const SizedBox(height: 5),
              _buildContactInfo('Phone', '+1 800 123 4567'),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build each FAQ item with a modern card layout
  Widget _buildFaqItem(String question, String answer) {
    return Card(
       color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 90, 113, 243)),
            ),
            const SizedBox(height: 5),
            Text(
              answer,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build contact info with an icon
  Widget _buildContactInfo(String title, String info) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              title == 'Email' ? Icons.email : Icons.phone,
              color: const Color.fromARGB(255, 90, 113, 243),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$title: $info',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
