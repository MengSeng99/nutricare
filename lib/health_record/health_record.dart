import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HealthRecordScreen extends StatefulWidget {
  const HealthRecordScreen({super.key});

  @override
  _HealthRecordScreenState createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isUploading = false;
  List<Map<String, dynamic>> _uploadedRecords = [];
  List<Map<String, dynamic>> _specialistReports = [];
  late TabController _tabController; // Correctly using TabController

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // Initialize TabController
    _fetchUploadedRecords();
    _fetchSpecialistReports();
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose of the TabController when done
    super.dispose();
  }

  Future<void> _confirmDeleteRecord(String fileId, String filePath) async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Confirm Delete',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243)),
          ),
          content: const Text(
            'Are you sure you want to delete this record?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 90, 113, 243),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
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
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      Reference storageReference =
          FirebaseStorage.instance.refFromURL(filePath);
      await storageReference.delete();

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
          const SnackBar(
              content: Text('Health record deleted successfully!'),
              backgroundColor: Colors.green),
        );

        _fetchUploadedRecords();
      }
    }
  }

  Future<void> _fetchUploadedRecords() async {
    setState(() {
      _isLoading = true;
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
      _isLoading = false;
    });
  }

  Future<void> _fetchSpecialistReports() async {
    setState(() {
      _isLoading = true;
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
      _isLoading = false;
    });
  }

  Future<void> _uploadHealthRecord() async {
    setState(() {
      _isUploading = true;
    });

    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.single.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected. Please try again.')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    try {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('health-records/$userId/$fileName');

      UploadTask uploadTask = storageReference.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

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
        const SnackBar(
            content: Text('Health record uploaded successfully!'),
            backgroundColor: Colors.green),
      );

      _tabController.index = 0; // Switch to "Your Records" tab
      _fetchUploadedRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
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
              color: Color.fromARGB(255, 90, 113, 243)),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color.fromARGB(255, 90, 113, 243),
          labelColor: Color.fromARGB(255, 90, 113, 243),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Your Records'),
            Tab(text: 'Uploads'),
          ],
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 90, 113, 243)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildYourRecordsTabContent(),
          _buildUploadsTabContent(),
        ],
      ),
    );
  }

  Widget _buildYourRecordsTabContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_uploadedRecords.isEmpty && _specialistReports.isEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('images/health-record-2.png',
                    width: 180, height: 180),
                const SizedBox(height: 20),
                const Text(
                  "You don't have any health records yet",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                const Text(
                  "If you do health screening with us, this is where you can check your personalised report later. Alternatively, you can upload your health docs here.",
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ] else ...[
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
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side:
                              BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            record['fileId'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 90, 113, 243),
                            ),
                          ),
                          subtitle: Text('Uploaded on $formattedTime',
                              style: const TextStyle(color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_new,
                                    color: Colors.grey),
                                onPressed: () async {
                                  final url = record['filePath'];
                                  Uri fileUri = Uri.parse(url);
                                  if (await canLaunchUrl(fileUri)) {
                                    await launchUrl(fileUri);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Could not open the file')));
                                  }
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _confirmDeleteRecord(
                                      record['fileId'], record['filePath']);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
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
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        report['reportId'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 90, 113, 243),
                        ),
                      ),
                      subtitle: Text('Uploaded on $formattedTime',
                          style: const TextStyle(color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new, color: Colors.grey),
                        onPressed: () async {
                          final url = report['filePath'];
                          Uri reportUri = Uri.parse(url);
                          if (await canLaunchUrl(reportUri)) {
                            await launchUrl(reportUri);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Could not open the file')));
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
      ),
    );
  }

  Widget _buildUploadsTabContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset('images/health-record.png', width: 180, height: 180),
          const SizedBox(height: 20),
          const Text(
            'Store and access your health records',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Securely upload your health records to manage them easily and access them anytime.',
            style: TextStyle(fontSize: 15, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          if (_isUploading)
            const Center(child: CircularProgressIndicator())
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
      ),
    );
  }

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
