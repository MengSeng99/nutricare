import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_specialist_details.dart';
import 'admin_create_specialist.dart'; // Import your new screen here

class AdminSpecialistsScreen extends StatefulWidget {
  const AdminSpecialistsScreen({super.key});

  @override
  _AdminSpecialistsScreenState createState() => _AdminSpecialistsScreenState();
}

class _AdminSpecialistsScreenState extends State<AdminSpecialistsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Specialists',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243))),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color.fromARGB(255, 90, 113, 243),
          labelColor: Color.fromARGB(255, 90, 113, 243),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Nutritionists'),
            Tab(text: 'Dietitians'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_rounded,
                color: Color.fromARGB(255, 90, 113, 243)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateSpecialistScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SpecialistsListView(specialization: 'Nutritionist'),
          SpecialistsListView(specialization: 'Dietitian'),
        ],
      ),
    );
  }
}

class SpecialistsListView extends StatelessWidget {
  final String specialization;

  const SpecialistsListView({super.key, required this.specialization});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('specialists')
          .where('specialization', isEqualTo: specialization)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No specialists found'));
        }

        final specialists = snapshot.data!.docs;

        return ListView.builder(
          itemCount: specialists.length,
          itemBuilder: (context, index) {
            final specialistData =
                specialists[index].data() as Map<String, dynamic>;
            final profilePictureUrl = specialistData['profile_picture_url'] ??
                ''; // Retrieve profile picture URL
            final email =
                specialistData['email'] ?? 'No Email'; // Retrieve email
            final specialistId = specialists[index].id; // Get the specialist ID

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade600, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: profilePictureUrl.isNotEmpty
                      ? NetworkImage(profilePictureUrl)
                      : const AssetImage('assets/images/default_profile.png')
                          as ImageProvider,
                ),
                title: RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Dr. ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromARGB(255, 90, 113, 243),
                        ),
                      ),
                      TextSpan(
                        text: specialistData['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromARGB(255, 90, 113, 243),
                        ),
                      ),
                    ],
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(specialistData['specialization'] ??
                        'No Specialization'),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeleteConfirmationDialog(
                        context, specialistData['name'], specialistId);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminSpecialistsDetailsScreen(
                          specialistId: specialistId),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String? specialistName, String specialistId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Delete Specialist',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 90, 113, 243))),
          content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black), // General text style
            children: [
              const TextSpan(text: 'Are you sure you want to remove\n'),
              TextSpan(
                text: 'Dr. ${specialistName ?? "this specialist"}',
                style: const TextStyle(
                  color: Color.fromARGB(255, 90, 113, 243), // Specific color for the name
                  fontWeight: FontWeight.bold, // Bold for emphasis
                ),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () async {
                // Delete the specialist from Firestore
                await FirebaseFirestore.instance
                    .collection('specialists')
                    .doc(specialistId)
                    .delete();
                Navigator.of(context).pop(); // Close the dialog
                // Optionally, show a snackbar or a toast to confirm deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Specialist removed successfully')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}