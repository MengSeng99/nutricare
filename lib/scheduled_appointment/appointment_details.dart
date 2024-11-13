import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_details.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;
  final String? specialistAvatarUrl;
  final DateTime date;
  final String time;
  final String specialistName;
  final String service;
  final String status;
  final String specialistId;
  final String appointmentMode;

  const AppointmentDetailsScreen({
    required this.appointmentId,
    required this.specialistAvatarUrl,
    required this.date,
    required this.time,
    required this.specialistName,
    required this.service,
    required this.status,
    required this.specialistId,
    required this.appointmentMode,
    super.key,
  });

  @override
  _AppointmentDetailsScreenState createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Future<Map<String, dynamic>?>? _appointmentFuture;

  @override
  void initState() {
    super.initState();
    _appointmentFuture =
        _fetchAppointmentDetails(); // Load data when the screen is initialized
  }

  Future<Map<String, dynamic>?> _fetchAppointmentDetails() async {
    try {
      DocumentSnapshot appointmentSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();

      if (!appointmentSnapshot.exists) {
        return null;
      }

      Map<String, dynamic> appointmentData =
          appointmentSnapshot.data() as Map<String, dynamic>;

      // Get details from the 'details' subcollection
      QuerySnapshot detailsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .collection('details')
          .get();

      // Assuming there's only one document in the details subcollection
      if (detailsSnapshot.docs.isNotEmpty) {
        DocumentSnapshot detailDoc = detailsSnapshot.docs.first;

        // Extracting payment information
        appointmentData['amountPaid'] = detailDoc['amountPaid'];
        appointmentData['paymentCardUsed'] = detailDoc['paymentCardUsed'];
        appointmentData['createdAt'] = detailDoc['createdAt'];
      }

      DocumentSnapshot specialistDoc = await FirebaseFirestore.instance
          .collection('specialists')
          .doc(widget.specialistId)
          .get();

      List<dynamic> reviews =
          (specialistDoc.data() as Map<String, dynamic>?)?['reviews'] ?? [];

      // Filter reviews to include only those corresponding to the current appointment ID
      reviews = reviews
          .where((review) => review['appointment_id'] == widget.appointmentId)
          .toList();

      appointmentData['reviews'] = reviews;

      return appointmentData;
    } catch (e) {
      print("Error fetching appointment details: $e");
      return null;
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
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _appointmentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No appointment details found"));
          }

          var appointmentDetails = snapshot.data!;
          double amountPaid = appointmentDetails['amountPaid'] ?? 0.0;
          String paymentCardUsed =
              appointmentDetails['paymentCardUsed'] ?? 'N/A';
          Timestamp createdAt =
              appointmentDetails['createdAt'] ?? Timestamp.now();
          List<dynamic> reviews = appointmentDetails['reviews'] ?? [];

          if (widget.status == "Completed") {
            // Show dialog for rating and review
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showRatingDialogIfNotReviewed(
                  context, widget.specialistId, widget.appointmentId);
            });
          }

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
                        widget.specialistAvatarUrl ?? '',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      widget.specialistName,
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
                      widget.status,
                      style: TextStyle(
                        fontSize: 16,
                        color: _getStatusColor(widget.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoCard(
                    title: "Appointment Details",
                    children: [
                      _buildAppointmentInfo(Icons.confirmation_number_outlined,
                          "Appointment ID", widget.appointmentId),
                      _buildAppointmentInfo(Icons.check_circle_outline,
                          "Status", widget.status),
                      _buildAppointmentInfo(Icons.calendar_today, "Date",
                          DateFormat('MMMM dd, yyyy').format(widget.date)),
                      _buildAppointmentInfo(
                          Icons.access_time, "Time", widget.time),
                      _buildAppointmentInfo(Icons.miscellaneous_services,
                          "Service", widget.service),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _buildInfoCard(
                    title: "Payment Details",
                    children: [
                      _buildAppointmentInfo(Icons.attach_money,"Amount Paid", "RM $amountPaid"),
                      _buildAppointmentInfo(
                          Icons.account_balance_wallet_outlined,"Appointment Mode", widget.appointmentMode),
                      _buildAppointmentInfo(
                          Icons.credit_card,"Payment Card Used", paymentCardUsed),
                      _buildAppointmentInfo(Icons.payment,
                          "Pay On",
                          DateFormat('MMMM dd, yyyy, hh:mm a')
                              .format(createdAt.toDate())),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (reviews.isNotEmpty)
                    ...reviews
                        .map((review) => _buildReviewCard(review))
                        
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _checkForChatSession(
                            context, widget.specialistId);
                      },
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: Text(
                        "Chat with Dr. ${widget.specialistName}",
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

  Future<void> _showRatingDialogIfNotReviewed(
      BuildContext context, String specialistId, String appointmentId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Retrieve the current user's name
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    String reviewerName = userDoc['name'] ?? 'Anonymous';

    // Fetch the specialist's document
    DocumentSnapshot specialistDoc = await FirebaseFirestore.instance
        .collection('specialists')
        .doc(specialistId)
        .get();

    // Retrieve the reviews array, or default to an empty list if it doesn't exist
    List<dynamic> reviews =
        (specialistDoc.data() as Map<String, dynamic>?)?['reviews'] ?? [];

    // Check if a review exists for this appointment ID
    bool hasReviewed =
        reviews.any((review) => review['appointment_id'] == appointmentId);

    // If the user has not reviewed this appointment, show the dialog
    if (!hasReviewed) {
      await _showRatingDialog(
          context, specialistId, reviewerName, appointmentId);
      setState(() {
        _appointmentFuture =
            _fetchAppointmentDetails(); // Refresh appointment details
      });
    } else {
      print("User has already submitted a review for this appointment.");
    }
  }

  Future<void> _showRatingDialog(BuildContext context, String specialistId,
      String reviewerName, String appointmentId) {
    int? selectedRating;
    final reviewController = TextEditingController();
    bool isSubmitted = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Rate Your Appointment",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rating stars with a modern touch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < (selectedRating ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 36,
                          ),
                          splashColor: Colors.amberAccent,
                          onPressed: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    // Review TextField with rounded corners
                    TextField(
                      controller: reviewController,
                      decoration: InputDecoration(
                        labelText: "Write your review",
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 10),
                      ),
                      maxLines: 3,
                      style: const TextStyle(fontSize: 16),
                    ),
                    // Validation message with a modern style
                    if (isSubmitted &&
                        (selectedRating == null ||
                            reviewController.text.isEmpty))
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Please fill out both rating and review.',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 90, 113, 243),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () async {
                    setState(() {
                      isSubmitted = true;
                    });
                    if (selectedRating != null &&
                        reviewController.text.isNotEmpty) {
                      final currentDate =
                          DateFormat('yyyy-MM-dd').format(DateTime.now());

                      // Prepare review data with appointmentId
                      final reviewData = {
                        'date': currentDate,
                        'rating': selectedRating,
                        'review': reviewController.text,
                        'reviewer_name': reviewerName,
                        'appointment_id': appointmentId,
                      };

                      // Save to Firestore in specialists -> specialistId -> reviews array
                      await FirebaseFirestore.instance
                          .collection('specialists')
                          .doc(specialistId)
                          .set(
                              {
                            'reviews': FieldValue.arrayUnion([reviewData])
                          },
                              SetOptions(
                                  merge:
                                      true)); // Create `reviews` array if it doesn't exist

                      // Print confirmation
                      print('Review submitted: $reviewData');

                      // Close the dialog
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
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
              specialistName: widget.specialistName,
              profilePictureUrl: widget.specialistAvatarUrl ?? '',
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
            specialistName: widget.specialistName,
            profilePictureUrl: widget.specialistAvatarUrl ?? '',
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
              color: highlight ? Colors.green : Colors.blueAccent, size: 22),
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

  Widget _buildReviewCard(Map<String, dynamic> review) {
    String reviewDate = review['date'] ?? '';
    int rating = review['rating'] ?? 0;
    String reviewText = review['review'] ?? '';

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
              'Your Review',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review Date: $reviewDate',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reviewText,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
