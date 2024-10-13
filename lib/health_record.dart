import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // To format the upload time
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart'; // To open the file URLs

class HealthRecordScreen extends StatefulWidget {
  const HealthRecordScreen({super.key});

  @override
  _HealthRecordScreenState createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  bool _isYourRecordsTab = true; // Track the active tab
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

  // Method to fetch uploaded records from Firestore
  Future<void> _fetchUploadedRecords() async {
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
    });
  }

  // Method to fetch health reports uploaded by specialists from Firestore
  Future<void> _fetchSpecialistReports() async {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Record',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 90, 113, 243),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
        // Section for user's personal uploads
        _buildSectionHeader('Your Uploads'),
        _uploadedRecords.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'images/health-record-2.png', // Ensure this image path is correct
                    width: 150,
                    height: 150,
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
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new, color: Colors.grey),
                        onPressed: () async {
                          final url = record['filePath'];
                          Uri fileUri = Uri.parse(url);
                          if (await canLaunchUrl(fileUri)) {
                            await launchUrl(fileUri);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Could not open the file')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(height: 20),

        // Section for specialist reports
        _buildSectionHeader('Health Reports from Specialists'),
        _specialistReports.isEmpty
            ? const Text(
                'No health reports from specialists yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              )
            : ListView.builder(
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
                          if (await canLaunchUrlString(url)) {
                            await launchUrlString(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Could not open the file')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  // Content for "Uploads" tab
  Widget _buildUploadsTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'images/health-record.png', // Ensure this image path is correct
          width: 150,
          height: 150,
        ),
        const SizedBox(height: 20),
        const Text(
          "Upload and store your records at one place",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        const Text(
          "Optimise your experience on our app by uploading your health records.",
          style: TextStyle(fontSize: 15, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _uploadFile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 90, 113, 243),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Upload Health Records',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Color.fromARGB(255, 90, 113, 243),
        ),
      ),
    );
  }

  // File upload logic
  Future<void> _uploadFile() async {
    // Allow users to pick a file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx', 'pdf'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';

      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('health-records/$userId/${file.name}');
      
      try {
        // Show a snackbar indicating upload has started
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading file...')),
        );

        // Start the upload task
        UploadTask uploadTask = ref.putFile(File(file.path!));
        TaskSnapshot snapshot = await uploadTask;

        // Get the download URL after the upload completes
        String downloadUrl = await snapshot.ref.getDownloadURL();
        String recordId = FirebaseFirestore.instance.collection('health-record').doc().id;

        // Save the file metadata to Firestore
        await FirebaseFirestore.instance
            .collection('health-record')
            .doc(userId)
            .collection('records')
            .doc(recordId)
            .set({
          'filePath': downloadUrl,
          'uploadTime': FieldValue.serverTimestamp(),
          'fileId': file.name,
        });

        // Show a success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );

        // Refresh the list of uploaded records
        _fetchUploadedRecords(); 

        // Switch to "Your Records" tab after successful upload
        setState(() {
          _isYourRecordsTab = true;
        });
      } catch (e) {
        // Show an error snackbar if the upload fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    }
  }
}
