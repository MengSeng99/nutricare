import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for user ID
import 'booking.dart';
import 'specialist_lists.dart';
import 'package:url_launcher/url_launcher.dart';

class SpecialistDetailsScreen extends StatefulWidget {
  final Specialist specialist;

  const SpecialistDetailsScreen({super.key, required this.specialist});

  @override
  _SpecialistDetailsScreenState createState() => _SpecialistDetailsScreenState();
}

class _SpecialistDetailsScreenState extends State<SpecialistDetailsScreen> {
  late Future<DocumentSnapshot> _specialistData;
  late String currentUserId;
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    _specialistData = _fetchSpecialistData();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    isFavorite = widget.specialist.isFavorite;
  }

  Future<DocumentSnapshot> _fetchSpecialistData() async {
    final specialistId = widget.specialist.id;
    return await FirebaseFirestore.instance
        .collection('specialists')
        .doc(specialistId)
        .get();
  }

  Future<void> _updateFavoriteStatus(Specialist specialist) async {
    final userFavoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('favorite_specialist_lists');

    setState(() {
      isFavorite = !isFavorite; // Toggle favorite state
    });

    if (isFavorite) {
      await userFavoritesRef.doc(specialist.id).set({
        'name': specialist.name,
        'specialization': specialist.specialization,
        'organization': specialist.organization,
        'profile_picture_url': specialist.profilePictureUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Successfully added Dr. ${specialist.name} to favorites.')));
    } else {
      await userFavoritesRef.doc(specialist.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Successfully removed Dr. ${specialist.name} from favorites.')));
    }
  }

  Future<void> _launchGoogleMapsSearch(String organization) async {
    final query = Uri.encodeComponent(organization);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    
    // Check if the URL can be launched
    if (await canLaunch(url)) {
      await launch(url); // Launch the Google Maps search in the browser or Maps app
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final specialist = widget.specialist;

    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: _specialistData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading data'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Specialist data not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final experienceYears = (data['experience_years'] is int)
              ? (data['experience_years'] as int).toDouble()
              : (data['experience_years'] ?? 0.0);
          final services = List<Map<String, dynamic>>.from(data['services']);
          final reviews = List<Map<String, dynamic>>.from(data['reviews']);
          final about = data['about'] ?? 'No details available';

          final rating = _calculateAverageRating(reviews);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300.0,
                floating: false,
                pinned: true,
                leading: _buildCustomBackButton(),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    "Dr. ${specialist.name}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          specialist.profilePictureUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                specialist.specialization,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Color.fromARGB(255, 90, 113, 243)),
                                  const SizedBox(width: 5),
                                  // Organization name as a hyperlink
                                  InkWell(
                                    onTap: () {
                                      _launchGoogleMapsSearch(
                                          specialist.organization);
                                    },
                                    child: Text(
                                      specialist.organization,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color.fromARGB(255, 90, 113, 243),
                                        decoration: TextDecoration.underline, // Underline to indicate a link
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.blue : Colors.grey,
                              size: 30,
                            ),
                            onPressed: () async {
                              await _updateFavoriteStatus(specialist);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.work_outline,
                              label: 'Experience',
                              value: '${experienceYears.toStringAsFixed(1)} Years',
                              iconColor: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.star,
                              label: 'Rating',
                              value: '${rating.toStringAsFixed(1)} / 5.0',
                              iconColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'About Dr. ${specialist.name}:',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // "About" section retrieved from Firestore
                      Text(
                        about,
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 20),

                      _buildServiceList(services),

                      const SizedBox(height: 20),

                      _buildReviewsSection(reviews),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingScreen(
                    specialistName: specialist.name,
                    specialistId: specialist.id, // Pass the specialistId
                  ),
                ),
              );
            },
            child: const Text(
              'Book Appointment',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // Function to calculate the average rating from the reviews
  double _calculateAverageRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0.0; // No reviews, return 0.0

    double totalRating = 0;
    for (var review in reviews) {
      final rating = (review['rating'] is int)
          ? (review['rating'] as int).toDouble()
          : review['rating'];
      totalRating += rating;
    }

    return totalRating / reviews.length;
  }

  // Helper method to build modern service list with a numbered counter
  Widget _buildServiceList(List<Map<String, dynamic>> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services & Fees:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < services.length; i++)
          _buildServiceCard(i + 1, services[i]['name'], '\$${services[i]['fee']}'),
      ],
    );
  }

  // Updated method to build individual service card without icons, but with a numbered counter
  Widget _buildServiceCard(int index, String serviceName, String fee) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Counter number in front of the service name
            Text(
              '$index. ', // Display the number (1. 2. 3. etc.)
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(
                serviceName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              fee,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build modern reviews section
  Widget _buildReviewsSection(List<Map<String, dynamic>> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        for (var review in reviews)
          _buildReviewCard(review['reviewer_name'], review['review'], (review['rating'] is int) ? (review['rating'] as int).toDouble() : review['rating']),
      ],
    );
  }

  // Helper method to build individual review card with modern design
  Widget _buildReviewCard(String reviewerName, String review, double rating) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // Review details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reviewerName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    review,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Rating with stars
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create custom back button
  Widget _buildCustomBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Colors.white, // White background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 10px radius
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.arrow_back, // Back icon
              color: Colors.blue, // Blue color for the icon
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to map Firestore icon strings to Flutter Icons
  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'medical_services':
        return Icons.medical_services;
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'calendar_today':
        return Icons.calendar_today;
      default:
        return Icons.help_outline;
    }
  }

  // Helper method to create info cards (for Experience and Rating)
  Widget _buildInfoCard(
      {required IconData icon,
      required String label,
      required String value,
      required Color iconColor}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 40),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
