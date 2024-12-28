import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// Admin screen to view specialist registration enquiries
class AdminSpecialistEnquiriesScreen extends StatefulWidget {
  const AdminSpecialistEnquiriesScreen({super.key});

  @override
  _AdminSpecialistEnquiriesScreenState createState() =>
      _AdminSpecialistEnquiriesScreenState();
}

class _AdminSpecialistEnquiriesScreenState
    extends State<AdminSpecialistEnquiriesScreen> {
  String filter = "All";

  void setFilter(String value) {
    setState(() {
      filter = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Specialist Enquiries",
          style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child:
              Divider(height: 0.5, color: Color.fromARGB(255, 220, 220, 241)),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("All"),
                  selected: filter == 'All',
                  onSelected: (selected) {
                    if (selected) setFilter('All');
                  },
                  selectedColor: const Color.fromARGB(255, 90, 113, 243),
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: filter == 'All'
                        ? Colors.white
                        : const Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(100), // Fully rounded corners
                    side: BorderSide(
                      color: filter == 'All'
                          ? const Color.fromARGB(255, 90, 113, 243)
                          : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                  labelPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0), // Padding around the text
                  elevation:
                      filter == 'All' ? 2 : 1, // Slight elevation when selected
                  pressElevation: 2, // More elevation on press
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Bookmarks"),
                  selected: filter == 'Bookmarked',
                  onSelected: (selected) {
                    if (selected) setFilter('Bookmarked');
                  },
                  selectedColor: const Color.fromARGB(255, 90, 113, 243),
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: filter == 'Bookmarked'
                        ? Colors.white
                        : const Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(100), // Fully rounded corners
                    side: BorderSide(
                      color: filter == 'Bookmarked'
                          ? const Color.fromARGB(255, 90, 113, 243)
                          : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                  labelPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0), // Padding around the text
                  elevation: filter == 'Bookmarked'
                      ? 2
                      : 1, // Slight elevation when selected
                  pressElevation: 2, // More elevation on press
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SpecialistEnquiry>>(
              stream: readSpecialistEnquiries(filter == 'Bookmarked'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Something went wrong: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final enquiries = snapshot.data!;

                // Check if the filter is 'Bookmarked' and there are no inquiries
                if (filter == 'Bookmarked' && enquiries.isEmpty) {
                  return Center(child: Text('No specialist enquiries added to your bookmark.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: enquiries.length,
                  itemBuilder: (context, index) {
                    final enquiry = enquiries[index];
                    return EnquiryCard(enquiry: enquiry);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<SpecialistEnquiry>> readSpecialistEnquiries(bool onlyBookmarked) {
    Query query = FirebaseFirestore.instance
        .collection('specialist_registration_enquiries')
        .orderBy('submitDate', descending: true); // Sort by submitDate

    if (onlyBookmarked) {
      query = query.where('bookmarked', isEqualTo: 1);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => SpecialistEnquiry.fromJson(
            doc.data() as Map<String, dynamic>,
            doc.id)) // Pass doc.id for the ID
        .toList());
  }
}

class EnquiryCard extends StatelessWidget {
  final SpecialistEnquiry enquiry;

  const EnquiryCard({super.key, required this.enquiry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Color.fromARGB(255, 221, 222, 226), width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(enquiry.profilePictureUrl),
                  backgroundColor: Color.fromARGB(255, 90, 113, 243),
                ),
                IconButton(
                  icon: Icon(
                    enquiry.bookmarked == 1
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: Color.fromARGB(255, 90, 113, 243),
                  ),
                  onPressed: () {
                    // Toggle the bookmark status
                    final isBookmarked = enquiry.bookmarked == 1;
                    FirebaseFirestore.instance
                        .collection('specialist_registration_enquiries')
                        .doc(enquiry.id)
                        .update({'bookmarked': isBookmarked ? 0 : 1});
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              enquiry.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 90, 113, 243),
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, enquiry.email),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, enquiry.phone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.business, enquiry.organization),
            const SizedBox(height: 8),
            Text(
              'Experience: ${enquiry.experienceYears} years',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            _buildGenderRow(enquiry.gender),
            const SizedBox(height: 8),
            Text(
              'Specialization: ${enquiry.specialization}',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'About:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              child: SingleChildScrollView(
                child: Text(
                  enquiry.about,
                  style: const TextStyle(height: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildServicesList(enquiry.services),
            const SizedBox(height: 8),
            // Display Document as an icon
            if (enquiry.documentUrl != null) ...[
              Text(
              'AHP License:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
              Row(
                children: [
                  Icon(Icons.attach_file, color: Color.fromARGB(255, 90, 113, 243)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _launchURL(enquiry.documentUrl!),
                    child: const Text(
                      "View Document",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Submitted on: ${_formatDate(enquiry.submitDate)}', // Update here
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString); // Convert string to DateTime
    return DateFormat('yyyy-MM-dd – HH:mm').format(dateTime); // Format date and time
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Color.fromARGB(255, 90, 113, 243)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildGenderRow(String gender) {
    IconData icon;
    Color color;

    if (gender.toLowerCase() == 'male') {
      icon = Icons.male;
      color = Colors.blue;
    } else {
      icon = Icons.female;
      color = Colors.red;
    }

    return Row(
      children: [
        Text('Gender: $gender', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Icon(icon, color: color, size: 20),
      ],
    );
  }

  Widget _buildServicesList(List<Map<String, dynamic>> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Services:', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        ...services.asMap().entries.map((entry) {
          int index = entry.key + 1;
          var service = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text('$index. ${service['name']}: ${service['description']}'),
          );
        }),
      ],
    );
  }
}

class SpecialistEnquiry {
  final String id; // Added to hold Firestore document ID
  final String name;
  final String email;
  final String phone;
  final String organization;
  final int experienceYears;
  final String gender;
  final String specialization;
  final String about;
  final String profilePictureUrl;
  final String? documentUrl; // New field for document URL
  final List<Map<String, dynamic>> services;
  final String submitDate;
  final int bookmarked; // 0 or 1 for bookmark status

  SpecialistEnquiry({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.organization,
    required this.experienceYears,
    required this.gender,
    required this.specialization,
    required this.about,
    required this.profilePictureUrl,
    this.documentUrl, // Optional document URL
    required this.services,
    required this.submitDate,
    required this.bookmarked,
  });

  factory SpecialistEnquiry.fromJson(Map<String, dynamic> json, String id) {
    return SpecialistEnquiry(
      id: id, // Firestore document ID
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      organization: json['organization'],
      experienceYears: json['experience_years'],
      profilePictureUrl: json['profile_picture_url'],
      gender: json['gender'],
      specialization: json['specialization'],
      about: json['about'],
      services: List<Map<String, dynamic>>.from(
          json['services'].map((item) => Map<String, dynamic>.from(item))),
      submitDate: json['submitDate'],
      bookmarked: json['bookmarked'] ?? 0, // Default to 0 if not present
      documentUrl: json['document_url'], // New field for document URL
    );
  }
}