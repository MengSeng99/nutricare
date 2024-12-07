import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'adjust_rate.dart';

class AdminEarningsScreen extends StatefulWidget {
  const AdminEarningsScreen({super.key});

  @override
  _AdminEarningsScreenState createState() => _AdminEarningsScreenState();
}

class _AdminEarningsScreenState extends State<AdminEarningsScreen> {
  List<Map<String, dynamic>> completedAppointments = [];
  List<int> availableYears = []; // List to hold unique years
  int? selectedMonth;
  int? selectedYear;
  bool noEarningsForSelectedDate = false; // Indicator for earnings
  double distributionRate = 0.0; // Variable to hold the distribution rate

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    completedAppointments.clear();
    availableYears.clear();
    noEarningsForSelectedDate = false;

    // Fetch all specialists
    var specialistsSnapshot = await FirebaseFirestore.instance
        .collection('specialists')
        .get();

    // Create a map of specialist IDs to names for easy lookup
    Map<String, String> specialistNames = {};
    for (var specialistDoc in specialistsSnapshot.docs) {
      specialistNames[specialistDoc.id] = specialistDoc.data()['name'] ?? 'Unknown';
    }

    // Fetch earnings for each specialist
    for (var specialistDoc in specialistsSnapshot.docs) {
      var earningsSnapshot = await FirebaseFirestore.instance
          .collection('specialists')
          .doc(specialistDoc.id)
          .collection('earnings')
          .get();

      for (var earningDoc in earningsSnapshot.docs) {
        double totalAmount = earningDoc.data()['totalAmount'] ?? 0.0; // Total amount for the appointment
        double amount = earningDoc.data()['amount'] ?? 0.0; // Amount paid to the specialist
        double rate = earningDoc.data()['rate'] ?? 0.0; // Rate
        String appointmentId = earningDoc.data()['appointmentId'] ?? 'Unknown';
        String service = earningDoc.data()['service'] ?? 'Unknown'; // Get service name

        Timestamp timestamp = earningDoc.data()['date'];
        DateTime selectedDate = timestamp.toDate();

        if (!availableYears.contains(selectedDate.year)) {
          availableYears.add(selectedDate.year);
        }

        // Calculate organization's earning
        double organizationEarning = totalAmount - amount;

        // Fetch specialist name using specialist ID
        String specialistName = specialistNames[specialistDoc.id] ?? 'Unknown';

        // Add to completed appointments ensuring to fetch all data and calculate earnings
        completedAppointments.add({
          'appointmentId': appointmentId,
          'totalAmount': totalAmount,
          'organizationEarning': organizationEarning,
          'selectedDate': selectedDate,
          'specialistName': specialistName,
          'service': service, // Include the service
          'rate': rate // Include the distribution rate
        });
      }
    }

    // Filter completed appointments based on selected month and year
    completedAppointments = completedAppointments.where((appointment) {
      DateTime date = appointment['selectedDate'];
      bool matchMonth = (selectedMonth == null || selectedMonth == 0 || date.month == selectedMonth);
      bool matchYear = (selectedYear == null || date.year == selectedYear);
      return matchMonth && matchYear;
    }).toList();

    if (completedAppointments.isEmpty) {
      noEarningsForSelectedDate = true;
    }

    setState(() {});
  }

  double getTotalEarnings() {
    return completedAppointments.fold(0, (sum, appointment) => sum + appointment['organizationEarning']);
  }

  Widget _buildFilterOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
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
              selectedMonth = newValue;
              _fetchEarnings();
            });
          },
        ),
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
              _fetchEarnings();
            });
          },
        ),
      ],
    );
  }

  void navigateToRateAdjustment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RateAdjustmentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Admin Earnings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 90, 113, 243),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: Color.fromARGB(255, 90, 113, 243),
            onPressed: () => navigateToRateAdjustment(context),
          ),
        ],
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
                              blurRadius: 10,
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
                                  Icons.attach_money,
                                  color: Color.fromARGB(255, 90, 113, 243),
                                  size: 24,
                                ),
                                const SizedBox(width: 8.0),
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
                                fontSize: 36,
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
                                side: const BorderSide(color: Colors.grey, width: 0.5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'RM ${appointment['organizationEarning'].toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        Text(
                                          'Appt ID: ${appointment['appointmentId']}', // Use appointmentId
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: ${appointment['selectedDate']?.toLocal().toIso8601String().split('T')[0] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Specialist: ${appointment['specialistName'] ?? 'Unknown'}', // Display the specialist name
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Service: ${appointment['service'] ?? 'Unknown'}', // Display the service name
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rate: ${(appointment['rate']! * 100).toStringAsFixed(1)}%', // Show rate as a percentage
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 8), // Spacing before total amount
                                    Text(
                                      'Total Amount: RM ${appointment['totalAmount'].toStringAsFixed(2)}', // Display total amount
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