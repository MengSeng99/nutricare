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
  TextEditingController searchController = TextEditingController();
  String searchKeyword = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose(); // Dispose the search controller
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
          _buildSpecialistsSection('Nutritionist'),
          _buildSpecialistsSection('Dietitian'),
        ],
      ),
    );
  }

  Widget _buildSpecialistsSection(String specialization) {
    return Column(
      children: [
        // New Search Field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchKeyword = value
                    .toLowerCase(); // Store lowercased keyword for comparison
              });
            },
            decoration: InputDecoration(
              hintText: "Search by Name", // Updated hint text
              prefixIcon: const Icon(Icons.search), // Search icon
              filled: true,
                  fillColor:
                      const Color.fromARGB(255, 250, 250, 250).withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 221, 222, 226),
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 221, 222, 226),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 90, 113, 243),
                      width: 2.0,
                    ),
                  ),
              suffixIcon: searchKeyword.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          searchKeyword = '';
                          searchController.clear();
                        });
                      },
                    )
                  : null,
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ),
        // Specialists list
        Expanded(
          child: SpecialistsListView(
              searchKeyword: searchKeyword, specialization: specialization),
        ),
      ],
    );
  }
}

class SpecialistsListView extends StatelessWidget {
  final String specialization;
  final String searchKeyword;

  const SpecialistsListView({
    super.key,
    required this.specialization,
    required this.searchKeyword,
  });

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

        final activeSpecialists = specialists.where((specialist) {
          final specialistData = specialist.data() as Map<String, dynamic>;
          final name = specialistData['name'] ?? '';
          final status = specialistData['status'] ?? '';
          return name.toLowerCase().startsWith(searchKeyword) &&
              status != 'inactive'; 
        }).toList();

        final inactiveSpecialists = specialists.where((specialist) {
          final specialistData = specialist.data() as Map<String, dynamic>;
          final name = specialistData['name'] ?? '';
          final status = specialistData['status'] ?? '';
          return name.toLowerCase().startsWith(searchKeyword) &&
              status == 'inactive'; 
        }).toList();

        if (activeSpecialists.isEmpty) {
          return Center(
              child: Text("No active specialists found matching '$searchKeyword'"));
        }

        return Column(
          children: [
            // Active Specialists List
            Expanded(
              child: ListView.builder(
                itemCount: activeSpecialists.length,
                itemBuilder: (context, index) {
                  final specialistData =
                      activeSpecialists[index].data() as Map<String, dynamic>;
                  final profilePictureUrl =
                      specialistData['profile_picture_url'] ?? ''; 
                  final email =
                      specialistData['email'] ?? 'No Email'; 
                  final specialistId =
                      activeSpecialists[index].id;

                  return _buildActiveSpecialistCard(
                    context,
                    specialistData,
                    profilePictureUrl,
                    email,
                    specialistId,
                  );
                },
              ),
            ),
            if (inactiveSpecialists.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Inactive Specialists',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: inactiveSpecialists.length,
                  itemBuilder: (context, index) {
                    final specialistData =
                        inactiveSpecialists[index].data() as Map<String, dynamic>;
                    final profilePictureUrl =
                        specialistData['profile_picture_url'] ?? ''; 
                    final email =
                        specialistData['email'] ?? 'No Email'; 
                    final specialistId =
                        inactiveSpecialists[index].id;

                    return _buildInactiveSpecialistCard(
                      context,
                      specialistData,
                      profilePictureUrl,
                      email,
                      specialistId,
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActiveSpecialistCard(
    BuildContext context,
    Map<String, dynamic> specialistData,
    String profilePictureUrl,
    String email,
    String specialistId,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Color.fromARGB(255, 221, 222, 226), width: 1),
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
            Text(specialistData['specialization'] ?? 'No Specialization'),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
          onPressed: () {
            _showDeactivateConfirmationDialog(
                context, specialistData['name'], specialistId);
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AdminSpecialistsDetailsScreen(specialistId: specialistId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInactiveSpecialistCard(
    BuildContext context,
    Map<String, dynamic> specialistData,
    String profilePictureUrl,
    String email,
    String specialistId,
  ) {
    // Get the deactivation date time
    final Timestamp? deactivationTimeStamp = 
        specialistData['deactivation_datetime'] as Timestamp?;
    
    // Format the date if the timestamp is not null
    final String deactivationDate = deactivationTimeStamp != null 
        ? "${deactivationTimeStamp.toDate()}".split(' ')[0] // Formatting to only get the date part
        : 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      color: const Color(0xFFFFF0F0), 
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.redAccent, width: 1),
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
                  color: Colors.redAccent,
                ),
              ),
              TextSpan(
                text: specialistData['name'] ?? 'No Name',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
              const TextSpan(text: ' (Inactive)', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(specialistData['specialization'] ?? 'No Specialization'),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Deactivated on: $deactivationDate', // Displaying deactivation date
                style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
        trailing: SizedBox.shrink(), // Hiding the deactivate button
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminSpecialistsDetailsScreen(specialistId: specialistId),
            ),
          );
        },
      ),
    );
  }
  void _showDeactivateConfirmationDialog(
    BuildContext context, String? specialistName, String specialistId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Deactivate Specialist',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243))),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 16, color: Colors.black), // General text style
            children: [
              const TextSpan(text: 'Are you sure you want to deactivate\n'),
              TextSpan(
                text: 'Dr. ${specialistName ?? "this specialist"}',
                style: const TextStyle(
                  color: Color.fromARGB(
                      255, 90, 113, 243), // Specific color for the name
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
              // Deactivate the specialist in Firestore
              await FirebaseFirestore.instance
                  .collection('specialists')
                  .doc(specialistId)
                  .update({
                'status': 'inactive',
                'deactivation_datetime': FieldValue.serverTimestamp(),
              }).then((_) {
                Navigator.of(context).pop(); // Close the dialog
                // Optionally, show a confirmation message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Specialist deactivated successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }).catchError((error) {
                // Handle any errors that occur during the update
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deactivating specialist: $error'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              });
            },
            child: const Text('Yes, Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}
}
