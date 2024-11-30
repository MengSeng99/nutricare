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
  TextEditingController searchController = TextEditingController();
  String _searchQuery = '';
  final List<String> _selectedGenders = [];
  bool _showFavoritesOnly = false; // New variable to track filter option

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
      List<Specialist> filteredSpecialists = specialists.where((specialist) {
        final matchesGender = _selectedGenders.isEmpty ||
            _selectedGenders.contains(specialist.gender);
        final matchesSearch =
            specialist.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesTitle = widget.title == 'Dietitian'
            ? specialist.specialization.toLowerCase() == 'dietitian'
            : widget.title == 'Nutritionist' &&
                specialist.specialization.toLowerCase() == 'nutritionist';

        return matchesGender && matchesSearch && matchesTitle;
      }).toList();

      // Sort to show favorites first
      filteredSpecialists.sort((a, b) {
        if (a.isFavorite == b.isFavorite) return 0;
        return a.isFavorite ? -1 : 1;
      });

      return _showFavoritesOnly
          ? filteredSpecialists
              .where((specialist) => specialist.isFavorite)
              .toList()
          : filteredSpecialists; // Return all specialists or favorite ones
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
          content:
              Text('Successfully added Dr. ${specialist.name} to favorites.')));
    } else {
      await userFavoritesRef.doc(specialist.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Successfully removed Dr. ${specialist.name} from favorites.')));
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
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side:
                    const BorderSide(color: Color.fromARGB(255, 218, 218, 218)),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(specialist.profilePictureUrl),
                ),
                title: Text("Dr. ${specialist.name}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(specialist.specialization),
                    Text(specialist.organization,
                        style: const TextStyle(fontWeight: FontWeight.w300,color: Color.fromARGB(255, 90, 113, 243))),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    specialist.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: specialist.isFavorite ? Color.fromARGB(255, 90, 113, 243) : null,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(
                color: Color.fromARGB(255, 90, 113, 243),
                fontWeight: FontWeight.bold)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search ${widget.title}',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 250, 250, 250)
                          .withOpacity(0.5),
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
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  searchController
                                      .clear(); // Clear the search field
                                  _searchQuery = ""; // Clear the search query
                                });
                              },
                            )
                          : null,
                    ),
                    style: const TextStyle(
                        color: Color.fromARGB(255, 74, 60, 137)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // Choice chips for filtering
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: !_showFavoritesOnly,
                    onSelected: (isSelected) {
                      setState(() {
                        _showFavoritesOnly = false; // Handle selection
                      });
                    },
                    selectedColor: const Color.fromARGB(255, 90, 113, 243),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: !_showFavoritesOnly
                          ? Colors.white
                          : const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(100), // 100px border radius
                      side: BorderSide(
                        color: !_showFavoritesOnly
                            ? const Color.fromARGB(255, 90, 113, 243)
                            : Colors.transparent,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ChoiceChip(
                    label: const Text('Favorites'),
                    selected: _showFavoritesOnly,
                    onSelected: (isSelected) {
                      setState(() {
                        _showFavoritesOnly = true; // Handle selection
                      });
                    },
                    selectedColor: const Color.fromARGB(255, 90, 113, 243),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _showFavoritesOnly
                          ? Colors.white
                          : const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(100), // 100px border radius
                      side: BorderSide(
                        color: _showFavoritesOnly
                            ? const Color.fromARGB(255, 90, 113, 243)
                            : Colors.transparent,
                        width: 2.0,
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
