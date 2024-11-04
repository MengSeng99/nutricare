import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'chat_details.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final String appointmentId;
  final String? specialistAvatarUrl;
  final DateTime date;
  final String time;
  final String specialistName;
  final String service;
  final String status;
  final String specialistId;

  const AppointmentDetailsScreen({
    required this.appointmentId,
    required this.specialistAvatarUrl,
    required this.date,
    required this.time,
    required this.specialistName,
    required this.service,
    required this.status,
    required this.specialistId,
    super.key,
  });

  Future<Map<String, dynamic>?> _fetchAppointmentDetails() async {
    try {
      // Access the details subcollection within the appointment document
      QuerySnapshot detailsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .collection('details')
          .get();

      // If there are any documents in the details subcollection, return the data from the first one
      if (detailsSnapshot.docs.isNotEmpty) {
        return detailsSnapshot.docs.first.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print("Error fetching appointment details: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Appointment Details",
          style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold),
        ),
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchAppointmentDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No appointment details found"));
          }

          var appointmentDetails = snapshot.data!;
          double amountPaid = appointmentDetails['amountPaid'] ?? 0.0;
          String appointmentMode =
              appointmentDetails['appointmentMode'] ?? 'Unknown';
          Timestamp createdAt =
              appointmentDetails['createdAt'] ?? Timestamp.now();
          String paymentCardUsed =
              appointmentDetails['paymentCardUsed'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        specialistAvatarUrl ?? '',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      specialistName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 16,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(
                    title: "Appointment Details",
                    children: [
                      _buildAppointmentInfo("Appointment ID", appointmentId),
                      _buildAppointmentInfo("Status", status),
                      _buildAppointmentInfo(
                          "Date", DateFormat('MMMM dd, yyyy').format(date)),
                      _buildAppointmentInfo("Time", time),
                      _buildAppointmentInfo("Service", service),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard(
                    title: "Payment Details",
                    children: [
                      _buildAppointmentInfo("Amount Paid", "RM $amountPaid"),
                      _buildAppointmentInfo(
                          "Appointment Mode", appointmentMode),
                      _buildAppointmentInfo(
                          "Payment Card Used", paymentCardUsed),
                      _buildAppointmentInfo(
                          "Pay On",
                          DateFormat('MMMM dd, yyyy, hh:mm a')
                              .format(createdAt.toDate())),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Check chat session or create a new one
                        await _checkForChatSession(context, specialistId);
                      },
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: Text(
                        "Chat with Dr. $specialistName",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A71F3),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkForChatSession(
      BuildContext context, String specialistId) async {
    String currentUserId =
        FirebaseAuth.instance.currentUser!.uid; // Get current user ID

    try {
      QuerySnapshot chatSnapshot =
          await FirebaseFirestore.instance.collection('chats').get();
      bool chatFound = false;

      for (var chat in chatSnapshot.docs) {
        List<dynamic> users = chat['users'] ?? [];

        if (users.contains(currentUserId) && users.contains(specialistId)) {
          chatFound = true;
          String chatId = chat.id;

          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chatId,
              currentUserId: currentUserId,
              receiverId: specialistId,
              specialistName: specialistName,
              profilePictureUrl: specialistAvatarUrl ?? '',
            ),
          ));
          return;
        }
      }

      if (!chatFound) {
        DocumentReference newChatDoc =
            await FirebaseFirestore.instance.collection('chats').add({
          'users': [currentUserId, specialistId],
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: newChatDoc.id,
            currentUserId: currentUserId,
            receiverId: specialistId,
            specialistName: specialistName,
            profilePictureUrl: specialistAvatarUrl ?? '',
          ),
        ));
      }
    } catch (e) {
      print('Error checking chat session: $e');
    }
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6D6D6D),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending Confirmation':
        return Colors.orange;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
