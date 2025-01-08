import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'specialist_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

late Position _currentPosition;

class Specialist {
  final String id;
  final String name;
  final String specialization;
  final String organization;
  final String profilePictureUrl;
  final String gender;
  bool isFavorite;
  double distance; // New property for distance

  Specialist({
    required this.id,
    required this.name,
    required this.specialization,
    required this.organization,
    required this.profilePictureUrl,
    required this.gender,
    this.isFavorite = false,
    this.distance = 0.0, // Default distance to 0
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
  final List<String> _selectedOrganizations = [];

  @override
  void initState() {
    super.initState();
    _fetchUserFavorites();
    _determinePosition();
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

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check for permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Fetch the current position
    _currentPosition = await Geolocator.getCurrentPosition();
  }

  Stream<List<Specialist>> _fetchSpecialists() {
    return _specialistsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Specialist specialist = Specialist.fromFirestore(doc);

        // Calculate distance
        final data = doc.data() as Map<String, dynamic>;
        double specialistLatitude = data['latitude'] ?? 0.0;
        double specialistLongitude = data['longitude'] ?? 0.0;

        specialist.distance = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          specialistLatitude,
          specialistLongitude,
        );

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

        // Modify organization filter logic
        final matchesOrganization = _selectedOrganizations.isEmpty ||
            _selectedOrganizations.contains(specialist.organization);

        return matchesGender &&
            matchesSearch &&
            matchesTitle &&
            matchesOrganization;
      }).toList();

      // Existing sorting logic
      filteredSpecialists.sort((a, b) {
        return a.distance.compareTo(b.distance);
      });

      filteredSpecialists.sort((a, b) {
        if (a.isFavorite == b.isFavorite) {
          return a.distance.compareTo(b.distance);
        }
        return a.isFavorite ? -1 : 1;
      });

      return _showFavoritesOnly
          ? filteredSpecialists
              .where((specialist) => specialist.isFavorite)
              .toList()
          : filteredSpecialists;
    });
  }

  // Modify _fetchUniqueOrganizations method
  Future<List<String>> _fetchUniqueOrganizations() async {
    List<Specialist> specialists = await _fetchSpecialists().first;
    return specialists
        .map((specialist) => specialist.organization)
        .toSet()
        .toList();
  }

  void _showOrganizationFilterDialog() {
    String selectedOrganization =
        _selectedOrganizations.isNotEmpty ? _selectedOrganizations.first : '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Colors.white,
              title: Text(
                'Filter by Organization',
                style: TextStyle(
                  color: Color.fromARGB(255, 90, 113, 243),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: FutureBuilder<List<String>>(
                  future: _fetchUniqueOrganizations(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error fetching organizations'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No organizations available'));
                    }

                    final organizations = snapshot.data!;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile(
                          title: Text('All Organizations'),
                          value: '',
                          groupValue: selectedOrganization,
                          onChanged: (value) {
                            setState(() {
                              selectedOrganization = value ?? '';
                            });
                          },
                          activeColor: Color.fromARGB(255, 90, 113, 243),
                        ),
                        ...organizations.map((organization) {
                          return RadioListTile(
                            title: Text(organization),
                            value: organization,
                            groupValue: selectedOrganization,
                            onChanged: (value) {
                              setState(() {
                                selectedOrganization = value ?? '';
                              });
                            },
                            activeColor: Color.fromARGB(255, 90, 113, 243),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedOrganizations.clear();
                    });
                  },
                  child: Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Use the parent widget's setState to trigger a refresh
                    setState(() {
                      _selectedOrganizations.clear();
                      if (selectedOrganization.isNotEmpty) {
                        _selectedOrganizations.add(selectedOrganization);
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 90, 113, 243),
                  ),
                  child: Text('Apply', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // This will be called after the dialog is closed
      setState(() {
        // This triggers a rebuild of the entire widget
      });
    });
  }

  Future<void> _updateFavoriteStatus(Specialist specialist) async {
    final userFavoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('favorite_specialist_lists');

    if (specialist.isFavorite) {
      await userFavoritesRef.doc(specialist.id).set({
        // 'name': specialist.name,
        // 'specialization': specialist.specialization,
        // 'organization': specialist.organization,
        // 'profile_picture_url': specialist.profilePictureUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Successfully added Dr. ${specialist.name} to favorites.')
              ,backgroundColor: Colors.green,
              ));
    } else {
      await userFavoritesRef.doc(specialist.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Successfully removed Dr. ${specialist.name} from favorites.')
              ,backgroundColor: Colors.red,));
    }

    await _fetchUserFavorites();
  }

  void _navigateToSpecialistDetails(Specialist specialist) async {
    // Navigate to details and wait for return
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SpecialistDetailsScreen(specialistId: specialist.id),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            color: Color.fromARGB(255, 90, 113, 243))),
                    if (specialist.distance > 0)
                      Text(
                        '${(specialist.distance / 1000).toStringAsFixed(2)} km away',
                        style: const TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w400),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    specialist.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: specialist.isFavorite
                        ? Color.fromARGB(255, 90, 113, 243)
                        : null,
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
                                  searchController.clear();
                                  _searchQuery = "";
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
            // Choice chips and filter row
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: !_showFavoritesOnly,
                          onSelected: (isSelected) {
                            setState(() {
                              _showFavoritesOnly = false;
                            });
                          },
                          selectedColor:
                              const Color.fromARGB(255, 90, 113, 243),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: !_showFavoritesOnly
                                ? Colors.white
                                : const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
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
                              _showFavoritesOnly = true;
                            });
                          },
                          selectedColor:
                              const Color.fromARGB(255, 90, 113, 243),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: _showFavoritesOnly
                                ? Colors.white
                                : const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
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
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _showOrganizationFilterDialog,
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedOrganizations.isNotEmpty
                        ? Color.fromARGB(255, 90, 113, 243).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: _selectedOrganizations.isNotEmpty
                              ? Color.fromARGB(255, 90, 113, 243)
                              : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Filter',
                          style: TextStyle(
                            color: _selectedOrganizations.isNotEmpty
                                ? Color.fromARGB(255, 90, 113, 243)
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16.0),
            Expanded(child: _buildSpecialistList()),
          ],
        ),
      ),
    );
  }
}
