import 'package:flutter/material.dart';
import 'booking.dart'; // Import the new booking screen
import 'specialist_lists.dart'; // Import the Specialist model

class SpecialistDetailsScreen extends StatefulWidget {
  final Specialist specialist;

  const SpecialistDetailsScreen({super.key, required this.specialist});

  @override
  _SpecialistDetailsScreenState createState() => _SpecialistDetailsScreenState();
}

class _SpecialistDetailsScreenState extends State<SpecialistDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final specialist = widget.specialist;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100.0), // Adjust bottom padding to make space for the button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Profile Picture and Basic Info
                Stack(
                  children: [
                    // Background Image (Profile Picture)
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(specialist.profilePictureUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Gradient Overlay
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    // Back Button Positioned at Top Left
                    Positioned(
                      top: 20,
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    // Specialist Name
                    Positioned(
                      bottom: 20,
                      left: 16,
                      child: Text(
                        "Dr. ${specialist.name}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // Main Content Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Specialization and Location Information
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                specialist.specialization,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color.fromARGB(255, 90, 113, 243)),
                                  const SizedBox(width: 5),
                                  Text(
                                    specialist.organization,
                                    style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 90, 113, 243), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Favorite Toggle Button
                          IconButton(
                            icon: Icon(
                              specialist.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: specialist.isFavorite ? Colors.blue : Colors.grey,
                              size: 30,
                            ),
                            onPressed: () {
                              setState(() {
                                specialist.isFavorite = !specialist.isFavorite;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Experience and Rating Cards
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    const Icon(Icons.work_outline, color: Color.fromARGB(255, 90, 113, 243), size: 40),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Experience',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '10+ Years',
                                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    const Icon(Icons.star_outline, color: Colors.orange, size: 40),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Rating',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '4.8 / 5.0',
                                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // About Section
                      Text(
                        'About Dr. ${specialist.name}:',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Dr. ${specialist.name} is a highly experienced ${specialist.specialization} with over 10 years of expertise in the field of nutrition. '
                        'They have helped hundreds of clients achieve their health goals through personalized meal planning and consultations. '
                        'At ${specialist.organization}, Dr. ${specialist.name} works with a dedicated team to provide the best care possible.',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Positioned Book Appointment Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8.0,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to Booking Screen and pass the specialist's name
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(specialistName: specialist.name), // Pass specialist's name
                      ),
                    );
                  },
                  child: const Text(
                    'Book Appointment',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
