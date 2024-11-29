import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'appointment_analysis.dart';

class AdminAppointmentScreen extends StatefulWidget {
  const AdminAppointmentScreen({super.key});

  @override
  _AdminAppointmentScreenState createState() => _AdminAppointmentScreenState();
}

class _AdminAppointmentScreenState extends State<AdminAppointmentScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "Manage Appointments",
            style: TextStyle(
              color: Color.fromARGB(255, 90, 113, 243),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics_outlined,
                  color: Color.fromARGB(255, 90, 113, 243)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AppointmentAnalysisScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(50),
            child: TabBar(
              labelColor: Color(0xFF5A71F3),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color.fromARGB(255, 78, 98, 215),
              indicatorWeight: 3,
              tabs: [
                Tab(text: "Upcoming"),
                Tab(text: "Completed"),
                Tab(text: "Canceled"),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            AppointmentsTab(
                statusFilter: ['Confirmed', 'Pending Confirmation']),
            AppointmentsTab(statusFilter: ['Completed']),
            AppointmentsTab(statusFilter: ['Canceled']),
          ],
        ),
      ),
    );
  }
}

class AppointmentsTab extends StatefulWidget {
  final List<String> statusFilter;

  const AppointmentsTab({required this.statusFilter, super.key});

  @override
  _AppointmentsTabState createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  final TextEditingController searchController = TextEditingController();
  String searchKeyword = '';
  List<String?> selectedSpecialists = [];
  List<String> specialists = [];
  String? sortingOption = 'Appointment ID'; // Default sorting option

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {
        searchKeyword = searchController.text;
      });
    });

    _fetchSpecialists();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSpecialists() async {
    final QuerySnapshot appointmentsSnapshot =
        await FirebaseFirestore.instance.collection('appointments').get();
    Set<String> specialistSet = {};

    for (var doc in appointmentsSnapshot.docs) {
      String appointmentId = doc.id;
      QuerySnapshot detailsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .collection('details')
          .get();

      for (var detailDoc in detailsSnapshot.docs) {
        final detailData = detailDoc.data() as Map<String, dynamic>;
        specialistSet.add(detailData['specialistName']);
      }
    }

    setState(() {
      specialists = specialistSet.toList();
    });
  }

  Stream<List<Map<String, dynamic>>> _retrieveAppointmentData() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .snapshots()
        .asyncMap((query) async {
      List<Map<String, dynamic>> appointments = [];

      for (var doc in query.docs) {
        String appointmentId = doc.id;
        List<dynamic>? usersArray = (doc.data())['users'] as List<dynamic>?;

        QuerySnapshot detailsSnapshot =
            await doc.reference.collection('details').get();

        for (var detailDoc in detailsSnapshot.docs) {
          final detailData = detailDoc.data() as Map<String, dynamic>;

          if (detailData.containsKey('appointmentStatus') &&
              widget.statusFilter.contains(detailData['appointmentStatus'])) {
            detailData['appointmentId'] = appointmentId;
            detailData['users'] = usersArray;
            appointments.add(detailData);
          }
        }
      }
      return appointments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Search by Appointment ID",
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 250, 250, 250)
                        .withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 221, 222, 226),
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 221, 222, 226),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 90, 113, 243),
                        width: 2.0,
                      ),
                    ),
                    suffixIcon: searchKeyword.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(width: 8.0),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list,
                        color: Color.fromARGB(255, 90, 113, 243)),
                    onPressed: () => _showFilterDialog(),
                  ),
                  const Text("Filter", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 8.0),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sort,
                        color: Color.fromARGB(255, 90, 113, 243)),
                    onPressed: () => _showSortDialog(),
                  ),
                  const Text("Sort", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _retrieveAppointmentData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "No Scheduled Appointments Found",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              }

              // Filter appointments based on the search keyword and selected specialists
              final filteredAppointments = snapshot.data!.where((appointment) {
                final startsWithKeyword = appointment['appointmentId']
                    .toString()
                    .startsWith(searchKeyword);
                final matchesSpecialist = selectedSpecialists.isEmpty ||
                    selectedSpecialists.contains(appointment['specialistName']);

                return startsWithKeyword && matchesSpecialist;
              }).toList();

              // Sort filtered appointments based on selected option
              filteredAppointments.sort((a, b) {
                switch (sortingOption) {
                  case 'Specialist Name':
                    return a['specialistName'].compareTo(b['specialistName']);
                  case 'Date':
                    return (a['selectedDate'] as Timestamp)
                        .compareTo(b['selectedDate'] as Timestamp);
                  default: // 'Appointment ID'
                    return a['appointmentId']
                        .toString()
                        .compareTo(b['appointmentId'].toString());
                }
              });

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: filteredAppointments.map((data) {
                  return AppointmentCard(
                    date: (data['selectedDate'] as Timestamp).toDate(),
                    time: data['selectedTimeSlot'] ?? 'N/A',
                    specialistName: data['specialistName'],
                    appointmentStatus: data['appointmentStatus'],
                    service: data['serviceName'],
                    appointmentId: data['appointmentId'].toString(),
                    appointmentMode: data['appointmentMode'],
                    users: data['users'],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: const Text(
                  'Filter by Specialists',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 90, 113, 243),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: specialists.map((specialist) {
                return RadioListTile<String>(
                  value: specialist,
                  groupValue: selectedSpecialists.isNotEmpty
                      ? selectedSpecialists.first
                      : '',
                  title: Text(specialist),
                  onChanged: (String? value) {
                    setState(() {
                      if (value != null) {
                        selectedSpecialists = [value]; // Select the specialist
                        Navigator.of(context).pop(); // Close the dialog
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSpecialists.clear(); // Clear the selections
                });
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Clear Filter"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 90, 113, 243),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Done", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: const Text(
                  'Sort by',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 90, 113, 243),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ['Appointment ID', 'Specialist Name', 'Date'].map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: sortingOption,
                  onChanged: (value) {
                    setState(() {
                      sortingOption = value;
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final String appointmentId;
  final DateTime date;
  final String time;
  final String specialistName;
  final String appointmentStatus;
  final String appointmentMode;
  final String service;
  final List<dynamic>? users;

  const AppointmentCard({
    required this.appointmentId,
    required this.date,
    required this.time,
    required this.specialistName,
    required this.appointmentStatus,
    required this.appointmentMode,
    required this.service,
    required this.users,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // Fetch appointment details using appointmentId
        Map<String, dynamic>? appointmentDetails =
            await _fetchAppointmentDetails(appointmentId);

        if (appointmentDetails != null) {
          _showAppointmentDetailsDialog(context, appointmentDetails);
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Color.fromARGB(255, 221, 222, 226), width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  "Appointment ID: $appointmentId",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 90, 113, 243),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Specialist: $specialistName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointmentStatus,
                          style: TextStyle(
                            color: _getStatusColor(appointmentStatus),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (users != null && users!.isNotEmpty)
                          FutureBuilder<String?>(
                            future: _fetchUserName(users![0]),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (userSnapshot.hasData &&
                                  userSnapshot.data != null) {
                                return Text(
                                  'Client Name: ${userSnapshot.data}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 90, 113, 243),
                                      fontWeight: FontWeight.bold),
                                );
                              } else {
                                return const Text(
                                  'Client Name: N/A',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 90, 113, 243),
                                      fontWeight: FontWeight.bold),
                                );
                              }
                            },
                          ),
                        const SizedBox(height: 8),
                        Text(
                          "${DateFormat('MMMM dd, yyyy').format(date)} | $time",
                          style: const TextStyle(
                              fontSize: 16, color: Color(0xFF6D6D6D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.grey),
              Text(
                service,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6D6D6D)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending Confirmation':
        return Colors.orange;
      case 'Canceled':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, dynamic>?> _fetchAppointmentDetails(
      String appointmentId) async {
    QuerySnapshot detailSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .collection('details')
        .limit(1)
        .get();

    if (detailSnapshot.docs.isNotEmpty) {
      return detailSnapshot.docs.first.data() as Map<String, dynamic>;
    }

    return null;
  }

  void _showAppointmentDetailsDialog(
      BuildContext context, Map<String, dynamic> details) async {
    String? clientName = users != null && users!.isNotEmpty
        ? await _fetchUserName(users![0])
        : "N/A";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Appointment Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 90, 113, 243),
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.calendar_today, 'Appointment ID',
                    details['appointmentId']),
                _buildDetailRow(Icons.person, 'Specialist', specialistName),
                _buildDetailRow(
                    Icons.account_circle, 'Client', clientName ?? 'N/A'),
                _buildDetailRow(
                    Icons.medical_services, 'Service', details['serviceName']),
                _buildDetailRow(
                    Icons.date_range,
                    'Date',
                    DateFormat('MMMM dd, yyyy').format(
                        (details['selectedDate'] as Timestamp).toDate())),
                _buildDetailRow(
                    Icons.access_time, 'Time', details['selectedTimeSlot']),
                _buildDetailRow(
                    Icons.verified, 'Status', details['appointmentStatus']),
                _buildDetailRow(
                    Icons.video_call, 'Mode', details['appointmentMode']),
                _buildDetailRow(Icons.attach_money, 'Amount Paid',
                    'RM ${details['amountPaid']}'),
                _buildDetailRow(Icons.credit_card, 'Payment Card Used',
                    details['paymentCardUsed']),
                _buildDetailRow(
                    Icons.calendar_today,
                    'Paid On',
                    DateFormat('MMMM dd, yyyy')
                        .format((details['createdAt'] as Timestamp).toDate())),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Close',
                style: TextStyle(color: Color.fromARGB(255, 90, 113, 243)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color.fromARGB(255, 90, 113, 243), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _fetchUserName(String userId) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      return (userDoc.data() as Map<String, dynamic>)['name'];
    }
    return null;
  }
}
