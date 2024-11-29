import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> with SingleTickerProviderStateMixin {
  final TextEditingController feedbackController = TextEditingController();
  bool isAnonymous = false; // Track anonymous submissions
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String userType = 'Client'; // Default user type

    if (user != null && !isAnonymous) {
      if (user.email != null && user.email!.endsWith('@nutricare.com')) {
        userType = 'Specialist';
      }
    } else if (isAnonymous) {
      userType = 'Anonymous'; // Set userType to Anonymous
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Feedback',
            style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Color(0xFF5A71F3),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color.fromARGB(255, 78, 98, 215),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Send Feedback"),
              Tab(text: "Feedback Sent"),
            ],
          ),
          iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
          elevation: 0,
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedbackForm(userType, user), // Send Feedback Tab
            FeedbackSentTab(userEmail: user?.email), // Feedback Sent Tab
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackForm(String userType, User? user) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Card(
          elevation: 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: const Color.fromARGB(255, 218, 218, 218), width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We Value Your Feedback!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 90, 113, 243)),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please share your thoughts, suggestions, or any issues you encountered while using our application. Your feedback is important to us and will help us improve our services.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                if (userType != 'Specialist') // Only show if not a Specialist
                  Row(
                    children: [
                      Checkbox(
                        value: isAnonymous,
                        onChanged: (value) {
                          setState(() {
                            isAnonymous = value ?? false; // Update the state
                          });
                        },
                      ),
                      const Text(
                        'I wish to submit anonymously',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color.fromARGB(255, 90, 113, 243)),
                    ),
                    hintText: 'Enter your feedback here...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final feedback = feedbackController.text.trim(); // Remove spaces

                      if (feedback.isNotEmpty) {
                        // Store feedback in Firestore
                        Map<String, dynamic> feedbackData = {
                          'feedback': feedback, // Store trimmed feedback
                          'userType': userType, // Use determined userType
                          'timestamp': FieldValue.serverTimestamp(),
                        };

                        // Add userEmail if not anonymous
                        if (!isAnonymous && user != null) {
                          feedbackData['userEmail'] = user.email; // Save user email
                        }

                        await FirebaseFirestore.instance.collection('feedback').add(feedbackData);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Feedback sent successfully! Thank you!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        feedbackController.clear();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please enter feedback before sending.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    ),
                    child: const Text('Send Feedback'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeedbackSentTab extends StatelessWidget {
  final String? userEmail;

  const FeedbackSentTab({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    if (userEmail == null) {
      return const Center(child: Text('No user logged in.'));
    }

    // Query Firestore for all feedback
    final query = FirebaseFirestore.instance.collection('feedback');

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('timestamp', descending: true).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final feedbackDocs = snapshot.data?.docs;
        if (feedbackDocs == null || feedbackDocs.isEmpty) {
          return const Center(child: Text('No feedback sent yet.'));
        }

        // Filter feedback to show only the ones sent by the current user
        final userFeedbackDocs = feedbackDocs.where((doc) {
          final feedbackData = doc.data() as Map<String, dynamic>;
          return feedbackData['userEmail'] == userEmail;
        }).toList(); // Convert to list after filtering

        if (userFeedbackDocs.isEmpty) {
          return const Center(child: Text('No feedback sent yet.'));
        }

        return ListView.builder(
          itemCount: userFeedbackDocs.length,
          itemBuilder: (context, index) {
            final feedbackData = userFeedbackDocs[index].data() as Map<String, dynamic>;
            return FeedbackCard(
              feedback: feedbackData['feedback'],
              timestamp: feedbackData['timestamp'],
            );
          },
        );
      },
    );
  }
}

class FeedbackCard extends StatelessWidget {
  final String feedback;
  final Timestamp timestamp;

  const FeedbackCard({
    super.key,
    required this.feedback,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    String formattedTime =
        "${timestamp.toDate().toLocal().toString().split(' ')[0]} ${timestamp.toDate().toLocal().toString().split(' ')[1].split('.')[0]}";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color.fromARGB(255, 221, 222, 226), width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      feedback,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  Text(
                    'At: $formattedTime',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}