import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'specialist_details.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Specialist {
  final String id; // Add this to store the specialist ID
  final String name;
  final String specialization;
  final String organization;
  final String profilePictureUrl;
  bool isFavorite;

  Specialist({
    required this.id, // Include the id in the constructor
    required this.name,
    required this.specialization,
    required this.organization,
    required this.profilePictureUrl,
    this.isFavorite = false,
  });

  // Method to convert Firestore document to Specialist object
  factory Specialist.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Specialist(
      id: doc.id, // Set the ID from the document
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? '',
      organization: data['organization'] ?? '',
      profilePictureUrl: data['profile_picture_url'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
    );
  }
}

class BookingAppointmentScreen extends StatefulWidget {
  final String title;

  const BookingAppointmentScreen({super.key, required this.title});

  @override
  _BookingAppointmentScreenState createState() => _BookingAppointmentScreenState();
}

class _BookingAppointmentScreenState extends State<BookingAppointmentScreen> {
  bool _showFilters = false;
  final Set<String> _selectedProfessionalPreferences = {};
  final Set<String> _selectedAvailability = {};

  // Firestore reference for the specialists collection
  final CollectionReference _specialistsCollection = FirebaseFirestore.instance.collection('specialists');
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid; // Current user ID
  late List<String> _favoriteIds = []; // List to store favorite IDs

  @override
  void initState() {
    super.initState();
    _fetchUserFavorites(); // Fetch user favorites on initialization
  }

  // Fetching user's favorite specialists from Firestore
  Future<void> _fetchUserFavorites() async {
    final userFavoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('favorite_specialist_lists');
    
    QuerySnapshot snapshot = await userFavoritesRef.get();
    setState(() {
      _favoriteIds = snapshot.docs.map((doc) => doc.id).toList(); // Store favorite IDs
    });
  }

  // Fetching specialists from Firestore
  Stream<List<Specialist>> _fetchSpecialists() {
    return _specialistsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Specialist specialist = Specialist.fromFirestore(doc);
        specialist.isFavorite = _favoriteIds.contains(specialist.id); // Check if specialist is a favorite
        return specialist;
      }).toList();
    });
  }

  // Update Firestore with favorite specialist
  Future<void> _updateFavoriteStatus(Specialist specialist) async {
    final userFavoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('favorite_specialist_lists');

    if (specialist.isFavorite) {
      // Add to favorites
      await userFavoritesRef.doc(specialist.id).set({
        'name': specialist.name,
        'specialization': specialist.specialization,
        'organization': specialist.organization,
        'profile_picture_url': specialist.profilePictureUrl,
      });
      // Feedback on addition
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added ${specialist.name} to favorites.'),
        ),
      );
    } else {
      // Remove from favorites
      await userFavoritesRef.doc(specialist.id).delete();
      // Feedback on removal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully removed ${specialist.name} from favorites.'),
        ),
      );
    }
    
    // Refresh the favorite IDs after updating Firestore
    await _fetchUserFavorites();
  }

  // Build the specialist list
  Widget _buildSpecialistList() {
    return StreamBuilder<List<Specialist>>(
      stream: _fetchSpecialists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching specialists'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No specialists available'));
        }

        List<Specialist> specialists = snapshot.data!;
        return ListView.builder(
          itemCount: specialists.length,
          itemBuilder: (context, index) {
            final specialist = specialists[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color.fromARGB(255, 218, 218, 218)),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(specialist.profilePictureUrl),
                ),
                title: Text("Dr. ${specialist.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(specialist.specialization),
                    Text(specialist.organization),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    specialist.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: specialist.isFavorite ? Colors.blue : null,
                  ),
                  onPressed: () async {
                    setState(() {
                      specialist.isFavorite = !specialist.isFavorite; // Toggle favorite status
                    });
                    await _updateFavoriteStatus(specialist); // Update Firestore
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpecialistDetailsScreen(specialist: specialist),
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

  @override
  Widget build(BuildContext context) {
    String placeholder = widget.title; // Placeholder text based on title
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Field with Filter Button to the right
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search $placeholder',
                          prefixIcon: const Icon(Icons.search),
                          fillColor: const Color.fromARGB(255, 250, 250, 250).withOpacity(0.5),
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
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      icon: Icon(
                        Icons.filter_list,
                        color: _showFilters
                            ? const Color.fromARGB(255, 90, 113, 243) // Blue color when filter is open
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildSpecialistList()), // Display the specialist list
              ],
            ),
          ),
        ],
      ),
    );
  }
}
