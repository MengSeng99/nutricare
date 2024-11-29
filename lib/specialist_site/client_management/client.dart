import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'client_details.dart';

// Client model to hold client details
class Client {
  final String id;
  final String name;
  final String email;
  final String profilePic;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePic,
  });
}

class SpecialistClientScreen extends StatefulWidget {
  const SpecialistClientScreen({super.key});

  @override
  _SpecialistClientScreenState createState() => _SpecialistClientScreenState();
}

class _SpecialistClientScreenState extends State<SpecialistClientScreen> {
  List<Client> clients = []; // List to hold client instances
  String? currentUserId; // Variable to hold the current user's ID

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
  }

  Future<void> _fetchCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      currentUserId = user.uid; // Set the current user ID
      await _fetchClients(); // Fetch clients once the ID is retrieved
    } else {
      // Handle the case when no user is signed in
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user is signed in')));
    }
  }

  Future<void> _fetchClients() async {
    // Clear the previous list
    clients.clear();

    // Fetch appointments
    var appointmentsSnapshot = await FirebaseFirestore.instance.collection('appointments').get();

    // Filter client IDs from appointments
    List<String> clientIds = [];
    for (var doc in appointmentsSnapshot.docs) {
      List<dynamic> users = doc['users']; // Assuming an array of user IDs
      if (users.contains(currentUserId)) {
        // Add all other user IDs from this appointment (that are not the current user)
        for (var userId in users) {
          if (userId != currentUserId && !clientIds.contains(userId)) {
            clientIds.add(userId);
          }
        }
      }
    }

    // Fetch client details
    for (String clientId in clientIds) {
      var clientDoc = await FirebaseFirestore.instance.collection('users').doc(clientId).get();
      if (clientDoc.exists) {
        var clientData = clientDoc.data()!;
        clients.add(Client(
          id: clientId,
          name: clientData['name'] ?? 'Unknown',
          email: clientData['email'] ?? 'No email',
          profilePic: clientData['profile_pic'] ?? '', // Assuming this is the URL to the profile pic
        ));
      }
    }

    // Refresh the UI
    setState(() {});
  }

  Future<void> _showAppointmentDialog(Client client) async {
  // Searching for existing appointments
  QuerySnapshot appointmentsSnapshot = await FirebaseFirestore.instance
      .collection('appointments')
      .where('users', arrayContains: currentUserId)
      .get();

  // To hold the list of appointment information
  List<Map<String, String>> appointmentDetails = []; // Store both ID and status

  for (var doc in appointmentsSnapshot.docs) {
    List<dynamic> users = doc['users'];
    if (users.contains(client.id)) {
      String appointmentId = doc.id; // Collect the appointment document ID

      // Fetch the appointment status from the subcollection
      var statusSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .collection('details') // Assuming your subcollection is named 'details'
          .limit(1) // Limit to 1 document
          .get();

      if (statusSnapshot.docs.isNotEmpty) {
        String appointmentStatus = statusSnapshot.docs[0].data()['appointmentStatus'] ?? 'No status'; // Replace with your actual field name
        appointmentDetails.add({
          'id': appointmentId,
          'status': appointmentStatus,
        });
      }
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Appointments with ${client.name}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 90, 113, 243)),
        ),
        content: SizedBox(
          width: double.maxFinite, // Maximum width
          child: Column(
            mainAxisSize: MainAxisSize.min, // Fit content
            children: [
              if (appointmentDetails.isNotEmpty)
                Column(
                  children: appointmentDetails
                      .map((appointment) => Card(
                            color: Color.fromARGB(255, 220, 220, 241),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Appointment ID: ${appointment['id']}\nStatus: ${appointment['status']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ))
                      .toList(),
                )
              else
                Text(
                  'No existing appointments with ${client.name}.',
                  style: const TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Your Clients',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 90, 113, 243),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: clients.isEmpty
          ? Center(child: CircularProgressIndicator()) // Loading indicator
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to ClientDetailsScreen and pass client details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClientDetailsScreen(
                          clientId: client.id,
                          clientName: client.name,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), // Internal padding
                      child: Row(
                        children: [
                          // Profile picture
                          client.profilePic.isNotEmpty
                              ? CircleAvatar(
                                  radius: 30, // Custom radius for the avatar
                                  backgroundImage: NetworkImage(client.profilePic),
                                )
                              : CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey.shade200,
                                  child: const Icon(Icons.person, size: 30),
                                ),
                          const SizedBox(width: 16), // Space between the avatar and text
                          // Client details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4), // Space between name and email
                                Text(
                                  client.email,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Appointment icon
                          IconButton(
                            icon: const Icon(Icons.calendar_today, color: Color.fromARGB(255, 90, 113, 243)),
                            onPressed: () {
                              _showAppointmentDialog(client); // Show dialog on icon press
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}