import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'bmi_history.dart';
import 'diet_history.dart';
import 'health_record.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientDetailsScreen(
      {super.key, required this.clientId, required this.clientName});

  @override
  _ClientDetailsScreenState createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen>
    with SingleTickerProviderStateMixin {
  Client? client;
  PersonalDetails? personalDetails;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchClientDetails();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _fetchClientDetails() async {
    try {
      var clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .get();

      if (clientDoc.exists) {
        var clientData = clientDoc.data()!;
        setState(() {
          client = Client(
            id: widget.clientId,
            name: widget.clientName,
            email: clientData['email'] ?? 'No email',
            profilePic: clientData['profile_pic'] ?? '',
          );
        });

        var personalDetailsQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.clientId)
            .collection('personal_details')
            .limit(1)
            .get();

        if (personalDetailsQuery.docs.isNotEmpty) {
          var personalData = personalDetailsQuery.docs.first.data();
          setState(() {
            personalDetails = PersonalDetails(
              dateOfBirth:
                  (personalData['dateOfBirth'] as Timestamp?)?.toDate(),
              fullName: personalData['fullName'] ?? 'No full name',
              gender: personalData['gender'] ?? 'Not specified',
              nric: personalData['nric'] ?? 'No NRIC',
              phoneNumber: personalData['phoneNumber'] ?? 'No phone number',
            );
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load client details: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.clientName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 90, 113, 243),
              )),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF5A71F3),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color.fromARGB(255, 78, 98, 215),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Diet History"),
              Tab(text: "BMI History"),
              Tab(text: "Health Record"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline,
                  color: Color.fromARGB(255, 90, 113, 243)),
              onPressed: () {
                _showClientInfoDialog();
              },
            ),
          ],
          iconTheme:
              const IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            DietHistoryWidget(clientId: widget.clientId),
            BmiHistoryScreen(clientId: widget.clientId),
            HealthRecordWidget(clientId: widget.clientId),
          ],
        ),
      ),
    );
  }

  void _showClientInfoDialog() {
    showDialog(
        context: context,
        builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              insetPadding: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 500),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage:
                                    client?.profilePic.isNotEmpty == true
                                        ? NetworkImage(client!.profilePic)
                                        : null,
                                child: client?.profilePic.isEmpty == true
                                    ? const Icon(Icons.person, size: 40)
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                client?.name ?? 'No name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color.fromARGB(255, 90, 113, 243),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                client?.email ?? 'No email',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const Divider(),
                              if (personalDetails != null) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'Client\'s Personal Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                InfoRow(
                                    icon: Icons.person,
                                    label: 'Full Name',
                                    value: personalDetails!.fullName),
                                InfoRow(
                                    icon: Icons.wc,
                                    label: 'Gender',
                                    value: personalDetails!.gender),
                                InfoRow(
                                    icon: Icons.perm_identity,
                                    label: 'NRIC',
                                    value: personalDetails!.nric),
                                InfoRow(
                                    icon: Icons.cake,
                                    label: 'Date of Birth',
                                    value: personalDetails!.dateOfBirth
                                            ?.toLocal()
                                            .toString()
                                            .split(' ')[0] ??
                                        'N/A'),
                                InfoRow(
                                    icon: Icons.phone,
                                    label: 'Phone Number',
                                    value:
                                        '+60 ${personalDetails!.phoneNumber}'),
                              ] else ...[
                                const Text('No personal details available.'),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(context).pop();
                            }),
                      )
                    ],
                  ),
                ),
              ),
            ));
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class Client {
  final String id;
  final String name;
  final String email;
  final String profilePic;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePic,
  });
}

class PersonalDetails {
  final DateTime? dateOfBirth;
  final String fullName;
  final String gender;
  final String nric;
  final String phoneNumber;

  PersonalDetails({
    this.dateOfBirth,
    required this.fullName,
    required this.gender,
    required this.nric,
    required this.phoneNumber,
  });
}
