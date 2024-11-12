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

  Client(
      {required this.id,
      required this.name,
      required this.email,
      required this.profilePic});
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No user is signed in')));
    }
  }

  Future<void> _fetchClients() async {
    // Clear the previous list
    clients.clear();

    // Fetch appointments
    var appointmentsSnapshot =
        await FirebaseFirestore.instance.collection('appointments').get();

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
      var clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .get();
      if (clientDoc.exists) {
        var clientData = clientDoc.data()!;
        clients.add(Client(
          id: clientId,
          name: clientData['name'] ?? 'Unknown',
          email: clientData['email'] ?? 'No email',
          profilePic: clientData['profile_pic'] ??
              '', // Assuming this is the URL to the profile pic
        ));
      }
    }

    // Refresh the UI
    setState(() {});
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
                  // Wrap the Card with GestureDetector to handle taps
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
                                  backgroundImage:
                                      NetworkImage(client.profilePic),
                                )
                              : CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey.shade200,
                                  child: const Icon(Icons.person, size: 30),
                                ),
                          const SizedBox(
                              width: 16), // Space between the avatar and text
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
                                const SizedBox(
                                    height: 4), // Space between name and email
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