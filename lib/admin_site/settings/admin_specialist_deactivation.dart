import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminEnquiryReviewScreen extends StatefulWidget {
  const AdminEnquiryReviewScreen({super.key});

  @override
  _AdminEnquiryReviewScreenState createState() =>
      _AdminEnquiryReviewScreenState();
}

class _AdminEnquiryReviewScreenState extends State<AdminEnquiryReviewScreen> {
  List<Map<String, dynamic>> _enquiries = [];
  bool _loading = true;
  String _selectedStatus = 'All'; // Track the selected status

  @override
  void initState() {
    super.initState();
    _fetchEnquiries();
  }

  Future<void> _fetchEnquiries() async {
    try {
      final enquirySnapshot = await FirebaseFirestore.instance
          .collection('specialist_deactivation_enquiries')
          .get();

      List<Map<String, dynamic>> enquiries = [];

      for (var doc in enquirySnapshot.docs) {
        var enquiryData = doc.data();
        var specialistId = enquiryData['specialistId'];

        // Fetch the specialist data
        var specialistDoc = await FirebaseFirestore.instance
            .collection('specialists')
            .doc(specialistId)
            .get();

        if (specialistDoc.exists) {
          var specialistData = specialistDoc.data() as Map<String, dynamic>;
          enquiryData['specialist'] = specialistData; // Add specialist data to enquiry
        }

        enquiries.add(enquiryData);
      }

      setState(() {
        _enquiries = enquiries;
      });
    } catch (e) {
      // print("Error fetching enquiries: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _updateEnquiryStatus(String specialistId, String status) async {
    try {
      // Get the current date and time
      DateTime now = DateTime.now();

      await FirebaseFirestore.instance
          .collection('specialist_deactivation_enquiries')
          .doc(specialistId)
          .update({
        'status': status,
        'updatedDate': now, // Store the updated date and time
      });

      // Fetch the enquiries again to update the list
      _fetchEnquiries();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update enquiry status.")),
      );
    }
  }

  void _showConfirmationDialog(String specialistId, String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text("Confirm $action",
              style: const TextStyle(
                  color: Color.fromARGB(255, 90, 113, 243),
                  fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to $action this enquiry?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 90, 113, 243),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _updateEnquiryStatus(specialistId,
                    action == 'approve' ? 'Approved' : 'Rejected');
              },
              child: Text("Yes, $action",
                  style: const TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'Rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'Pending':
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      default:
        return const Icon(Icons.error, color: Colors.grey);
    }
  }

  List<Map<String, dynamic>> _filteredEnquiries() {
  List<Map<String, dynamic>> filteredEnquiries;

  // Filter by selected status first
  if (_selectedStatus == 'All') {
    filteredEnquiries = _enquiries;
  } else {
    filteredEnquiries = _enquiries
        .where((enquiry) => enquiry['status'] == _selectedStatus)
        .toList();
  }

  // Sort by status: 'Pending' first, then by submission date
  filteredEnquiries.sort((a, b) {
    // Compare status; bring 'Pending' to the front
    if (a['status'] == 'Pending' && b['status'] != 'Pending') {
      return -1;  // 'a' comes before 'b'
    } else if (a['status'] != 'Pending' && b['status'] == 'Pending') {
      return 1;  // 'b' comes before 'a'
    } else {
      // If both have the same status, sort by submission date
      return (a['submittedDate'] as Timestamp).compareTo(b['submittedDate'] as Timestamp);
    }
  });

  return filteredEnquiries;
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<Map<String, dynamic>> filteredEnquiries = _filteredEnquiries();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Deactivation Enquiries",
            style: TextStyle(
                color: Color.fromARGB(255, 90, 113, 243),
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 0.5, color: Color.fromARGB(255, 220, 220, 241)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row of ChoiceChips for filtering
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ChoiceChip(
                    label: const Text("All"),
                    selected: _selectedStatus == 'All',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStatus = 'All';
                        });
                      }
                    },
                    selectedColor: const Color.fromARGB(255, 90, 113, 243),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedStatus == 'All'
                          ? Colors.white
                          : const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(
                        color: _selectedStatus == 'All'
                            ? const Color.fromARGB(255, 90, 113, 243)
                            : Colors.transparent,
                        width: 2.0,
                      ),
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    elevation: _selectedStatus == 'All' ? 2 : 1,
                    pressElevation: 2,
                  ),
                  const SizedBox(width: 8), // Space between chips
                  ChoiceChip(
                    label: const Text("Pending"),
                    selected: _selectedStatus == 'Pending',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStatus = 'Pending';
                        });
                      }
                    },
                    selectedColor: const Color.fromARGB(255, 90, 113, 243),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedStatus == 'Pending'
                          ? Colors.white
                          : const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(
                        color: _selectedStatus == 'Pending'
                            ? const Color.fromARGB(255, 90, 113, 243)
                            : Colors.transparent,
                        width: 2.0,
                      ),
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    elevation: _selectedStatus == 'Pending' ? 2 : 1,
                    pressElevation: 2,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Approved"),
                    selected: _selectedStatus == 'Approved',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStatus = 'Approved';
                        });
                      }
                    },
                    selectedColor: const Color.fromARGB(255, 90, 113, 243),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedStatus == 'Approved'
                          ? Colors.white
                          : const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(
                        color: _selectedStatus == 'Approved'
                            ? const Color.fromARGB(255, 90, 113, 243)
                            : Colors.transparent,
                        width: 2.0,
                      ),
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    elevation: _selectedStatus == 'Approved' ? 2 : 1,
                    pressElevation: 2,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Rejected"),
                    selected: _selectedStatus == 'Rejected',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStatus = 'Rejected';
                        });
                      }
                    },
                    selectedColor: const Color.fromARGB(255, 90, 113, 243),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedStatus == 'Rejected'
                          ? Colors.white
                          : const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(
                        color: _selectedStatus == 'Rejected'
                            ? const Color.fromARGB(255, 90, 113, 243)
                            : Colors.transparent,
                        width: 2.0,
                      ),
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    elevation: _selectedStatus == 'Rejected' ? 2 : 1,
                    pressElevation: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Check if the filtered enquiries are empty
            if (filteredEnquiries.isEmpty) ...[
              Center(
                child: Text(
                  "No ${_selectedStatus.toLowerCase()} enquiries",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
              ),
            ] else ...[
              // Display filtered enquiries
              for (var enquiry in filteredEnquiries) ...[
                const SizedBox(height: 10),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                        color: Color.fromARGB(255, 218, 218, 218)),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Specialist details
                        Row(
                          children: [
                            ClipOval(
                              child: Image.network(
                                enquiry['specialist']['profile_picture_url'] ??
                                    '',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 20,
                                        color: Color.fromARGB(
                                            255, 90, 113, 243)), // Icon for name
                                    const SizedBox(width: 10),
                                    Text(
                                      enquiry['specialist']['name'] ??
                                          'Unknown',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.email,
                                        size: 20,
                                        color: Color.fromARGB(
                                            255, 90, 113, 243)), // Icon for email
                                    const SizedBox(width: 10),
                                    Text(
                                      enquiry['specialist']['email'] ??
                                          'No Email',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                          maxLines: 2,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.business,
                                        size: 20,
                                        color: Color.fromARGB(255, 90, 113,
                                            243)), // Icon for organization
                                    const SizedBox(width: 10),
                                    Text(
                                      enquiry['specialist']['organization'] ??
                                          'No Organization',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                          maxLines: 2,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              "Status: ${enquiry['status']}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            _getStatusIcon(enquiry['status']),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Ending Date: ${DateFormat.yMMMd().format(DateTime.parse(enquiry['endDate']))}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Submission Date: ${DateFormat.yMMMd().add_jm().format((enquiry['submittedDate'] as Timestamp).toDate())}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Reason: ${enquiry['reason']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (enquiry['reason'] == 'Other' &&
                            enquiry['otherReason'] != null)
                          Text(
                            "Other Reason: ${enquiry['otherReason']}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          "Details: \n${enquiry['details']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (enquiry['updatedDate'] != null)
                          Text(
                            "Updated On: ${DateFormat.yMMMd().add_jm().format((enquiry['updatedDate'] as Timestamp).toDate())}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        const SizedBox(height: 16),
                        if (enquiry['status'] == 'Pending') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromARGB(255, 90, 113, 243),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () {
                                  _showConfirmationDialog(
                                      enquiry['specialistId'], 'approve');
                                },
                                child: const Text("Approve",
                                    style: TextStyle(color: Colors.white)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () {
                                  _showConfirmationDialog(
                                      enquiry['specialistId'], 'reject');
                                },
                                child: const Text("Reject",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}