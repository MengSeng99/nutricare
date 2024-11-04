import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_specialist_details.dart';

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
        title: const Text('Admin Specialists',
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

        // Inside SpecialistsListView class

        return ListView.builder(
          itemCount: specialists.length,
          itemBuilder: (context, index) {
            final specialistData =
                specialists[index].data() as Map<String, dynamic>;
            final profilePictureUrl = specialistData['profile_picture_url'] ??
                ''; // Retrieve profile picture URL
            final email =
                specialistData['email'] ?? 'No Email'; // Retrieve email

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
                      TextSpan(
                        text: 'Dr. ',
                        style: const TextStyle(
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
                    SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () {
                  final specialistId =
                      specialists[index].id; // Get the specialist ID
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
}
