import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import '../../scheduled_appointment/reschedule.dart';
import 'specialist_appointment_details.dart';

class SpecialistSchedulesScreen extends StatefulWidget {
  const SpecialistSchedulesScreen({super.key});

  @override
  _SpecialistSchedulesScreenState createState() => _SpecialistSchedulesScreenState();
}

class _SpecialistSchedulesScreenState extends State<SpecialistSchedulesScreen> with TickerProviderStateMixin {
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
        ),
        body: const TabBarView(
          children: [
            AppointmentsTab(statusFilter: ['Confirmed', 'Pending Confirmation']),
            AppointmentsTab(statusFilter: ['Completed']),
            AppointmentsTab(statusFilter: ['Canceled']),
          ],
        ),
      ),
    );
  }
}

class AppointmentsTab extends StatefulWidget {
  final List<String> statusFilter;
  const AppointmentsTab({required this.statusFilter, super.key});

  @override
  _AppointmentsTabState createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  late Future<List<Map<String, dynamic>>> _appointmentsFuture;
  String _selectedSortOption = 'Appointment Date'; // Default sort option

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
        List<dynamic> usersArray = doc['users'] ?? [];

        if (usersArray.isNotEmpty) {
          String clientId = usersArray[0];

          DocumentSnapshot clientDocSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(clientId)
              .get();

          String clientName = (clientDocSnapshot.data() as Map<String, dynamic>)['name'] ?? 'Unknown';
          String clientProfilePic = (clientDocSnapshot.data() as Map<String, dynamic>)['profile_pic'] ?? '';

          QuerySnapshot detailsSnapshot = await FirebaseFirestore.instance
              .collection('appointments')
              .doc(appointmentId)
              .collection('details')
              .get();

          for (var detailDoc in detailsSnapshot.docs) {
            Map<String, dynamic> detailData = detailDoc.data() as Map<String, dynamic>;

            if (detailData.containsKey('appointmentStatus') &&
                widget.statusFilter.contains(detailData['appointmentStatus'])) {
              detailData['clientId'] = clientId;
              detailData['appointmentId'] = appointmentId;
              detailData['clientName'] = clientName;
              detailData['clientProfilePic'] = clientProfilePic;
              detailData['amountPaid'] = detailData['amountPaid'] ?? 0;
              detailData['paymentCardUsed'] = detailData['paymentCardUsed'] ?? 'N/A';
              detailData['createdAt'] = (detailData['createdAt'] as Timestamp).toDate();
              appointments.add(detailData);
            }
          }
        }
      }
    }

    // Sort appointments based on the selected option
    switch (_selectedSortOption) {
      case 'Appointment Id':
        appointments.sort((a, b) => a['appointmentId'].compareTo(b['appointmentId']));
        break;
      case 'Client Name':
        appointments.sort((a, b) => a['clientName'].compareTo(b['clientName']));
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
      _appointmentsFuture = _retrieveAppointmentData(); // Refresh data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sort Dropdown
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
                  return AppointmentCard(
                    appointmentId: data['appointmentId'],
                    date: (data['selectedDate'] as Timestamp).toDate(),
                    time: data['selectedTimeSlot'] ?? 'N/A',
                    appointmentMode: data['appointmentMode'],
                    appointmentStatus: data['appointmentStatus'],
                    service: data['serviceName'],
                    clientName: data['clientName'],
                    clientProfilePic: data['clientProfilePic'],
                    amountPaid: data['amountPaid'],
                    paymentCardUsed: data['paymentCardUsed'],
                    createdAt: data['createdAt'],
                    clientId: data['clientId'],
                    specialistName: data['specialistName'],
                    refreshAppointments: refreshAppointments,
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
  final String appointmentStatus;
  final String service;
  final String clientName; 
  final String clientProfilePic;
  final String appointmentMode;
  final double amountPaid;
  final String paymentCardUsed; 
  final DateTime createdAt; 
  final String clientId;
  final Function refreshAppointments;
  final String specialistName;

  const AppointmentCard({
    required this.appointmentId,
    required this.date,
    required this.time,
    required this.appointmentStatus,
    required this.service,
    required this.clientName,
    required this.clientProfilePic,
    required this.appointmentMode,
    required this.amountPaid,
    required this.paymentCardUsed,
    required this.createdAt,
    required this.clientId,
    required this.refreshAppointments,
    required this.specialistName,
    super.key,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending Confirmation':
        return Colors.orange;
      case 'Canceled':
        return Colors.red;
      case 'Completed':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpecialistAppointmentDetailsScreen(
              clientId: clientId,
              appointmentId: appointmentId,
              date: date,
              time: time,
              appointmentMode: appointmentMode,
              appointmentStatus: appointmentStatus,
              service: service,
              clientName: clientName,
              clientProfilePic: clientProfilePic,
              amountPaid: amountPaid, // Pass amountPaid
              paymentCardUsed: paymentCardUsed, // Pass paymentCardUsed
              createdAt: createdAt, // Pass createdAt
              onRefresh: refreshAppointments,
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
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  "Appointment ID: $appointmentId",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 90, 113, 243),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 0),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: clientProfilePic.isNotEmpty
                        ? NetworkImage(clientProfilePic)
                        : null,
                    backgroundColor: Colors.blueAccent,
                    radius: 30,
                    child: clientProfilePic.isEmpty
                        ? Text(
                            clientName.isNotEmpty ? clientName[0] : '?',
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
                          clientName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          style: const TextStyle(
                            color: Color.fromARGB(255, 79, 53, 150),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${DateFormat('MMMM dd, yyyy').format(date)} | $time",
                          style: const TextStyle(fontSize: 16, color: Color(0xFF6D6D6D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.grey),
              Text(
                service,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6D6D6D)),
              ),
              const SizedBox(height: 10),
              if (appointmentStatus == "Confirmed" || appointmentStatus == "Pending Confirmation") 
                _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildActionButtons(BuildContext context) {
  // Get the current date
  final currentDate = DateTime.now();

  // Calculate the difference in days
  final differenceInDays = date.difference(currentDate).inDays;

  // Check if the appointment is in the past, today, or tomorrow
  final bool isPastOrTodayOrTomorrow = differenceInDays <= 0; // Adjusted condition

  // Define common styles for inactive buttons
  final Color inactiveColor = Colors.grey; // Inactive color
  final Color textColor = isPastOrTodayOrTomorrow ? Colors.grey : Colors.white; 

  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ElevatedButton(
        onPressed: isPastOrTodayOrTomorrow
            ? null // Disable the button
            : () => _showCancelConfirmationDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPastOrTodayOrTomorrow ? inactiveColor : const Color.fromARGB(255, 232, 235, 247),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          "Cancel",
          style: TextStyle(
            color: textColor,
            fontSize: 16,
          ),
        ),
      ),
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: isPastOrTodayOrTomorrow
            ? null // Disable the button
            : () async {
                String specialistId = FirebaseAuth.instance.currentUser!.uid;
                DocumentSnapshot specialistDoc =
                    await FirebaseFirestore.instance
                        .collection('specialists')
                        .doc(specialistId)
                        .get();
                String specialistName = (specialistDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';

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
        style: ElevatedButton.styleFrom(
          backgroundColor: isPastOrTodayOrTomorrow ? inactiveColor : const Color.fromARGB(255, 90, 113, 243),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          "Reschedule",
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      ),
    ],
  );
}

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
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
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
        if (users.contains(currentUserId) && users.contains(clientId)) {
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
          'users': [clientId, currentUserId],
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
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

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
      'senderId': currentUserId,
      'isImage': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}