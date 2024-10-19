import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Sample specialist data
class Specialist {
  String name;
  String specialization;
  String organization;
  int experienceYears;
  double rating;
  String profilePictureUrl;
  String gender;

  Specialist({
    required this.name,
    required this.specialization,
    required this.organization,
    required this.experienceYears,
    required this.rating,
    required this.profilePictureUrl,
    required this.gender,
  });
}

class FirestoreTestPage extends StatelessWidget {
  const FirestoreTestPage({super.key});

  // Function to add a specialist to Firestore
  Future<void> addSpecialist(Specialist specialist) async {
    final specialistsRef = FirebaseFirestore.instance.collection('specialists');

    // Ensure specialization is valid
    if (specialist.specialization != 'Nutritionist' && specialist.specialization != 'Dietitian') {
      throw Exception('Specialization must be either Nutritionist or Dietitian.');
    }

    // Adding specialist data to Firestore
    await specialistsRef.add({
      'name': specialist.name,
      'specialization': specialist.specialization,
      'organization': specialist.organization,
      'experience_years': specialist.experienceYears,
      'rating': specialist.rating,
      'profile_picture_url': specialist.profilePictureUrl,
      'gender': specialist.gender,
      'services': [
        {'name': 'Personalized Consultation', 'fee': 100, 'icon': 'medical_services'},
        {'name': 'Diet Planning', 'fee': 80, 'icon': 'restaurant_menu'},
        {'name': 'Follow-up Consultation', 'fee': 50, 'icon': 'calendar_today'},
      ],
      'reviews': [
        {
          'reviewer_name': 'John Doe',
          'review': 'Excellent service, very thorough and professional.',
          'rating': 5.0,
          'date': '2023-10-15',
        },
        {
          'reviewer_name': 'Jane Smith',
          'review': 'Highly recommend! Personalized plans that really work.',
          'rating': 4.8,
          'date': '2023-10-10',
        },
      ],
    });

    print('Specialist added successfully!');
  }

  // Function to toggle favorite for a user
  Future<void> toggleFavorite(String userId, String specialistId, bool isFavorite) async {
    final favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(specialistId);

    if (isFavorite) {
      await favoritesRef.set({'specialistId': specialistId});
      print('Specialist marked as favorite.');
    } else {
      await favoritesRef.delete();
      print('Specialist removed from favorites.');
    }
  }

  // Sample test function to add specialist and favorite
  Future<void> runTest() async {
    // 1. Add a sample specialist
    Specialist sampleSpecialist = Specialist(
      name: 'Dr. Lisa Johnson',
      specialization: 'Dietitian',  // Can only be Nutritionist or Dietitian
      organization: 'Black Pink Clinic',
      experienceYears: 10,
      rating: 4.9,
      profilePictureUrl: 'https://cdn-bloha.nitrocdn.com/iYznGJZGanzaCCgxovUBGCyByrXxQITj/assets/images/optimized/rev-12377d1/www.weljii.com/wp-content/uploads/2024/06/apr-3.jpg',
      gender: 'Female',
    );

    // Add specialist to Firestore
    await addSpecialist(sampleSpecialist);

    // 2. Toggle favorite for a user (userId can be a dummy value for testing)
    String userId = 'khyNsOrkL8fQ0b8weOBZfcyHMOR2';  // Replace with actual userId
    String specialistId = 'CPzkFTpGAQnF2T2SsFP2';  // Replace with the actual specialist ID from Firestore

    // Mark as favorite
    await toggleFavorite(userId, specialistId, true);

    // Remove from favorites
    await toggleFavorite(userId, specialistId, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firestore Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await runTest();
          },
          child: const Text('Run Firestore Test'),
        ),
      ),
    );
  }
}
