import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SpecialistDeactivation extends StatefulWidget {
  final String specialistId;

  const SpecialistDeactivation({super.key, required this.specialistId});

  @override
  _SpecialistDeactivationState createState() => _SpecialistDeactivationState();
}

class _SpecialistDeactivationState extends State<SpecialistDeactivation> {
  String? _selectedReason;
  String? _otherReason;
  DateTime? _selectedDate;
  final TextEditingController _detailsController = TextEditingController();
  bool _isOtherSelected = false;
  bool _showEnquiryForm = false;

  final List<String> _reasons = [
    "Personal Reasons",
    "Health Issues",
    "Career Change",
    "Other",
  ];

  bool _loading = true;
  Map<String, dynamic>? _existingEnquiry;

  bool get _isFormValid {
    if (_selectedReason == null || _selectedDate == null) {
      return false;
    }
    if (_isOtherSelected && (_otherReason == null || _otherReason!.isEmpty)) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _fetchEnquiryStatus();
    _fetchPastEnquiries();
  }

  Future<void> _fetchEnquiryStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('specialist_enquiries')
          .doc(widget.specialistId)
          .get();

      if (doc.exists) {
        setState(() {
          _existingEnquiry = doc.data() as Map<String, dynamic>;

          if (_existingEnquiry!['submittedDate'] is Timestamp) {
            _existingEnquiry!['submittedDate'] =
                (_existingEnquiry!['submittedDate'] as Timestamp).toDate();
          }
          if (_existingEnquiry!['endDate'] is String) {
            _existingEnquiry!['endDate'] =
                DateTime.parse(_existingEnquiry!['endDate']);
          }
        });
      }
    } catch (e) {
      print("Error fetching enquiry: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchPastEnquiries() async {
    try {
      setState(() {});
    } catch (e) {
      print("Error fetching past enquiries: $e");
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime startFrom = now.add(const Duration(days: 14));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startFrom,
      firstDate: startFrom,
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEnquiry() async {
    try {
      await FirebaseFirestore.instance
          .collection('specialist_enquiries')
          .doc(widget.specialistId)
          .set({
        'specialistId': widget.specialistId,
        'reason': _selectedReason,
        'otherReason': _otherReason,
        'endDate': _selectedDate?.toIso8601String(),
        'details': _detailsController.text,
        'status': 'Pending',
        'submittedDate': FieldValue.serverTimestamp(),
      });

      setState(() {
        _showEnquiryForm = false;
      });

      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit enquiry. Try again.")),
      );
    }
  }

  void _handleSubmit() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Confirm Submission",
            style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
              "Are you sure you want to submit the deactivation enquiry?"),
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
                _saveEnquiry();
              },
              child: const Text("Yes, Submit",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Enquiry Submitted",
            style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
              "Your deactivation enquiry has been sent successfully. The admin will review it and you can check the status on this screen. Kindly wait for the approval from our admin team."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _fetchEnquiryStatus();
                });
              },
              child: const Text("OK"),
            ),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Deactivation Enquiry",
          style: TextStyle(
            color: Color.fromARGB(255, 90, 113, 243),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme:
            const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                      color: Color.fromARGB(255, 182, 172, 172)),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_existingEnquiry != null &&
                          _existingEnquiry!['status'] == 'Rejected') ...[
                        Row(
                          children: [
                            Text(
                              "Status: ${_existingEnquiry!['status']}",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            _getStatusIcon(_existingEnquiry!['status']),
                          ],
                        ),
                        const Text(
                          "Your last enquiry was rejected.",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                         Text(
                          "Ending Date: ${DateFormat.yMMMd().format(_existingEnquiry!['endDate'])}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Submitted On: ${DateFormat.yMMMd().add_jm().format(_existingEnquiry!['submittedDate'])}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Reason: ${_existingEnquiry!['reason']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (_existingEnquiry!['reason'] == 'Other') ...[
                          Text(
                            "Other Reason: ${_existingEnquiry!['otherReason']}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                        Text(
                          "Details: \n${_existingEnquiry!['details']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 90, 113, 243),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _showEnquiryForm = true;
                              });
                            },
                            child: const Text("Submit Another Enquiry",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ] else if (_existingEnquiry != null) ...[
                        Row(
                          children: [
                            Text(
                              "Status: ${_existingEnquiry!['status']}",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            _getStatusIcon(_existingEnquiry!['status']),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_existingEnquiry!['status'] == 'Approved') ...[
                          Text(
                            "*Your account will be deactivate on: ${DateFormat.yMMMd().format(_existingEnquiry!['endDate'])}.",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "For any inquiries, please contact our admin for support.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          "Reason: ${_existingEnquiry!['reason']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (_existingEnquiry!['reason'] == 'Other')
                          Text(
                            "Other Reason: ${_existingEnquiry!['otherReason']}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        Text(
                          "Ending Date: ${DateFormat.yMMMd().format(_existingEnquiry!['endDate'])}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Submission Date: ${DateFormat.yMMMd().add_jm().format(_existingEnquiry!['submittedDate'])}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (_existingEnquiry!['details'] != null &&
                            _existingEnquiry!['details'].isNotEmpty)
                          Text(
                            "Details: \n${_existingEnquiry!['details']}",
                            style: const TextStyle(fontSize: 16),
                          ),
                      ],
                      if (_existingEnquiry == null || _showEnquiryForm) ...[
                        const SizedBox(height: 16),
                        const Text(
                          "Please choose the reason for deactivation:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                          value: _selectedReason,
                          items: _reasons.map((reason) {
                            return DropdownMenuItem(
                              value: reason,
                              child: Text(reason),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedReason = value;
                              _isOtherSelected = value == "Other";
                              if (!_isOtherSelected) _otherReason = null;
                            });
                          },
                          hint: const Text("Select a reason"),
                        ),
                        if (_isOtherSelected) ...[
                          const SizedBox(height: 16),
                          const Text(
                            "Please specify:",
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _otherReason = value;
                              });
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Enter your reason",
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          "Select the Date of Deactivation:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 90, 113, 243),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () => _pickDate(context),
                              child: const Text("Pick Date",
                                  style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 16),
                            if (_selectedDate != null)
                              Text(
                                DateFormat.yMMMd().format(_selectedDate!),
                                style: const TextStyle(fontSize: 16),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "More Details (Optional):",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _detailsController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Provide additional details if any",
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 90, 113, 243),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _isFormValid ? _handleSubmit : null,
                            child: const Text("Submit",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
