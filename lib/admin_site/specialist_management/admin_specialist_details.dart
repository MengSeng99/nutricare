import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_edit_specialist.dart';
import 'admin_specialist_appointment.dart';

class AdminSpecialistsDetailsScreen extends StatefulWidget {
  final String specialistId;

  const AdminSpecialistsDetailsScreen({super.key, required this.specialistId});

  @override
  _AdminSpecialistsDetailsScreenState createState() => _AdminSpecialistsDetailsScreenState();
}

class _AdminSpecialistsDetailsScreenState extends State<AdminSpecialistsDetailsScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  late Map<String, dynamic> specialistData = {};
  late TabController _tabController;
  List<dynamic> services = [];
  List<dynamic> reviews = [];
  bool showEditIcon = true;
  String deactivationDate = '';

  @override
  void initState() {
    super.initState();
    fetchSpecialistData();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes
    _tabController.addListener(() {
      setState(() {
        showEditIcon = _tabController.index == 0 && specialistData['status'] != 'inactive';
      });
    });
  }

  void fetchSpecialistData() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('specialists')
        .doc(widget.specialistId)
        .get();

    if (snapshot.exists) {
      setState(() {
        specialistData = snapshot.data() as Map<String, dynamic>;
        services = specialistData['services'] ?? [];
        reviews = specialistData['reviews'] ?? [];
        
        // Check if the specialist is inactive and get the deactivation date
        if (specialistData['status'] == 'inactive') {
          Timestamp? deactivationTimestamp = specialistData['deactivation_datetime'] as Timestamp?;
          if (deactivationTimestamp != null) {
            deactivationDate = deactivationTimestamp.toDate().toLocal().toString().split(' ')[0];
          }
        }

        isLoading = false; 
      });
    } else {
      setState(() {
        specialistData = {};
        services = [];
        reviews = [];
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check for inactive status
    bool isInactive = specialistData['status'] == 'inactive';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Specialist Details",
          style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color.fromARGB(255, 90, 113, 243),
          labelColor: Color.fromARGB(255, 90, 113, 243),
          tabs: [
            const Tab(text: 'Details'),
            Tab(text: isInactive ? 'Appointment Slots (Inactive)' : 'Appointment Slots'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 90, 113, 243)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (!isInactive && showEditIcon) // Show edit icon only for active specialists
            IconButton(
              icon: const Icon(Icons.edit, color: Color.fromARGB(255, 90, 113, 243)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditSpecialistScreen(
                      specialistId: widget.specialistId,
                      specialistData: specialistData,
                    ),
                  ),
                ).then((_) {
                  fetchSpecialistData();
                });
              },
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // First Tab for Specialist Details
          _buildDetailsTab(isInactive), // Pass inactive status to details tab
          // Second Tab for Appointments
          isInactive ? _buildInactiveAppointmentMessage() : SpecialistAppointmentsScreen(specialistId: widget.specialistId),
        ],
      ),
    );
  }

  // Method to build the details tab view
  Widget _buildDetailsTab(bool isInactive) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture and name section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: (specialistData['profile_picture_url'] != null &&
                              specialistData['profile_picture_url'].isNotEmpty)
                          ? NetworkImage(specialistData['profile_picture_url'])
                          : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Dr. ${specialistData['name'] ?? 'No Name'}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (isInactive) // Show inactive message if applicable
                      Text(
                        'This specialist is no longer serving starting from $deactivationDate.',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey[300]),

              // Specialist Details
              _buildInfoRow(Icons.email, 'Email', specialistData['email'] ?? 'No Email'),
              _buildInfoRow(Icons.business, 'Organization', specialistData['organization'] ?? 'N/A'),
              _buildInfoRow(Icons.access_time, 'Experience',
                  specialistData['experience_years'] != null ? '${specialistData['experience_years']} years' : 'N/A'),
              _buildInfoRow(Icons.person, 'Gender', specialistData['gender'] ?? 'N/A'),
              const SizedBox(height: 20),

              // About Section
              const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                specialistData['about'] ?? 'No Information Available',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 20),

              // Services Section
              _buildSectionHeader(Icons.medical_services, 'Services'),
              if (services.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No services added yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                )
              else ...services.map((service) {
                final serviceFee = service['fee'] ?? 'N/A';
                final serviceName = service['name'] ?? 'Unnamed Service';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(serviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Fee: RM $serviceFee', style: const TextStyle(color: Colors.grey)),
                  ),
                );
              }),

              const SizedBox(height: 20),
              // Reviews Section
              _buildSectionHeader(Icons.rate_review, 'Reviews'),
              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No reviews available yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                )
              else ...reviews.map((review) {
                String reviewDate;
                if (review['date'] is Timestamp) {
                  reviewDate = (review['date'] as Timestamp).toDate().toLocal().toString().split(' ')[0];
                } else if (review['date'] is String) {
                  reviewDate = review['date'];
                } else {
                  reviewDate = 'N/A';
                }

                final reviewerName = review['reviewer_name'] ?? 'Anonymous';
                final reviewText = review['review'] ?? 'No Review';
                final rating = review['rating'] ?? 'N/A';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(reviewerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: $reviewDate', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        Text('Rating: $rating / 5', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(reviewText, style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Method to build a message when appointment slots are inactive
  Widget _buildInactiveAppointmentMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'This specialist is inactive and cannot accept new appointments.',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color.fromARGB(255, 90, 113, 243)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Expanded(
            child: Tooltip(
              message: value,
              child: Text(
                value,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.visible,
                maxLines: 2,
                softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 90, 113, 243)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}