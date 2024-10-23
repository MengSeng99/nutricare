import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'appointment_details.dart';
import 'package:intl/intl.dart';

import 'reschedule.dart'; // For date formatting

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "Schedule",
            style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: TabBar(
              labelColor: Color(0xFF5A71F3),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color.fromARGB(255, 78, 98, 215),
              indicatorWeight: 3,
              tabs: [
                Tab(text: "Upcoming"),
                Tab(text: "Completed"),
                Tab(text: "Canceled"),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            AppointmentsTab(
                statusFilter: ['Confirmed', 'Pending Confirmation']),
            AppointmentsTab(statusFilter: ['Completed']),
            AppointmentsTab(statusFilter: ['Canceled']),
          ],
        ),
      ),
    );
  }
}

// Generic Appointments Tab
class AppointmentsTab extends StatelessWidget {
  final List<String> statusFilter;
  const AppointmentsTab({required this.statusFilter, super.key});

  Stream<QuerySnapshot> _getAppointments() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('appointments')
        .where('appointmentStatus', whereIn: statusFilter)
        .snapshots();
  }

  Future<String?> _getSpecialistAvatar(String specialistId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('specialists')
        .doc(specialistId)
        .get();
    return snapshot.data()?['profile_picture_url'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No appointments available"));
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String specialistId = data['specialistId'];

            return FutureBuilder<String?>(
              future: _getSpecialistAvatar(specialistId),
              builder: (context, avatarSnapshot) {
                if (avatarSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return AppointmentCard(
                  date: (data['selectedDate'] as Timestamp).toDate(),
                  time: data['selectedTimeSlot'] ?? 'N/A',
                  specialistName: data['specialistName'],
                  appointmentStatus: data['appointmentStatus'],
                  service: data['serviceName'],
                  showButtons: statusFilter.contains('Confirmed'),
                  appointmentId: (data['appointmentId']).toString(),
                  appointmentMode: data['appointmentMode'],
                  specialistId: data['specialistId'],
                  specialistAvatarUrl: avatarSnapshot.data,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final String appointmentId;
  final DateTime date;
  final String time;
  final String specialistName;
  final String appointmentStatus;
  final String appointmentMode;
  final String service;
  final bool showButtons;
  final String specialistId;
  final String? specialistAvatarUrl;

  const AppointmentCard({
    required this.appointmentId,
    required this.date,
    required this.time,
    required this.specialistName,
    required this.appointmentStatus,
    required this.appointmentMode,
    required this.service,
    required this.showButtons,
    required this.specialistId,
    this.specialistAvatarUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              appointmentId: appointmentId, // Pass appointmentId
              specialistAvatarUrl:
                  specialistAvatarUrl, // Pass specialistAvatarUrl
              date: date,
              time: time,
              specialistName: specialistName,
              service: service,
              status: appointmentStatus,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: specialistAvatarUrl != null
                        ? NetworkImage(specialistAvatarUrl!)
                        : null,
                    backgroundColor: Colors.blueAccent,
                    radius: 30,
                    child: specialistAvatarUrl == null
                        ? Text(
                            specialistName[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          specialistName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: _getStatusColor(appointmentStatus),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              appointmentStatus,
                              style: TextStyle(
                                color: _getStatusColor(appointmentStatus),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$appointmentMode Appointment',
                          style: TextStyle(
                            color: Color.fromARGB(255, 79, 53, 150),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${DateFormat('MMMM dd, yyyy').format(date)} | $time",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6D6D6D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.grey),
              Text(
                service,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6D6D6D),
                ),
              ),
              const SizedBox(height: 10),
              if (appointmentStatus == "Confirmed" ||
                  appointmentStatus == "Pending Confirmation")
                _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending Confirmation':
        return Colors.orange;
      case 'Canceled':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Action Buttons for Cancel and Reschedule
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            _showCancelConfirmationDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 232, 235, 247),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Cancel",
            style:
                TextStyle(color: Color.fromARGB(255, 59, 59, 59), fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RescheduleScreen(
                  appointmentId: appointmentId,
                  originalDate: date,
                  appointmentMode: appointmentMode,
                  specialistId: specialistId,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 90, 113, 243),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Reschedule",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Show confirmation dialog for cancellation
  void _showCancelConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Confirm Cancellation",
            style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 90, 113, 243)),
          ),
          content: const Text(
            "Are you sure you want to cancel this appointment? "
            "The payment will be refunded within 14 working days.",
            style: TextStyle(fontSize: 16.0),
          ),
          actions: [
            ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text(
                "No",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                _cancelAppointment(context);
              },
              child: const Text("Yes, Cancel",style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  // Cancel the appointment by updating its status in Firestore
  void _cancelAppointment(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Reference the specific appointment to cancel
    final appointmentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('appointments')
        .doc(appointmentId); // Use the appointmentId

    try {
      // Update the appointment status to "Canceled"
      await appointmentRef.update({
        'appointmentStatus': 'Canceled',
      });

      // Show a success message or perform additional actions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment canceled successfully.'),
        backgroundColor: Colors.green,),
      );
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: $e')),
      );
    }
  }
}
