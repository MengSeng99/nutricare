import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../main.dart';
import '../client_management/client_details.dart';

class SpecialistAppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;
  final DateTime date;
  final String time;
  final String appointmentMode;
  final String appointmentStatus; // Change to allow updates
  final String service;
  final String clientName;
  final String clientProfilePic;
  final double amountPaid;
  final String paymentCardUsed;
  final DateTime createdAt;
  final String clientId;
  final Function onRefresh;

  const SpecialistAppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
    required this.date,
    required this.time,
    required this.appointmentMode,
    required this.appointmentStatus,
    required this.service,
    required this.clientName,
    required this.clientProfilePic,
    required this.amountPaid,
    required this.paymentCardUsed,
    required this.createdAt,
    required this.clientId,
    required this.onRefresh,
  });

  @override
  _SpecialistAppointmentDetailsScreenState createState() =>
      _SpecialistAppointmentDetailsScreenState();
}

class _SpecialistAppointmentDetailsScreenState
    extends State<SpecialistAppointmentDetailsScreen> {
  late String appointmentStatus;

  @override
  void initState() {
    super.initState();
    // Initialize the appointment status from the widget's property
    appointmentStatus = widget.appointmentStatus;
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Client Information Card with Click Navigation
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClientDetailsScreen(
                      clientId: widget.clientId,
                      clientName: widget.clientName,
                    ),
                  ),
                );
              },
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: widget.clientProfilePic.isNotEmpty
                            ? NetworkImage(widget.clientProfilePic)
                            : null,
                        radius: 35,
                        child: widget.clientProfilePic.isEmpty
                            ? Text(
                                widget.clientName.isNotEmpty
                                    ? widget.clientName[0]
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 50),
                      Expanded(
                        child: Text(
                          widget.clientName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.navigate_next_outlined,
                          color: Color.fromARGB(255, 90, 113, 243), size: 35),
                    ],
                  ),
                ),
              ),
            ),

            // Appointment Information Card
            _buildInfoCard(
              title: "Appointment Details",
              children: [
                _buildAppointmentInfo(Icons.confirmation_number_outlined,
                    "Appointment ID", widget.appointmentId),
                _buildAppointmentInfo(
                    Icons.check_circle_outline, "Status", appointmentStatus),
                _buildAppointmentInfo(Icons.calendar_today, "Date",
                    DateFormat('MMMM dd, yyyy').format(widget.date)),
                _buildAppointmentInfo(Icons.access_time, "Time", widget.time),
                _buildAppointmentInfo(
                    widget.appointmentMode == "Physical"
                        ? Icons.people_alt_outlined
                        : Icons.video_call_outlined,
                    "Appointment Mode",
                    widget.appointmentMode),
                _buildAppointmentInfo(
                    Icons.miscellaneous_services, "Service", widget.service),
              ],
            ),
            // Payment Information Card
            _buildInfoCard(
              title: "Payment Details",
              children: [
                _buildAppointmentInfo(Icons.attach_money, "Amount Paid",
                    "\$${widget.amountPaid.toStringAsFixed(2)}"),
                _buildAppointmentInfo(Icons.credit_card, "Payment Card Used",
                    widget.paymentCardUsed),
                _buildAppointmentInfo(
                    Icons.date_range_outlined,
                    "Pay On",
                    DateFormat('MMMM dd, yyyy, hh:mm a')
                        .format(widget.createdAt)),
              ],
            ),
            // At the bottom of the build method
            const SizedBox(height: 20),
// Appointment Complete Button only visible if appointmentStatus is 'Confirmed'
            if (appointmentStatus == 'Confirmed') ...[
              Center(
                child: ElevatedButton(
                  onPressed: () => _showCompleteConfirmationDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 90, 113, 243),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: const Text(
                    "Mark as Completed",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ]
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentInfo(IconData icon, String title, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon,
              color: highlight ? Colors.green : Color.fromARGB(255, 90, 113, 243), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6D6D6D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                color: highlight ? Colors.green : Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteConfirmationDialog(BuildContext context) {
    // Convert the appointment time to DateTime
    String dateTimeString =
        "${DateFormat("MMMM dd, yyyy").format(widget.date)} ${widget.time}";

    // Log the complete datetime string to debug
    // print("Complete dateTime string: $dateTimeString");

    try {
      DateTime appointmentDateTime =
          DateFormat("MMMM dd, yyyy hh:mm a").parse(dateTimeString);
      DateTime currentDateTime = DateTime.now();

      // Check if the appointment's time has passed
      if (appointmentDateTime.isBefore(currentDateTime)) {
        // Show the dialog if the appointment time has passed
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              "Confirm Completion",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 90, 113, 243)),
            ),
            content: const Text(
              "Please ensure you have completed the appointment before proceeding. Do you want to mark this appointment as completed?",
              style: TextStyle(fontSize: 14.0),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  _markAppointmentAsComplete(context); // Mark as complete
                },
                child: const Text("Yes, Proceed",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        // Show a warning if the appointment time has not passed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "You cannot mark this appointment as completed yet. Please wait until the scheduled time has passed."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Log the exception to understand the parsing issue
      // print("Error parsing date and time: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Error parsing appointment date and time. Please check the format."),
        ),
      );
    }
  }

  Future<void> _markAppointmentAsComplete(BuildContext context) async {
    try {
      // First, update the appointment status in the main appointment document
      final appointmentDocRef = FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId);

      // Update the appointment status to 'Completed'
      await appointmentDocRef.update({'appointmentStatus': 'Completed'});

      // Now, reference the details subcollection of the appointment
      final detailsCollectionRef = appointmentDocRef.collection('details');

      // Get the details snapshot
      QuerySnapshot detailsSnapshot = await detailsCollectionRef.get();

      if (detailsSnapshot.docs.isNotEmpty) {
        // Get the reference to the first document in the details subcollection
        DocumentReference detailDocRef = detailsSnapshot.docs.first.reference;

        // Update the appointment status to 'Completed' in the details subcollection
        await detailDocRef.update({'appointmentStatus': 'Completed'});

        // Update internal state to reflect changes
        setState(() {
          appointmentStatus = 'Completed'; // Update status in the UI
        });

        // Show a success message
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Appointment marked as completed successfully.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        widget.onRefresh();
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
      // print('Error marking appointment as completed: $e');

      // Show an error message in case of failure
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
              'Failed to mark appointment as completed. Please try again.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
