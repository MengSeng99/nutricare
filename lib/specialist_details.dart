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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
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
                  // Specialization and Location Information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            specialist.specialization,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color.fromARGB(255, 90, 113, 243)),
                              const SizedBox(width: 5),
                              Text(
                                specialist.organization,
                                style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 90, 113, 243)),
                              ),
                            ],
                          ),
                        ],
                      ),
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

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.work_outline,
                          label: 'Experience',
                          value: '10+ Years',
                          iconColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.star,
                          label: 'Rating',
                          value: '4.8 / 5.0',
                          iconColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'About Dr. ${specialist.name}:',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Dr. ${specialist.name} is a highly experienced ${specialist.specialization} with over 10 years of expertise. They specialize in personalized care '
                    'and are known for their holistic approach to health. At ${specialist.organization}, Dr. ${specialist.name} leads a team of professionals to deliver '
                    'exceptional service to their clients.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  // Modern Service & Fees Section
                  _buildServiceList(),

                  const SizedBox(height: 20),

                  // Modern Reviews Section
                  _buildReviewsSection(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
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
                  builder: (context) => BookingScreen(specialistName: specialist.name),
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
    );
  }

  // Helper method to build modern service list with cards and icons
  Widget _buildServiceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services & Fees:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildServiceCard('Personalized Consultation', '\$100', Icons.medical_services),
        _buildServiceCard('Diet Planning', '\$80', Icons.restaurant_menu),
        _buildServiceCard('Follow-up Consultation', '\$50', Icons.calendar_today),
      ],
    );
  }

  // Helper method to build individual service card with modern design
  Widget _buildServiceCard(String serviceName, String fee, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.blue),
            const SizedBox(width: 12),
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
  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildReviewCard('John Doe', 'Excellent service, very thorough and professional.', 5.0),
        _buildReviewCard('Jane Smith', 'Highly recommend! Personalized plans that really work.', 4.8),
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

  // Helper method to create info cards (for Experience and Rating)
  Widget _buildInfoCard({required IconData icon, required String label, required String value, required Color iconColor}) {
    return Card(
      elevation: 6,
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
