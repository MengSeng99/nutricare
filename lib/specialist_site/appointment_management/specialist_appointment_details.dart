import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart';
import '../client_management/client_details.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

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

  Future<void> _uploadReport(String appointmentId) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    PlatformFile file = result.files.first;

    try {
      _showProcessingDialog(); // Show processing dialog

      Reference ref = FirebaseStorage.instance
          .ref()
          .child('reports/$appointmentId/${file.name}');

      UploadTask uploadTask = ref.putFile(File(file.path!));
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      String fileId = file.name; // Unique ID for the file
      DateTime uploadTime = DateTime.now();

      final detailsCollectionRef = FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .collection('details');

      QuerySnapshot detailsSnapshot = await detailsCollectionRef.get();

      if (detailsSnapshot.docs.isNotEmpty) {
        DocumentReference detailDocRef = detailsSnapshot.docs.first.reference;

        await detailDocRef.update({
          'reports': FieldValue.arrayUnion([
            {
              'fileId': fileId,
              'filePath': downloadUrl,
              'uploadTime': uploadTime,
            },
          ]),
        });

        // Hide the processing dialog
        _dismissProcessingDialog();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report uploaded successfully!')),
        );

        setState(() {
          // This will re-trigger the FutureBuilder to fetch reports again on the next build
        });
      }
    } catch (e) {
      _dismissProcessingDialog(); // Hide the dialog on error

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload report: $e')),
      );
    }
  }
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
                    "RM ${widget.amountPaid.toStringAsFixed(2)}"),
                _buildAppointmentInfo(Icons.credit_card, "Payment Card Used",
                    widget.paymentCardUsed),
                _buildAppointmentInfo(
                    Icons.date_range_outlined,
                    "Pay On",
                    DateFormat('MMMM dd, yyyy, hh:mm a')
                        .format(widget.createdAt)),
              ],
            ),

            // At the appropriate place in your build method, right after the Payment Information Card
            if (appointmentStatus == 'Completed') ...[
              Center(
                child: ElevatedButton(
                  onPressed: () => _uploadReport(widget.appointmentId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 90, 113, 243),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: const Text(
                    "Upload Report",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],

            _buildReportsSection(),
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

  void _showProcessingDialog() {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (context) {
      return AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Uploading report, please wait...')),
          ],
        ),
      );
    },
  );
}

void _dismissProcessingDialog() {
  Navigator.of(context, rootNavigator: true).pop();
}

  void _refreshReports() {
    setState(() {
    });
  }

Widget _buildReportsSection() {
  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .collection('details')
        .limit(1)
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(
            child: Text('Error fetching reports: ${snapshot.error}'));
      }

      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
        var doc = snapshot.data!.docs.first.data() as Map<String, dynamic>?;

        var reports = doc?['reports'] as List<dynamic>?;
        if (reports == null || reports.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Uploaded Reports:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            ...reports.map((report) {
              String filePath = report['filePath'];
              String fileId = report['fileId'];
              DateTime uploadTime = report['uploadTime'].toDate(); // Convert Firestore Timestamp

              return Dismissible(
                key: Key(fileId), // Use fileId as the key
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirmationDialog(context);
                },
                onDismissed: (direction) async {
                  await _deleteReport(fileId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Report deleted successfully.')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    onTap: () async {
                      // Launch the URL using the filePath
                      if (await canLaunch(filePath)) {
                        await launch(filePath);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not launch $filePath')),
                        );
                      }
                    },
                    child: Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file,
                                color: Color.fromARGB(255, 90, 113, 243),
                                size: 36), // Icon for documents
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileId, // Display the fileId
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Uploaded on: ${DateFormat('yyyy-MM-dd – kk:mm').format(uploadTime)}', // Display upload time
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward,
                                color: Colors.grey), // Arrow indicating action
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }

      return SizedBox.shrink(); // Return empty widget if there is no document
    },
  );
}

Future<void> _deleteReport(String fileId) async {
  try {
    // Access the details collection reference
    final detailsCollectionRef = FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .collection('details');

    // Get the details snapshot
    QuerySnapshot detailsSnapshot = await detailsCollectionRef.get();

    // Check if there's at least one document
    if (detailsSnapshot.docs.isNotEmpty) {
      DocumentReference detailDocRef = detailsSnapshot.docs.first.reference;

      // Fetch the report data
      var docData = detailsSnapshot.docs.first.data() as Map<String, dynamic>;
      var reports = docData['reports'] as List<dynamic>;

      // Find the report by fileId to get its filePath
      String? filePath;
      
      for (var report in reports) {
        if (report['fileId'] == fileId) {
          filePath = report['filePath'];
        }
      }

      if (filePath != null) {
        // Delete the file from Firebase Storage
        await FirebaseStorage.instance.refFromURL(filePath).delete();

        // Remove the report from Firestore
        reports.removeWhere((report) => report['fileId'] == fileId);
        await detailDocRef.update({'reports': reports});

        _refreshReports();
        // Notify the user about the successful deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report deleted successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No matching report found for deletion.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No report details found for deletion.')),
      );
    }
  } catch (e) {
    print('Error deleting report: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete report: $e')),
    );
  }
}

Future<bool> _showDeleteConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
         shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Delete Report",
            style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 90, 113, 243)),
          ),
        content: Text('Are you sure you want to delete this report?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  ).then((value) => value ?? false); // Handle the case when null is returned
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
              color:
                  highlight ? Colors.green : Color.fromARGB(255, 90, 113, 243),
              size: 22),
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
    // Combine date and time into a single string
    String dateTimeString =
        "${DateFormat("MMMM dd, yyyy").format(widget.date)} ${widget.time}";

    print("DateTime String: $dateTimeString"); // Debugging line

    try {
      // Use HH:mm for 24-hour format
      DateTime appointmentDateTime =
          DateFormat("MMMM dd, yyyy HH:mm").parse(dateTimeString);
      DateTime currentDateTime = DateTime.now();

      // Check if the appointment's time has passed
      if (appointmentDateTime.isBefore(currentDateTime)) {
        // Show the dialog if the appointment time has passed
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
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
      print("Error parsing date and time: $e"); // Log the error for debugging

      // Show an error message in case of failure
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
      // Fetch the distribution rate from Firestore
      double distributionRate = await _fetchDistributionRate();

      // Calculate earnings for the specialist
      double earnings = widget.amountPaid * distributionRate;

      // Get the current specialist (user) ID from Firebase Auth
      String specialistId = FirebaseAuth.instance.currentUser!.uid;

      // Now, update the appointment status in the main appointment document
      final appointmentDocRef = FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId);

      // Reference the details subcollection of the appointment
      final detailsCollectionRef = appointmentDocRef.collection('details');

      // Get the details snapshot
      QuerySnapshot detailsSnapshot = await detailsCollectionRef.get();

      if (detailsSnapshot.docs.isNotEmpty) {
        // Get the reference to the first document in the details subcollection
        DocumentReference detailDocRef = detailsSnapshot.docs.first.reference;

        // Update the appointment status to 'Completed' in the details subcollection
        await detailDocRef.update({'appointmentStatus': 'Completed'});

        // Save the earnings to the specialist's earnings subcollection
        final earningsDocRef = FirebaseFirestore.instance
            .collection('specialists')
            .doc(specialistId)
            .collection('earnings')
            .doc(); // This will auto-generate a document ID

        await earningsDocRef.set({
          'appointmentId': widget.appointmentId,
          'clientName': widget.clientName,
          'service': widget.service,
          'totalAmount': widget.amountPaid,
          'rate': distributionRate,
          'amount': earnings,
          'date': DateTime.now(),
        });

        // Update internal state to reflect changes
        setState(() {
          appointmentStatus = 'Completed'; // Update status in the UI
        });

        // Show a success message
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
                'Appointment marked as completed successfully.\nEarnings calculated: RM ${earnings.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        widget.onRefresh();
      } else {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('No appointment details found.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
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

  Future<double> _fetchDistributionRate() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('rates')
          .doc('current_rate_doc') // Update with your document ID for the rate
          .get();
      if (snapshot.exists) {
        return snapshot.data()?['rate'] ?? 1.0; // Default to 100% if not set
      }
    } catch (e) {
      print("Error fetching distribution rate: $e");
    }
    return 1.0; // Return 100% as default in case of error
  }
}
