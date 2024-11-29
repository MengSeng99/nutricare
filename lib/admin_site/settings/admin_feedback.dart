import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  // Track the currently selected view (All or Bookmarked)
  bool showBookmarks = false;

  // This could be replaced with an actual bookmark management logic
  final List<String> bookmarks = [];

  void toggleBookmark(String feedbackId) {
    setState(() {
      if (bookmarks.contains(feedbackId)) {
        bookmarks.remove(feedbackId);
      } else {
        bookmarks.add(feedbackId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          iconTheme:
              const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
          title: const Text(
            "Manage Feedback",
            style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  labelColor: Color(0xFF5A71F3),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color.fromARGB(255, 78, 98, 215),
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: "Client"),
                    Tab(text: "Specialist"),
                    Tab(text: "Anonymous"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text("All"),
                      selected: !showBookmarks,
                      onSelected: (selected) {
                        setState(() {
                          showBookmarks = false;
                        });
                      },
                      selectedColor: const Color.fromARGB(255, 90, 113, 243),
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: !showBookmarks
                            ? Colors.white
                            : const Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(100), // Fully rounded corners
                        side: BorderSide(
                          color: !showBookmarks
                              ? const Color.fromARGB(255, 90, 113, 243)
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0), // Padding around the text
                      elevation: !showBookmarks
                          ? 2
                          : 1, // Slight elevation when selected
                      pressElevation: 2, // More elevation on press
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text("Bookmarks"),
                      selected: showBookmarks,
                      onSelected: (selected) {
                        setState(() {
                          showBookmarks = true;
                        });
                      },
                      selectedColor: const Color.fromARGB(255, 90, 113, 243),
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: showBookmarks
                            ? Colors.white
                            : const Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(100), // Fully rounded corners
                        side: BorderSide(
                          color: showBookmarks
                              ? const Color.fromARGB(255, 90, 113, 243)
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0), // Padding around the text
                      elevation: showBookmarks
                          ? 2
                          : 1, // Slight elevation when selected
                      pressElevation: 2, // More elevation on press
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            FeedbackTab(
                userType: 'Client',
                showBookmarks: showBookmarks,
                bookmarks: bookmarks,
                toggleBookmark: toggleBookmark),
            FeedbackTab(
                userType: 'Specialist',
                showBookmarks: showBookmarks,
                bookmarks: bookmarks,
                toggleBookmark: toggleBookmark),
            FeedbackTab(
                userType: 'Anonymous',
                showBookmarks: showBookmarks,
                bookmarks: bookmarks,
                toggleBookmark: toggleBookmark),
          ],
        ),
      ),
    );
  }
}

class FeedbackTab extends StatelessWidget {
  final String userType;
  final bool showBookmarks;
  final List<String> bookmarks;
  final Function(String) toggleBookmark;

  const FeedbackTab(
      {super.key,
      required this.userType,
      required this.showBookmarks,
      required this.bookmarks,
      required this.toggleBookmark});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('feedback')
        .where('userType', isEqualTo: userType);

    return StreamBuilder<QuerySnapshot>(
      stream: showBookmarks
          ? (bookmarks.isNotEmpty
              ? query
                  .where(FieldPath.documentId, whereIn: bookmarks)
                  .snapshots()
              : Stream.empty()) // Use an empty stream if there are no bookmarks
          : query.orderBy('timestamp', descending: true).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // If showBookmarks is true and bookmarks are empty, show message
        if (showBookmarks && bookmarks.isEmpty) {
          return const Center(
              child: Text('No feedback added to your bookmark.'));
        }

        final feedbackDocs = snapshot.data?.docs;

        // If no feedback is available
        if (feedbackDocs == null || feedbackDocs.isEmpty) {
          return const Center(child: Text('No feedback available.'));
        }

        return ListView.builder(
          itemCount: feedbackDocs.length,
          itemBuilder: (context, index) {
            final feedbackData =
                feedbackDocs[index].data() as Map<String, dynamic>;
            return FeedbackCard(
              feedback: feedbackData['feedback'],
              timestamp: feedbackData['timestamp'],
              userEmail: feedbackData['userEmail'],
              feedbackId: feedbackDocs[index].id,
              isBookmarked: bookmarks.contains(feedbackDocs[index].id),
              toggleBookmark: toggleBookmark,
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
  final String? userEmail; // Make userEmail nullable
  final String feedbackId; // Feedback ID to manage bookmarks
  final bool isBookmarked; // Check if this feedback is bookmarked
  final Function(String) toggleBookmark; // Function to toggle bookmark

  const FeedbackCard({
    super.key,
    required this.feedback,
    required this.timestamp,
    this.userEmail, // Allow it to be null
    required this.feedbackId,
    required this.isBookmarked,
    required this.toggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    // Convert the Timestamp to a readable format
    String formattedTime =
        "${timestamp.toDate().toLocal().toString().split(' ')[0]} "
        "${timestamp.toDate().toLocal().toString().split(' ')[1].split('.')[0]}";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Color.fromARGB(255, 221, 222, 226), width: 1),
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
                  // Feedback Text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      feedback,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Show user email only if it's not anonymous
                  if (userEmail?.isNotEmpty == true) ...[
                    Text(
                      'By: $userEmail',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(
                            0xFF5A71F3), // A modern blue color for the email
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Display the timestamp
                  Text(
                    'At: $formattedTime',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Bookmark Icon
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? const Color(0xFF5A71F3) : Colors.grey,
                  ),
                  onPressed: () => toggleBookmark(feedbackId),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () => _showDeleteConfirmationDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Confirm Deletion",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 90, 113, 243))),
          content: const Text("Are you sure you want to delete this feedback?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () async {
                // Delete feedback from Firestore
                await FirebaseFirestore.instance
                    .collection('feedback')
                    .doc(feedbackId)
                    .delete()
                    .then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Feedback deleted successfully."),
                    ),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error deleting feedback: $error"),
                    ),
                  );
                });
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child:
                  const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
