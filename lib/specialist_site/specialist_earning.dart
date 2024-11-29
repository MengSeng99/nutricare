import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  _EarningsScreenState createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  List<Map<String, dynamic>> completedAppointments = [];
  String? currentUserId;
  List<int> availableYears = []; // List to hold unique years
  int? selectedMonth;
  int? selectedYear;
  bool noEarningsForSelectedDate = false; // Indicator for earnings

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
  }

  Future<void> _fetchCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      currentUserId = user.uid;
      await _fetchEarnings();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No user is signed in')));
    }
  }

  Future<void> _fetchEarnings() async {
    completedAppointments.clear();
    availableYears.clear(); // Reset the year list
    noEarningsForSelectedDate = false; // Reset the flag

    var appointmentsSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('users', arrayContains: currentUserId)
        .where('appointmentStatus', isEqualTo: 'Completed')
        .get();

    for (var doc in appointmentsSnapshot.docs) {
      var detailsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(doc.id)
          .collection('details')
          .limit(1)
          .get();

      if (detailsSnapshot.docs.isNotEmpty) {
        double amountPaid = detailsSnapshot.docs[0].data()['amountPaid'] ?? 0.0;
        Timestamp timestamp = detailsSnapshot.docs[0].data()['selectedDate'];
        DateTime selectedDate = timestamp.toDate();

        // Gather unique years for the year filter
        if (!availableYears.contains(selectedDate.year)) {
          availableYears.add(selectedDate.year);
        }

        completedAppointments.add({
          'id': doc.id,
          'amountPaid': amountPaid,
          'selectedDate': selectedDate,
        });
      }
    }

    // Filter completed appointments based on selected month and year
    completedAppointments = completedAppointments.where((appointment) {
      DateTime date = appointment['selectedDate'];
      bool matchMonth = (selectedMonth == null ||
          selectedMonth == 0 ||
          date.month == selectedMonth);
      bool matchYear = (selectedYear == null || date.year == selectedYear);
      return matchMonth && matchYear;
    }).toList();

    // Update the flag if there are no appointments after filtering
    if (completedAppointments.isEmpty) {
      noEarningsForSelectedDate =
          true; // Set the flag to true if no earnings are found
    }

    setState(() {});
  }

  // Method to calculate total earnings
  double getTotalEarnings() {
    return completedAppointments.fold(
        0, (sum, appointment) => sum + appointment['amountPaid']);
  }

  // Method to display the filter options
  Widget _buildFilterOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Month Filter
        DropdownButton<int>(
          value: selectedMonth,
          hint: const Text('Month'),
          items: [
                DropdownMenuItem<int>(
                  value: 0, // All months
                  child: const Text('All'),
                ),
              ] +
              List.generate(12, (index) => index + 1).map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(DateFormat('MMMM').format(DateTime(0, value))),
                );
              }).toList(),
          onChanged: (int? newValue) {
            setState(() {
              selectedMonth = newValue; // "All" is represented by 0
              _fetchEarnings(); // Fetch earnings based on selected filters
            });
          },
        ),
        // Year Filter
        DropdownButton<int>(
          value: selectedYear,
          hint: const Text('Year'),
          items: availableYears.map((int year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text(year.toString()),
            );
          }).toList(),
          onChanged: (int? newValue) {
            setState(() {
              selectedYear = newValue;
              _fetchEarnings(); // Fetch earnings based on selected filters
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Your Earnings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 90, 113, 243),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 0.5,
            color: Color.fromARGB(255, 220, 220, 241),
          ),
        ),
        iconTheme: IconThemeData(color: Color.fromARGB(255, 90, 113, 243)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildFilterOptions(),
          ),
          Expanded(
            child: completedAppointments.isEmpty
                ? Center(
                    child: noEarningsForSelectedDate
                        ? Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 60,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'No Earnings Found',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'It seems there are no earnings for this month or year.',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : const CircularProgressIndicator(),
                  )
                : Column(
                    children: [
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(255, 255, 255, 255),
                              Color.fromARGB(255, 238, 239, 241),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueGrey.withOpacity(0.25),
                              blurRadius:
                                  10, // Increased blur for a subtler shadow
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.attach_money, // Money icon
                                  color: Color.fromARGB(
                                      255, 90, 113, 243), // Matching color
                                  size: 24,
                                ),
                                const SizedBox(
                                    width: 8.0), // Space between icon and text
                                const Text(
                                  'Total Earnings:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 90, 113, 243),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'RM ${getTotalEarnings().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 36, // Slightly larger for emphasis
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 90, 113, 243),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: completedAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = completedAppointments[index];
                            return Card(
                              elevation: 2,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                    color: Colors.grey, width: 0.5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'RM ${appointment['amountPaid'].toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        Text(
                                          'Appt ID: ${appointment['id']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                        height: 4), 
                                    Text(
                                      'Date: ${appointment['selectedDate']?.toLocal().toIso8601String().split('T')[0] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
