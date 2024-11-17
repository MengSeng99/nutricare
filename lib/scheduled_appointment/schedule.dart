import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import 'appointment_details.dart';
import 'package:intl/intl.dart';
import 'reschedule.dart'; // For date formatting

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }


   void _showCancellationPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Cancellation and Rescheduling Policy",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 90, 113, 243),
            ),
          ),
          content: const Text(
            "Cancellations and rescheduling can only be done at least one day before the appointment date. "
            "Please make sure to notify us in advance to avoid any penalties.",
            style: TextStyle(fontSize: 14.0),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text(
                "OK",
                style: TextStyle(color: Color.fromARGB(255, 90, 113, 243)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "Scheduled Appointments",
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
                Tab(text: "Upcoming", icon: Icon(Icons.schedule_outlined)),
                Tab(text: "Completed", icon: Icon(Icons.done)),
                Tab(text: "Canceled", icon: Icon(Icons.cancel_outlined)),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded,
                  color: Color.fromARGB(255, 90, 113, 243)),
              onPressed: () {
                _showCancellationPolicy(context); // Show the policy dialog
              },
            ),
          ],
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

Future<String?> _getSpecialistAvatar(String specialistId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('specialists')
      .doc(specialistId)
      .get();
  return snapshot.data()?['profile_picture_url'] as String?;
}

class AppointmentsTab extends StatefulWidget {
  final List<String> statusFilter;
  const AppointmentsTab({required this.statusFilter, super.key});

  @override
  _AppointmentsTabState createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  late Future<List<Map<String, dynamic>>> _appointmentsFuture;
  String _selectedSortOption = 'Appointment Date';

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = _retrieveAppointmentData();
  }

  Future<List<Map<String, dynamic>>> _retrieveAppointmentData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    List<Map<String, dynamic>> appointments = [];

    if (currentUser != null) {
      String userId = currentUser.uid;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('users', arrayContains: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        String appointmentId = doc.id;

        // Fetch details subcollection within each appointment
        QuerySnapshot detailsSnapshot = await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .collection('details')
            .get();

        for (var detailDoc in detailsSnapshot.docs) {
          Map<String, dynamic> detailData =
              detailDoc.data() as Map<String, dynamic>;

          // Only include appointments that match the status filter
          if (detailData.containsKey('appointmentStatus') &&
              widget.statusFilter.contains(detailData['appointmentStatus'])) {
            detailData['appointmentId'] = appointmentId;
            detailData['specialistId'] =
                detailData['specialistId']; // Extract from details
            appointments.add(detailData);
          }
        }
      }
    }

    // Sort appointments based on the selected option
    switch (_selectedSortOption) {
      case 'Appointment Id':
        appointments.sort((a, b) => a['appointmentId'].compareTo(b['appointmentId']));
        break;
      case 'Specialist Name':
        appointments.sort((a, b) => a['specialistName'].compareTo(b['specialistName']));
        break;
      case 'Appointment Date':
      default:
        appointments.sort((a, b) => (a['selectedDate'] as Timestamp).toDate().compareTo((b['selectedDate'] as Timestamp).toDate()));
        break;
    }

    return appointments;
  }

  void refreshAppointments() {
    setState(() {
      _appointmentsFuture = _retrieveAppointmentData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Circular card for sorting options
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30), // Make it circular
          // border: Border.all(color: Colors.grey.shade400, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16), // Padding inside card
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sort By:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 90, 113, 243),
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedSortOption,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSortOption = newValue!;
                      refreshAppointments();
                    });
                  },
                  items: <String>[
                    'Appointment Date',
                    'Specialist Name',
                    'Appointment Id',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _appointmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "No Scheduled Appointments Found",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: snapshot.data!.map((data) {
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
                        showButtons: widget.statusFilter.contains('Confirmed'),
                        appointmentId: data['appointmentId'].toString(),
                        appointmentMode: data['appointmentMode'],
                        specialistId: data['specialistId'],
                        specialistAvatarUrl: avatarSnapshot.data,
                        refreshAppointments: refreshAppointments,
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
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
  final Function refreshAppointments;

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
    required this.refreshAppointments,
    this.specialistAvatarUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Get the current date
    final currentDate = DateTime.now();

    // Calculate the difference in days
    final differenceInDays = date.difference(currentDate).inDays;

    // Check if the appointment is in the past or tomorrow
    final bool isPastOrTodayOrTomorrow = differenceInDays <= 0; // Adjusted condition

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              appointmentId: appointmentId,
              specialistAvatarUrl: specialistAvatarUrl,
              date: date,
              time: time,
              specialistName: specialistName,
              specialistId: specialistId,
              service: service,
              status: appointmentStatus,
              appointmentMode: appointmentMode,
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Appointment ID Display
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  "Appointment ID: $appointmentId",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 90, 113, 243), // Blue color
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Adjust size as needed
                  ),
                ),
              ),
              const SizedBox(height: 0), // Space between ID and specialist info
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
                _buildActionButtons(context, isPastOrTodayOrTomorrow ), // Pass the condition
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
  Widget _buildActionButtons(BuildContext context, bool isPastOrTomorrow) {
    // Common style for inactive buttons
    final inactiveStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 200, 200, 200), // Gray for disabled
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: isPastOrTomorrow 
              ? null  // Disable the button if condition is met
              : () {
                  _showCancelConfirmationDialog(context);
                },
          style: isPastOrTomorrow ? inactiveStyle : ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 232, 235, 247), // Original button color
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            "Cancel",
            style: TextStyle(
              color: isPastOrTomorrow ? Colors.grey : Color.fromARGB(255, 59, 59, 59), // Gray for inactive
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: isPastOrTomorrow ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RescheduleScreen(
                  appointmentId: appointmentId,
                  originalDate: date,
                  originalTime: time,
                  appointmentMode: appointmentMode,
                  specialistId: specialistId,
                  specialistName: specialistName,
                  onRefresh: refreshAppointments, 
                ),
              ),
            ).then((_) {
              refreshAppointments();
            });
          },
          style: isPastOrTomorrow ? inactiveStyle : ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 90, 113, 243), // Original button color
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            "Reschedule",
            style: TextStyle(
              color: isPastOrTomorrow ? Colors.grey : Colors.white, // Gray for inactive
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // Update the _showCancelConfirmationDialog to pass refreshAppointments
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
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243)),
          ),
          content: const Text(
            "Are you sure you want to cancel this appointment? "
            "The payment will be refunded within 14 working days.",
            style: TextStyle(fontSize: 14.0),
          ),
          actions: [
            TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
            child: const Text(
              "No",
              style: TextStyle(color: Color.fromARGB(255, 90, 113, 243)), // Optional color for the text
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
                _cancelAppointment(context, appointmentId); // Call cancel method
              },
              child: const Text(
                "Yes, Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
  void _cancelAppointment(BuildContext context, String appointmentId) async {
  try {
    final detailsCollectionRef = FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .collection('details');

    QuerySnapshot detailsSnapshot = await detailsCollectionRef.get();

    if (detailsSnapshot.docs.isNotEmpty) {
      DocumentReference detailDocRef = detailsSnapshot.docs.first.reference;

      await detailDocRef.update({'appointmentStatus': 'Canceled'});

      // print('Appointment status updated to Canceled successfully.');

      // Instead of using context, use the global key to show SnackBar
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Appointment canceled successfully.'),backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      // print('SnackBar displayed for cancellation success.');

      refreshAppointments();

      await _checkForChatAndCreateCancellationMessage();
    } else {
      // print('No appointment details found to update.');
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('No appointment details found.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    // print('Error canceling appointment: $e');

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Failed to cancel appointment. Please try again.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

  Future<void> _checkForChatAndCreateCancellationMessage() async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Get the reference to the chats collection
      QuerySnapshot chatSnapshot =
          await FirebaseFirestore.instance.collection('chats').get();
      bool chatFound = false;
      String? chatId;

      // Iterate through each document in the chats collection
      for (var chat in chatSnapshot.docs) {
        List<dynamic> users = chat['users'] ?? [];

        // Check if both the currentUserId and specialistId are in the users array
        if (users.contains(currentUserId) && users.contains(specialistId)) {
          chatFound = true;
          chatId = chat.id;

          // Send cancellation message
          await _sendCancellationMessage(chatId);
          return; // Exit the function after sending the message
        }
      }

      // If no chat session is found, create a new chat
      if (!chatFound) {
        // Create a new chat document
        DocumentReference newChatDoc =
            await FirebaseFirestore.instance.collection('chats').add({
          'users': [currentUserId, specialistId],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Send cancellation message
        await _sendCancellationMessage(newChatDoc.id);
      }
    } catch (e) {
      // print('Error checking chat session and creating cancel message: $e');
    }
  }

  Future<void> _sendCancellationMessage(String chatId) async {
    // Prepare the cancellation message
    String messageText = '''
Your appointment has been canceled.

Cancellation Details:
- Appointment ID: $appointmentId
- Specialist: Dr. $specialistName
- Appointment Date: ${DateFormat('yyyy-MM-dd').format(date)}
- Appointment Time: $time
- Service: $service
- Cancellation Reason: Patient request
- Cancellation Date & Time: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}

If you have any further questions or wish to reschedule, please reach out to us.
''';

    // Send the message to Firestore
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': messageText,
      'senderId': specialistId,
      'isImage': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
