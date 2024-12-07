import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../specialist_management/admin_specialist_details.dart';

class ServiceMapScreen extends StatefulWidget {
  const ServiceMapScreen({super.key});

  @override
  _ServiceMapScreenState createState() => _ServiceMapScreenState();
}

class _ServiceMapScreenState extends State<ServiceMapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  LatLng _center = LatLng(0, 0); // Default center point
  String? selectedSpecialistId;
  String? selectedSpecialistName;
  String? selectedOrganization;
  String? selectedProfilePictureUrl;

  @override
  void initState() {
    super.initState();
    _fetchSpecialists();
  }

  Future<void> _fetchSpecialists() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('specialists').get();

    _markers.clear(); // Clear markers before adding new ones

    for (var doc in snapshot.docs) {
      double latitude = doc['latitude']; // Extract latitude
      double longitude = doc['longitude']; // Extract longitude
      String organization = doc['organization']; // Extract organization
      String specialistName = doc['name']; // Extract specialist name
      String profilePictureUrl =
          doc['profile_picture_url']; // Extract profile picture URL

      // Create a marker
      final marker = Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: organization,
          snippet: 'Specialist: $specialistName',
        ),
        onTap: () {
          // Update selected specialist when marker is tapped
          setState(() {
            selectedSpecialistId = doc.id;
            selectedSpecialistName = specialistName;
            selectedOrganization = organization;
            selectedProfilePictureUrl = profilePictureUrl;
          });
        },
      );

      // Add the marker to the set
      _markers.add(marker);
    }

    // Center the map on the first specialist
    if (snapshot.docs.isNotEmpty) {
      _center = LatLng(
        snapshot.docs.first['latitude'],
        snapshot.docs.first['longitude'],
      );
      mapController.moveCamera(CameraUpdate.newLatLng(_center));
    }

    setState(() {}); // Refresh the UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Service Map',
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
              target: _center, // Set the initial camera position
              zoom: 10.0, // Set zoom level as required
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
    return Container(); // If no specialist is selected, return an empty container
  }

  return GestureDetector(
    onTap: () {
      // Navigate to AdminSpecialistsDetailsScreen with selectedSpecialistId
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminSpecialistsDetailsScreen(
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
                      ? NetworkImage(selectedProfilePictureUrl!) // Load image from URL
                      : const AssetImage('images/user_profile/default_profile.png')
                          as ImageProvider, // Use a default image if none
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
                        overflow: TextOverflow.ellipsis, // Handle long names
                        maxLines: 1, // Limit to one line
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedOrganization ?? 'N/A',
                        style: const TextStyle(color: Colors.grey),
                        softWrap: true, // Enable wrapping
                        overflow: TextOverflow.ellipsis, // Handle overflow elegantly
                        maxLines: 2, // Limit to 2 lines for organization
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 5, // Fixed position from the right
              top: 20, // Fixed position from the top
              child: Icon(
                Icons.arrow_forward_ios, // Choose your desired icon
                color: Color.fromARGB(255, 90, 113, 243), // Match icon color
                size: 20, // Set the size of the icon
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
