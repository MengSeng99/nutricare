import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'specialist_details.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Specialist {
  final String id;
  final String name;
  final String specialization;
  final String organization;
  final String profilePictureUrl;
  bool isFavorite;
  final String gender;

  Specialist({
    required this.id,
    required this.name,
    required this.specialization,
    required this.organization,
    required this.profilePictureUrl,
    required this.gender,
    this.isFavorite = false,
  });

  factory Specialist.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Specialist(
      id: doc.id,
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? '',
      organization: data['organization'] ?? '',
      profilePictureUrl: data['profile_picture_url'] ?? '',
      gender: data['gender'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
    );
  }
}

class BookingAppointmentScreen extends StatefulWidget {
  final String title;

  const BookingAppointmentScreen({super.key, required this.title});

  @override
  _BookingAppointmentScreenState createState() =>
      _BookingAppointmentScreenState();
}

class _BookingAppointmentScreenState extends State<BookingAppointmentScreen> {
  final CollectionReference _specialistsCollection =
      FirebaseFirestore.instance.collection('specialists');
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late List<String> _favoriteIds = [];

  String _searchQuery = '';
  final List<String> _selectedGenders = [];

  @override
  void initState() {
    super.initState();
    _fetchUserFavorites();
  }

  Future<void> _fetchUserFavorites() async {
    final userFavoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('favorite_specialist_lists');

    QuerySnapshot snapshot = await userFavoritesRef.get();
    setState(() {
      _favoriteIds = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Stream<List<Specialist>> _fetchSpecialists() {
    return _specialistsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Specialist specialist = Specialist.fromFirestore(doc);
        specialist.isFavorite = _favoriteIds.contains(specialist.id);
        return specialist;
      }).toList();
    }).map((specialists) {
      return specialists.where((specialist) {
        final matchesGender =
            _selectedGenders.isEmpty || _selectedGenders.contains(specialist.gender);
        final matchesSearch =
            specialist.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesTitle = widget.title == 'Dietitian'
            ? specialist.specialization.toLowerCase() == 'dietitian'
            : widget.title == 'Nutritionist' &&
                specialist.specialization.toLowerCase() == 'nutritionist';
        return matchesGender && matchesSearch && matchesTitle;
      }).toList();
    });
  }

  Future<void> _updateFavoriteStatus(Specialist specialist) async {
    final userFavoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('favorite_specialist_lists');

    if (specialist.isFavorite) {
      await userFavoritesRef.doc(specialist.id).set({
        'name': specialist.name,
        'specialization': specialist.specialization,
        'organization': specialist.organization,
        'profile_picture_url': specialist.profilePictureUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Successfully added Dr. ${specialist.name} to favorites.')));
    } else {
      await userFavoritesRef.doc(specialist.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Successfully removed Dr. ${specialist.name} from favorites.')));
    }

    await _fetchUserFavorites();
  }

  void _navigateToSpecialistDetails(Specialist specialist) async {
    // Navigate to details and wait for return
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpecialistDetailsScreen(specialist: specialist),
      ),
    );

    // After returning, re-fetch the favorites and update the list
    await _fetchUserFavorites();
    setState(() {});
  }

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
                      specialist.isFavorite = !specialist.isFavorite;
                    });
                    await _updateFavoriteStatus(specialist);
                  },
                ),
                onTap: () {
                  _navigateToSpecialistDetails(specialist);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search ${widget.title}',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: const BorderSide(color: Color.fromARGB(255, 221, 222, 222)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(child: _buildSpecialistList()),
          ],
        ),
      ),
    );
  }
}
