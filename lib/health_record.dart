import 'package:flutter/material.dart';

class HealthRecordScreen extends StatefulWidget {
  const HealthRecordScreen({super.key});

  @override
  _HealthRecordScreenState createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  bool _isYourRecordsTab = true; // Track the active tab

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Record',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tab-like buttons for "Your Records" and "Uploads"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabButton(
                    'Your Records',
                    isSelected: _isYourRecordsTab,
                    onTap: () {
                      setState(() {
                        _isYourRecordsTab = true; // Set "Your Records" as active
                      });
                    },
                  ),
                  _buildTabButton(
                    'Uploads',
                    isSelected: !_isYourRecordsTab,
                    onTap: () {
                      setState(() {
                        _isYourRecordsTab = false; // Set "Uploads" as active
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20), // Space between tabs and content
              
              // Content based on selected tab
              _isYourRecordsTab ? _buildYourRecordsTabContent() : _buildUploadsTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  // Method to build the tab button with updated design
  Widget _buildTabButton(String text, {bool isSelected = false, required VoidCallback onTap}) {
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
                margin: const EdgeInsets.only(top: 4.0),
                height: 2.0,
                width: text.length * 8.0, // Adjust width based on text length
                color: const Color.fromARGB(255, 90, 113, 243),
              ),
          ],
        ),
      ),
    );
  }

  // Content for "Your Records" tab
  Widget _buildYourRecordsTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Display the image for "Your Records" tab
        Image.asset(
          'images/health-record-2.png', // Ensure this image path is correct
          width: 150, // Image width
          height: 150, // Image height
        ),
        const SizedBox(height: 20), // Space between image and text
        const Text(
          "You don't have any health records yet",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "If you do the health screening with us, this is where you can check your personalised report later. Alternatively, you can upload your health docs here.",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center, // Center the text
        ),
      ],
    );
  }

  // Content for "Uploads" tab
  Widget _buildUploadsTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Display the image for "Uploads" tab
        Image.asset(
          'images/health-record.png', // Ensure this image path is correct
          width: 150, // Image width
          height: 150, // Image height
        ),
        const SizedBox(height: 20), // Space between image and text
        const Text(
          "Upload and store your records at one place",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Optimise your experience on our app by uploading your health records.",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center, // Center the text
        ),
        const SizedBox(height: 30), // Space between text and button

        // Upload Health Records button
        ElevatedButton(
          onPressed: () {
            // Add functionality for uploading health records
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 90, 113, 243), // Button color
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), // Padding for button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
          ),
          child: const Text(
            'Upload Health Records',
            style: TextStyle(fontSize: 18, color: Colors.white), // Text color and size
          ),
        ),
      ],
    );
  }
}
