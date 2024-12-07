import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for user ID
import '../booking_appointment/booking.dart';
import 'package:url_launcher/url_launcher.dart';

class SpecialistDetailsScreen extends StatefulWidget {
  final String specialistId; // Updated class to accept only the ID

  const SpecialistDetailsScreen({super.key, required this.specialistId});

  @override
  _SpecialistDetailsScreenState createState() =>
      _SpecialistDetailsScreenState();
}

class _SpecialistDetailsScreenState extends State<SpecialistDetailsScreen> {
  late Future<DocumentSnapshot> _specialistData; // Future to hold specialist data
  late String currentUserId;
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    _specialistData = _fetchSpecialistData(); // Fetch specialist data upon initialization
    currentUserId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
    isFavorite = false; // Initialize to false
  }

  Future<DocumentSnapshot> _fetchSpecialistData() async {
    // Fetch specialist data from Firestore based on the specialist ID
    return await FirebaseFirestore.instance
        .collection('specialists')
        .doc(widget.specialistId)
        .get()
        .then((doc) async {
          if (doc.exists) {
            // Check if the specialist is a favorite
            isFavorite = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .collection('favorite_specialist_lists')
                .doc(widget.specialistId)
                .get()
                .then((value) => value.exists);
          }
          return doc;
        });
  }

  Future<void> _updateFavoriteStatus() async {
    final userFavoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('favorite_specialist_lists');

    setState(() {
      isFavorite = !isFavorite; // Toggle favorite state
    });

    if (isFavorite) {
      await userFavoritesRef.doc(widget.specialistId).set({
        'id': widget.specialistId,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Successfully added to favorites.')));
    } else {
      await userFavoritesRef.doc(widget.specialistId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Successfully removed from favorites.')));
    }
  }

  Future<void> _launchGoogleMapsSearch(String organization) async {
    final query = Uri.encodeComponent(organization);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';

    // Check if the URL can be launched
    if (await canLaunch(url)) {
      await launch(url); // Launch Google Maps search
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
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

          final specialist = snapshot.data!.data() as Map<String, dynamic>;
          final experienceYears = (specialist['experience_years'] is int)
              ? (specialist['experience_years'] as int).toDouble()
              : (specialist['experience_years'] ?? 0.0);

          // Ensure reviews defaults to an empty list if it's null
          final services = List<Map<String, dynamic>>.from(specialist['services'] ?? []);
          final reviews = List<Map<String, dynamic>>.from(specialist['reviews'] ?? []);
          final about = specialist['about'] ?? 'No details available';

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
                    "Dr. ${specialist['name']}",
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
                          specialist['profile_picture_url'],
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
                                specialist['specialization'],
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Color.fromARGB(255, 90, 113, 243)),
                                  const SizedBox(width: 5),
                                  GestureDetector(
                                    onTap: () {
                                      _launchGoogleMapsSearch(specialist['organization']);
                                    },
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 200),
                                      child: Text(
                                        specialist['organization'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color.fromARGB(255, 90, 113, 243),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Color.fromARGB(255, 90, 113, 243) : Colors.grey,
                              size: 30,
                            ),
                            onPressed: () async {
                              await _updateFavoriteStatus();
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
                              iconColor: Color.fromARGB(255, 90, 113, 243),
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
                        'About Dr. ${specialist['name']}:',
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
      bottomNavigationBar: FutureBuilder<DocumentSnapshot>(
        future: _specialistData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink(); // Return an empty widget or wait indicator
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const SizedBox.shrink(); // Handle error or no data case
          }

          final specialistData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
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
                        specialistName: specialistData['name'],
                        specialistId: widget.specialistId, // Pass the specialist ID
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
          );
        },
      ),
    );
  }

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
          _buildServiceCard(i + 1, services[i]['name'], 'RM ${services[i]['fee']}'),
      ],
    );
  }

  Widget _buildServiceCard(int index, String serviceName, String fee) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Text(
              '$index. ',
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

  Widget _buildReviewsSection(List<Map<String, dynamic>> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (reviews.isEmpty)
          const Text(
            'No reviews yet.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          )
        else
          for (var review in reviews)
            _buildReviewCard(
                review['reviewer_name'],
                review['review'],
                (review['rating'] is int)
                    ? (review['rating'] as int).toDouble()
                    : review['rating']),
      ],
    );
  }

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

  Widget _buildCustomBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.arrow_back,
              color: Color.fromARGB(255, 90, 113, 243),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
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