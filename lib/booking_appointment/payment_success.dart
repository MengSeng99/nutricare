import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // for formatting date
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current user ID
import 'dart:math';

// Assuming there's MainScreen imported
import '../main/navigation_bar.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String specialistName;
  final DateTime selectedDate;
  final String? selectedTimeSlot;
  final String appointmentMode;
  final double amountPaid;
  final String serviceName;
  final String paymentCardUsed;
  final String appointmentStatus;
  final String specialistId;

  const PaymentSuccessScreen({
    super.key,
    required this.specialistId,
    required this.specialistName,
    required this.selectedDate,
    this.selectedTimeSlot,
    required this.appointmentMode,
    required this.amountPaid,
    required this.serviceName,
    required this.paymentCardUsed,
    required this.appointmentStatus,
  });

  @override
  _PaymentSuccessScreenState createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  late String appointmentId;

  @override
  void initState() {
    super.initState();
    appointmentId = _generateAppointmentId(); // Generate appointment ID on initialization
  }

  // Function to generate a random 4-digit appointment ID
  String _generateAppointmentId() {
    Random random = Random();
    int id = 1000 + random.nextInt(9000); // Generates a random number between 1000 and 9999
    return id.toString(); // Convert to string for easier display and storage
  }

  Future<void> _deleteSelectedTimeSlot() async {
    // Prepare the selected date string
    String selectedDateString = widget.selectedDate.toIso8601String().split('T')[0];

    // Reference to the date slots collection for the specialist
    final docRef = FirebaseFirestore.instance
        .collection('specialists')
        .doc(widget.specialistId)
        .collection('appointments')
        .doc(widget.appointmentMode); // Use the appointment mode to find the appropriate document

    // Fetch the document
    DocumentSnapshot docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final dateSlots = Map<String, dynamic>.from(data['date_slots'] ?? {});

      // Check the selected date
      if (dateSlots.containsKey(selectedDateString)) {
        List<String> timeSlots = List<String>.from(dateSlots[selectedDateString] ?? []);
        
        // Remove the selected time slot
        timeSlots.remove(widget.selectedTimeSlot);

        // If the timeSlots array is empty, remove the date entry
        if (timeSlots.isEmpty) {
          dateSlots.remove(selectedDateString);
        } else {
          // Update the time slots for that date
          dateSlots[selectedDateString] = timeSlots;
        }

        // Update Firestore document with the modified date slots
        await docRef.update({'date_slots': dateSlots});
      }
    }
  }

  Future<void> _checkForChatAndCreateMessage(BuildContext context) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID

    try {
      // Get the reference to the chats collection
      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance.collection('chats').get();
      bool chatFound = false;
      String chatId;

      // Iterate through each document in the chats collection
      for (var chat in chatSnapshot.docs) {
        List<dynamic> users = chat['users'] ?? [];

        // Check if both the currentUserId and specialistId are in the users array
        if (users.contains(currentUserId) && users.contains(widget.specialistId)) {
          chatFound = true;
          chatId = chat.id;

          // Send message with appointment details
          await _sendAppointmentMessage(chatId, appointmentId, widget.specialistId);
          return; // Exit the function after sending the message
        }
      }

      // If no chat session is found, create a new chat
      if (!chatFound) {
        // Create a new chat document
        DocumentReference newChatDoc = await FirebaseFirestore.instance.collection('chats').add({
          'users': [currentUserId, widget.specialistId],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Send message with appointment details
        await _sendAppointmentMessage(newChatDoc.id, appointmentId, widget.specialistId);
      }
    } catch (e) {
      // print('Error checking chat session and creating message: $e');
    }
  }

  Future<void> _sendAppointmentMessage(String chatId, String appointmentId, String specialistId) async {
    // Prepare the success message for appointment confirmation
    String messageText = '''
Your appointment has been successfully booked!

Appointment Details:
- Appointment ID: $appointmentId
- Specialist: Dr. ${widget.specialistName}
- Date: ${DateFormat('yyyy-MM-dd').format(widget.selectedDate)}
- Time: ${widget.selectedTimeSlot ?? 'N/A'}
- Mode: ${widget.appointmentMode}
- Amount Paid: RM ${widget.amountPaid.toStringAsFixed(2)}
- Service: ${widget.serviceName}
- Status: ${widget.appointmentStatus}

Please review the details above and let us know if you spot any errors.
''';

    // Send the message to Firestore
    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({
      'text': messageText,
      'senderId': specialistId, // Set the sender ID to specialist ID
      'isImage': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: MediaQuery.of(context).size.height * 0.10),
                      const SizedBox(height: 10),
                      Text(
                        "Payment Successful!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionCard("Appointment Summary", [
                  _buildSummaryRow("Appointment ID", appointmentId), // Display Appointment ID
                  _buildSummaryRow("Specialist", "Dr. ${widget.specialistName}"),
                  _buildSummaryRow(
                      "Date", DateFormat('yyyy-MM-dd').format(widget.selectedDate)),
                  _buildSummaryRow("Time", widget.selectedTimeSlot ?? 'N/A'),
                  _buildSummaryRow("Appointment Mode", widget.appointmentMode),
                ]),
                const SizedBox(height: 10),
                _buildSectionCard("Service", [
                  _buildSummaryRow("Service", widget.serviceName),
                ]),
                const SizedBox(height: 10),
                _buildSectionCard("Payment Details", [
                  _buildSummaryRow("Payment Card", widget.paymentCardUsed),
                  _buildSummaryRow(
                      "Amount Paid", "RM ${widget.amountPaid.toStringAsFixed(2)}"),
                ]),
                const SizedBox(height: 10),
                _buildSectionCard("Appointment Status", [
                  _buildStatus(widget.appointmentStatus),
                ]),
                const SizedBox(height: 10),
                _buildDoneButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 90, 113, 243)),
            ),
            const SizedBox(height: 10),
            ...children,
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(String status) {
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case "Confirmed":
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case "Pending Confirmation":
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_bottom;
        break;
      case "Canceled":
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 24),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDoneButton(BuildContext context) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () async {
        // Show loading indicator dialog
        showDialog(
          context: context,
          barrierDismissible: false,  // Prevent dismissal of dialog by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),  // Loading indicator
                  SizedBox(width: 20),          // Add some spacing
                  Text("Processing, please wait..."), // Loading message
                ],
              ),
            );
          },
        );

        // Invoke the function to delete the selected time slot before creating the appointment.
        await _deleteSelectedTimeSlot();

        // Invoke the function to check for chat and create a message.
        await _checkForChatAndCreateMessage(context);

        User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          String userId = currentUser.uid;

          // Create the appointment data to save to Firestore
          Map<String, dynamic> appointmentData = {
            'appointmentId': appointmentId, // Add the appointment ID
            'specialistId': widget.specialistId,
            'specialistName': widget.specialistName,
            'selectedDate': widget.selectedDate,
            'selectedTimeSlot': widget.selectedTimeSlot,
            'appointmentMode': widget.appointmentMode,
            'amountPaid': widget.amountPaid,
            'serviceName': widget.serviceName,
            'paymentCardUsed': widget.paymentCardUsed,
            'appointmentStatus': widget.appointmentStatus,
            'createdAt': DateTime.now(), // Add a timestamp
          };

          // Save the appointment data to Firestore
          await FirebaseFirestore.instance
              .collection('appointments')   // Main collection for appointments
              .doc(appointmentId)           // Document ID is the appointmentId
              .set({
                'users': [userId, widget.specialistId], // Add user IDs to the main appointment document
              });

          // Add appointment details to a subcollection called 'details'
          await FirebaseFirestore.instance
              .collection('appointments')
              .doc(appointmentId)
              .collection('details')
              .add(appointmentData); // Append details to subcollection

          // Dismiss loading dialog before navigating
          Navigator.of(context).pop(); // This will close the loading dialog
          
          // Navigate back to the schedule screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen(initialIndex: 2)), // Assuming index 2 is the schedule screen
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(
        "Done",
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
}