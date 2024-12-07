import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../specialist/specialist_details.dart';

class ClientNearMeScreen extends StatefulWidget {
  const ClientNearMeScreen({super.key});

  @override
  _ClientNearMeScreenState createState() => _ClientNearMeScreenState();
}

class _ClientNearMeScreenState extends State<ClientNearMeScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  LatLng _center = LatLng(0, 0);
  
  String? selectedSpecialistId;
  String? selectedSpecialistName;
  String? selectedOrganization;
  String? selectedProfilePictureUrl;
  double? selectedSpecialistDistance;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndSpecialists();
  }

  Future<void> _fetchLocationAndSpecialists() async {
    // Get the user's current location
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _center = LatLng(position.latitude, position.longitude); // Center map on user's location

    // Adding a marker for the user's current location
    _markers.add(Marker(
      markerId: MarkerId('currentLocation'),
      position: _center,
      infoWindow: InfoWindow(title: 'Your Location'), // Title for the marker
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Custom marker icon
    ));

    // Fetch specialists from Firestore
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('specialists').get();
    _markers.clear(); // Clear previous markers (if any)

    for (var doc in snapshot.docs) {
      double latitude = doc['latitude'];
      double longitude = doc['longitude'];
      String organization = doc['organization'];
      String specialistName = doc['name'];
      String profilePictureUrl = doc['profile_picture_url'];

      // Calculate distance (optional)
      double distance = Geolocator.distanceBetween(position.latitude, position.longitude, latitude, longitude);

      // Create a marker for each specialist
      final marker = Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: organization,
          snippet: 'Specialist: $specialistName',
        ),
        onTap: () {
          setState(() {
            selectedSpecialistId = doc.id;
            selectedSpecialistName = specialistName;
            selectedOrganization = organization;
            selectedProfilePictureUrl = profilePictureUrl;
            selectedSpecialistDistance = distance; // Store the distance
          });
        },
      );

      _markers.add(marker);
    }

    mapController.moveCamera(CameraUpdate.newLatLng(_center)); // Center the map on the user's location
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Specialists Near Me',
          style: TextStyle(
            color: Color.fromARGB(255, 90, 113, 243),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            markers: _markers,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 12.0,
            ),
          ),
          Positioned(
            top: 20,
            left: 10,
            right: 10,
            child: _buildSpecialistDetails(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistDetails(BuildContext context) {
    if (selectedSpecialistId == null) {
      return Container(); // Return empty if no specialist is selected
    }

    return GestureDetector(
      onTap: () {
        // Navigate to SpecialistDetailsScreen passing the selectedSpecialistId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpecialistDetailsScreen(
              specialistId: selectedSpecialistId!,
            ),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: selectedProfilePictureUrl != null
                        ? NetworkImage(selectedProfilePictureUrl!) // Load from URL
                        : const AssetImage('images/user_profile/default_profile.png') as ImageProvider, // Default image
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedSpecialistName ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 90, 113, 243),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedOrganization ?? 'N/A',
                          style: const TextStyle(color: Colors.grey),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(selectedSpecialistDistance! / 1000).toStringAsFixed(2)} km away', // Convert to kilometers
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 5,
                top: 20,
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Color.fromARGB(255, 90, 113, 243),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
