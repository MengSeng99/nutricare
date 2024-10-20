import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // To format the upload time
import 'package:url_launcher/url_launcher.dart';

class HealthRecordScreen extends StatefulWidget {
  const HealthRecordScreen({super.key});

  @override
  _HealthRecordScreenState createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  bool _isYourRecordsTab = true; // Track the active tab
  bool _isLoading = false; // To track the loading state for fetching data
  bool _isUploading = false; // To track the loading state for uploading
  List<Map<String, dynamic>> _uploadedRecords =
      []; // List to store uploaded records
  List<Map<String, dynamic>> _specialistReports =
      []; // List to store specialist reports

  @override
  void initState() {
    super.initState();
    _fetchUploadedRecords(); // Fetch user's uploaded records
    _fetchSpecialistReports(); // Fetch specialist reports
  }

  // Method to confirm and delete a record
  Future<void> _confirmDeleteRecord(String fileId, String filePath) async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this record?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels
              },
            ),
            TextButton(
              child: const Text('Delete',style: TextStyle(color: Colors.red),),
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Delete the file from Firebase Storage
      Reference storageReference =
          FirebaseStorage.instance.refFromURL(filePath);
      await storageReference.delete();

      // Delete the document from Firestore
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('health-record')
          .doc(userId)
          .collection('records')
          .where('fileId', isEqualTo: fileId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health record deleted successfully!')),
        );

        // Refresh the uploaded records list after deletion
        _fetchUploadedRecords();
      }
    }
  }

  // Method to fetch uploaded records from Firestore
  Future<void> _fetchUploadedRecords() async {
    setState(() {
      _isLoading = true; // Start loading indicator
    });

    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('health-record')
        .doc(userId)
        .collection('records')
        .orderBy('uploadTime', descending: true)
        .get();

    setState(() {
      _uploadedRecords = querySnapshot.docs.map((doc) {
        return {
          'filePath': doc['filePath'],
          'fileId': doc['fileId'],
          'uploadTime': (doc['uploadTime'] as Timestamp).toDate(),
        };
      }).toList();
      _isLoading = false; // Stop loading indicator
    });
  }

  // Method to fetch health reports uploaded by specialists from Firestore
  Future<void> _fetchSpecialistReports() async {
    setState(() {
      _isLoading = true; // Start loading indicator
    });

    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('health-report')
        .doc(userId)
        .collection('reports')
        .orderBy('uploadTime', descending: true)
        .get();

    setState(() {
      _specialistReports = querySnapshot.docs.map((doc) {
        return {
          'filePath': doc['filePath'],
          'reportId': doc['reportId'],
          'uploadTime': (doc['uploadTime'] as Timestamp).toDate(),
        };
      }).toList();
      _isLoading = false; // Stop loading indicator
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Health Record',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 90, 113, 243),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 90, 113, 243)),
          onPressed: () {
            Navigator.pop(context); // Back navigation
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tab-like buttons for "Your Records" and "Uploads"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabButton(
                    'Your Records',
                    isSelected: _isYourRecordsTab,
                    onTap: () {
                      setState(() {
                        _isYourRecordsTab =
                            true; // Set "Your Records" as active
                      });
                    },
                  ),
                  _buildTabButton(
                    'Uploads',
                    isSelected: !_isYourRecordsTab,
                    onTap: () {
                      setState(() {
                        _isYourRecordsTab = false; // Set "Uploads" as active
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20), // Space between tabs and content

              // Content based on selected tab
              _isYourRecordsTab
                  ? _buildYourRecordsTabContent()
                  : _buildUploadsTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  // Method to build the tab button with updated design
  Widget _buildTabButton(String text,
      {bool isSelected = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Column(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color.fromARGB(255, 90, 113, 243)
                    : Colors.grey,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4.0),
                height: 2.0,
                width: text.length * 8.0,
                color: const Color.fromARGB(255, 90, 113, 243),
              ),
          ],
        ),
      ),
    );
  }

// Content for "Your Records" tab
Widget _buildYourRecordsTabContent() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Loading spinner while fetching records
      if (_isLoading)
        const Center(
          child: CircularProgressIndicator(),
        )
      else if (_uploadedRecords.isEmpty && _specialistReports.isEmpty) ...[
        // Show the image and the message when both records and reports are empty
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'images/health-record-2.png', // Ensure this image path is correct
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 20),
            const Text(
              "You don't have any health records yet",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "If you do the health screening with us, this is where you can check your personalised report later. Alternatively, you can upload your health docs here.",
              style: TextStyle(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ] else ...[
        // Show the user's personal uploads if available
        _buildSectionHeader('Your Uploads'),
        _uploadedRecords.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No records yet. Please go to the upload tab to add your health documents.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _uploadedRecords.length,
                itemBuilder: (context, index) {
                  final record = _uploadedRecords[index];
                  final formattedTime = DateFormat('dd MMM yyyy, hh:mm a')
                      .format(record['uploadTime']);

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        record['fileId'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 90, 113, 243),
                        ),
                      ),
                      subtitle: Text(
                        'Uploaded on $formattedTime',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.open_in_new, color: Colors.grey),
                            onPressed: () async {
                              final url = record['filePath'];
                              Uri fileUri = Uri.parse(url);
                              if (await canLaunchUrl(fileUri)) {
                                await launchUrl(fileUri);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open the file')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _confirmDeleteRecord(record['fileId'], record['filePath']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(height: 20),

        // Only show specialist reports section if available
        if (_specialistReports.isNotEmpty) ...[
          _buildSectionHeader('Health Reports from Specialists'),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _specialistReports.length,
            itemBuilder: (context, index) {
              final report = _specialistReports[index];
              final formattedTime = DateFormat('dd MMM yyyy, hh:mm a')
                  .format(report['uploadTime']);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(
                    report['reportId'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 90, 113, 243),
                    ),
                  ),
                  subtitle: Text(
                    'Uploaded on $formattedTime',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.grey),
                    onPressed: () async {
                      final url = report['filePath'];
                      Uri reportUri = Uri.parse(url);
                      if (await canLaunchUrl(reportUri)) {
                        await launchUrl(reportUri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open the file')),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ],
    ],
  );
}

  // Content for "Uploads" tab
  Widget _buildUploadsTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          'images/health-record.png', // Ensure this image path is correct
          width: 180,
          height: 180,
        ),
        const SizedBox(height: 20),
        const Text(
          'Store and access your health records',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Securely upload your health records to manage them easily and access them anytime.',
          style: TextStyle(fontSize: 15, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        // Show loading spinner while uploading a file
        if (_isUploading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else
          ElevatedButton.icon(
            onPressed: _uploadHealthRecord,
            icon: const Icon(Icons.upload_file, color: Colors.white),
            label: const Text('Upload Health Record',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 90, 113, 243),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
          ),
      ],
    );
  }

  // Method to upload a health record
  Future<void> _uploadHealthRecord() async {
    setState(() {
      _isUploading = true; // Show uploading indicator
    });

    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';

    // Open file picker to allow users to select a file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      // Upload the file to Firebase Storage
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('health-records/$userId/$fileName');

      UploadTask uploadTask = storageReference.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Save file metadata to Firestore
      await FirebaseFirestore.instance
          .collection('health-record')
          .doc(userId)
          .collection('records')
          .add({
        'filePath': downloadUrl,
        'fileId': fileName,
        'uploadTime': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health record uploaded successfully!')),
      );

      // Refresh the uploaded records list
      _fetchUploadedRecords();
    }

    // Switch to "Your Records" tab after successful upload
    setState(() {
      _isYourRecordsTab = true;
    });

    setState(() {
      _isUploading = false; // Hide uploading indicator
    });
  }

  // Helper method to build section headers
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Color.fromARGB(255, 90, 113, 243),
      ),
    );
  }
}
